# frozen_string_literal: true

module Boxr
  class Client
    def file_from_path(path)
      path = path.slice(1..-1) if path.start_with?('/')

      path_items = path.split('/')
      file_name = path_items.slice!(-1)

      folder = folder_from_path(path_items.join('/'))

      files = folder_items(folder, fields: %i[id name]).files
      file = files.select { |f| f.name.casecmp?(file_name) }.first
      raise BoxrError.new(boxr_message: "File not found: '#{file_name}'") if file.nil?

      file
    end

    def file_from_id(file_id, fields: [])
      file_id = ensure_id(file_id)
      uri = "#{FILES_URI}/#{file_id}"
      query = build_fields_query(fields, FOLDER_AND_FILE_FIELDS_QUERY)
      file, = get(uri, query: query)
      file
    end
    alias file file_from_id

    def embed_url(file, show_download: false, show_annotations: false)
      file_info = file_from_id(file, fields: [:expiring_embed_link])
      file_info.expiring_embed_link.url + "?showDownload=#{show_download}&showAnnotations=#{show_annotations}"
    end
    alias embed_link embed_url
    alias preview_url embed_url
    alias preview_link embed_url

    def update_file(file, name: nil, description: nil, parent: nil, shared_link: nil, tags: nil,
                    lock: nil, if_match: nil)
      file_id = ensure_id(file)
      parent_id = ensure_id(parent)
      uri = "#{FILES_URI}/#{file_id}"

      attributes = {}
      attributes[:name] = name unless name.nil?
      attributes[:description] = description unless description.nil?
      attributes[:parent] = { id: parent_id } unless parent_id.nil?
      attributes[:shared_link] = shared_link unless shared_link.nil?
      attributes[:tags] = tags unless tags.nil?
      attributes[:lock] = lock unless lock.nil?

      updated_file, = put(uri, attributes, if_match: if_match)
      updated_file
    end

    def lock_file(file, expires_at: nil, is_download_prevented: false, if_match: nil)
      lock = { type: 'lock' }
      lock[:expires_at] = expires_at.to_datetime.rfc3339 unless expires_at.nil?
      lock[:is_download_prevented] = is_download_prevented unless is_download_prevented.nil?

      update_file(file, lock: lock, if_match: if_match)
    end

    def unlock_file(file, if_match: nil)
      file_id = ensure_id(file)
      uri = "#{FILES_URI}/#{file_id}"
      attributes = { lock: nil }

      updated_file, = put(uri, attributes, if_match: if_match)
      updated_file
    end

    def move_file(file, new_parent, name: nil, if_match: nil)
      update_file(file, parent: new_parent, name: name, if_match: if_match)
    end

    def download_file(file, version: nil, follow_redirect: true)
      file_id = ensure_id(file)

      loop do
        uri = "#{FILES_URI}/#{file_id}/content"
        query = {}
        query[:version] = version unless version.nil?
        _, response = get(uri, query: query, success_codes: [302, 202], process_response: false, follow_redirect: false) # we don't want httpclient to automatically follow the redirect; we need to grab it
        if response.status == 302
          location = response.header['Location'][0]
          return location unless follow_redirect

          file_content, = get(location, process_response: false)
          return file_content

        # simply return the url

        elsif response.status == 202
          retry_after_seconds = response.header['Retry-After'][0]
          sleep retry_after_seconds.to_i
        end
        break if file_content
      end
    end

    def download_url(file, version: nil)
      download_file(file, version: version, follow_redirect: false)
    end

    def upload_file(path_to_file, parent, name: nil, content_created_at: nil, content_modified_at: nil,
                    preflight_check: true, send_content_md5: true)
      filename = name || File.basename(path_to_file)

      File.open(path_to_file) do |file|
        upload_file_from_io(file, parent, name: filename, content_created_at: content_created_at,
                                          content_modified_at: content_modified_at, preflight_check: preflight_check, send_content_md5: send_content_md5)
      end
    end

    def upload_file_from_io(io, parent, name:, content_created_at: nil, content_modified_at: nil,
                            preflight_check: true, send_content_md5: true)
      parent_id = ensure_id(parent)

      preflight_check(io, name, parent_id) if preflight_check

      if send_content_md5
        content_md5 = Digest::SHA1.hexdigest(io.read)
        io.rewind
      end

      attributes = { name: name, parent: { id: parent_id } }
      unless content_created_at.nil?
        attributes[:content_created_at] =
          content_created_at.to_datetime.rfc3339
      end
      unless content_modified_at.nil?
        attributes[:content_modified_at] =
          content_modified_at.to_datetime.rfc3339
      end

      body = { attributes: JSON.dump(attributes), file: io }

      file_info, = post(FILES_UPLOAD_URI, body, process_body: false,
                                                content_md5: content_md5)

      file_info.entries[0]
    end

    def upload_new_version_of_file(path_to_file, file, content_modified_at: nil, send_content_md5: true,
                                   preflight_check: true, if_match: nil, name: nil)
      filename = name || File.basename(path_to_file)

      File.open(path_to_file) do |io|
        upload_new_version_of_file_from_io(io, file, name: filename,
                                                     content_modified_at: content_modified_at, preflight_check: preflight_check, send_content_md5: send_content_md5, if_match: if_match)
      end
    end

    def upload_new_version_of_file_from_io(io, file, name: nil, content_modified_at: nil, send_content_md5: true,
                                           preflight_check: true, if_match: nil)
      name || file.name

      file_id = ensure_id(file)
      preflight_check_new_version_of_file(io, file_id) if preflight_check

      uri = "#{UPLOAD_URI}/files/#{file_id}/content"

      if send_content_md5
        content_md5 = Digest::SHA1.hexdigest(io.read)
        io.rewind
      end

      attributes = { name: name }
      unless content_modified_at.nil?
        attributes[:content_modified_at] =
          content_modified_at.to_datetime.rfc3339
      end

      body = { attributes: JSON.dump(attributes), file: io }

      file_info, = post(uri, body, process_body: false, content_md5: content_md5,
                                   if_match: if_match)

      file_info.entries[0]
    end

    def versions_of_file(file)
      file_id = ensure_id(file)
      uri = "#{FILES_URI}/#{file_id}/versions"
      versions, = get(uri)
      versions.entries
    end

    def promote_old_version_of_file(file, file_version)
      file_id = ensure_id(file)
      file_version_id = ensure_id(file_version)

      uri = "#{FILES_URI}/#{file_id}/versions/current"
      attributes = { type: 'file_version', id: file_version_id }
      new_version, = post(uri, attributes)
      new_version
    end

    def delete_file(file, if_match: nil)
      file_id = ensure_id(file)
      uri = "#{FILES_URI}/#{file_id}"
      result, = delete(uri, if_match: if_match)
      result
    end

    def delete_old_version_of_file(file, file_version, if_match: nil)
      file_id = ensure_id(file)
      file_version_id = ensure_id(file_version)

      uri = "#{FILES_URI}/#{file_id}/versions/#{file_version_id}"
      result, = delete(uri, if_match: if_match)
      result
    end

    def copy_file(file, parent, name: nil)
      file_id = ensure_id(file)
      parent_id = ensure_id(parent)

      uri = "#{FILES_URI}/#{file_id}/copy"
      attributes = { parent: { id: parent_id } }
      attributes[:name] = name unless name.nil?
      new_file, = post(uri, attributes)
      new_file
    end

    def thumbnail(file, min_height: nil, min_width: nil, max_height: nil, max_width: nil)
      file_id = ensure_id(file)
      uri = "#{FILES_URI}/#{file_id}/thumbnail.png"
      query = {}
      query[:min_height] = min_height unless min_height.nil?
      query[:min_width] = min_width unless min_width.nil?
      query[:max_height] = max_height unless max_height.nil?
      query[:max_width] = max_width unless max_width.nil?
      body, response = get(uri, query: query, success_codes: [302, 202, 200],
                                process_response: false)

      if [202, 302].include?(response.status)
        location = response.header['Location'][0]
        thumbnail, = get(location, process_response: false)
      else # 200
        thumbnail = body
      end

      thumbnail
    end

    def create_shared_link_for_file(file, access: nil, unshared_at: nil, can_download: nil,
                                    can_preview: nil, password: nil)
      file_id = ensure_id(file)
      uri = "#{FILES_URI}/#{file_id}"
      create_shared_link(uri, file_id, access, unshared_at, can_download, can_preview, password)
    end

    def disable_shared_link_for_file(file)
      file_id = ensure_id(file)
      uri = "#{FILES_URI}/#{file_id}"
      disable_shared_link(uri)
    end

    def trashed_file(file, fields: [])
      file_id = ensure_id(file)
      uri = "#{FILES_URI}/#{file_id}/trash"
      query = build_fields_query(fields, FOLDER_AND_FILE_FIELDS_QUERY)

      trashed_file, = get(uri, query: query)
      trashed_file
    end

    def delete_trashed_file(file)
      file_id = ensure_id(file)
      uri = "#{FILES_URI}/#{file_id}/trash"

      result, = delete(uri)
      result
    end

    def restore_trashed_file(file, name: nil, parent: nil)
      file_id = ensure_id(file)
      parent_id = ensure_id(parent)

      uri = "#{FILES_URI}/#{file_id}"
      restore_trashed_item(uri, name, parent_id)
    end

    private

    def preflight_check(io, filename, parent_id)
      size = io.size

      # TODO: need to make sure that figuring out the filename from the path_to_file works for people using Windows
      attributes = { name: filename, parent: { id: parent_id.to_s }, size: size }
      options("#{FILES_URI}/content", attributes)
    end

    def preflight_check_new_version_of_file(io, file_id)
      size = io.size
      attributes = { size: size }
      options("#{FILES_URI}/#{file_id}/content", attributes)
    end
  end
end

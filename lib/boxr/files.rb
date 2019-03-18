# frozen_string_literal: true

module Boxr
  class Client
    def file_from_path(path)
      path = path.slice(1..-1) if path.start_with?('/')

      path_items = path.split('/')
      file_name = path_items.slice!(-1)

      folder = folder_from_path(path_items.join('/'))

      files = folder_items(folder, fields: %i[id name]).files
      file = files.select { |f| f.name == file_name }.first
      raise BoxrError.new(boxr_message: "File not found: '#{file_name}'") if file.nil?

      file
    end

    def file_from_id(file_id, fields: [])
      file_id = ensure_id(file_id)
      uri = "#{FILES_URI}/#{file_id}"
      query = build_fields_query(fields, FOLDER_AND_FILE_FIELDS_QUERY)
      file, response = get(uri, query: query)
      file
    end
    alias file file_from_id

    def embed_url(file, show_download: false, show_annotations: false)
      file_info = file_from_id(file, fields: [:expiring_embed_link])
      url = file_info.expiring_embed_link.url + "?showDownload=#{show_download}&showAnnotations=#{show_annotations}"
      url
    end
    alias embed_link embed_url
    alias preview_url embed_url
    alias preview_link embed_url

    def update_file(file, name: nil, description: nil, parent: nil, shared_link: nil, tags: nil, lock: nil, if_match: nil)
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

      updated_file, response = put(uri, attributes, if_match: if_match)
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

      updated_file, response = put(uri, attributes, if_match: if_match)
      updated_file
    end

    def move_file(file, new_parent, name: nil, if_match: nil)
      update_file(file, parent: new_parent, name: name, if_match: if_match)
    end

    def download_file(file, version: nil, follow_redirect: true)
      file_id = ensure_id(file)
      begin
        uri = "#{FILES_URI}/#{file_id}/content"
        query = {}
        query[:version] = version unless version.nil?
        body_json, response = get(uri, query: query, success_codes: [302, 202], process_response: false, follow_redirect: false) # we don't want httpclient to automatically follow the redirect; we need to grab it

        if response.status == 302
          location = response.header['Location'][0]

          if follow_redirect
            file, response = get(location, process_response: false)
          else
            return location # simply return the url
          end
        elsif response.status == 202
          retry_after_seconds = response.header['Retry-After'][0]
          sleep retry_after_seconds.to_i
        end
      end until file

      file
    end

    def download_url(file, version: nil)
      download_file(file, version: version, follow_redirect: false)
    end

    def upload_file(path_to_file, parent, name: nil, content_created_at: nil, content_modified_at: nil,
                    preflight_check: true, send_content_md5: true)

      parent_id = ensure_id(parent)

      filename = name || File.basename(path_to_file)
      preflight_check(path_to_file, filename, parent_id) if preflight_check

      file_info = nil
      response = nil

      File.open(path_to_file) do |file|
        content_md5 = send_content_md5 ? Digest::SHA1.file(file).hexdigest : nil

        attributes = { name: filename, parent: { id: parent_id } }
        attributes[:content_created_at] = content_created_at.to_datetime.rfc3339 unless content_created_at.nil?
        attributes[:content_modified_at] = content_modified_at.to_datetime.rfc3339 unless content_modified_at.nil?

        body = { attributes: JSON.dump(attributes), file: file }

        file_info, response = post(FILES_UPLOAD_URI, body, process_body: false, content_md5: content_md5)
      end

      file_info.entries[0]
    end

    def upload_new_version_of_file(path_to_file, file, content_modified_at: nil, send_content_md5: true,
                                    preflight_check: true, if_match: nil, name: nil)
      filename = name ? name : File.basename(path_to_file)

      file_id = ensure_id(file)
      preflight_check_new_version_of_file(path_to_file, file_id) if preflight_check

      uri = "#{UPLOAD_URI}/files/#{file_id}/content"
      file_info = nil
      response = nil

      File.open(path_to_file) do |file|
        content_md5 = send_content_md5 ? Digest::SHA1.file(file).hexdigest : nil
        attributes = {name: filename}
        attributes[:content_modified_at] = content_modified_at.to_datetime.rfc3339 unless content_modified_at.nil?
        body = {attributes: JSON.dump(attributes), file: file}
        file_info, response = post(uri, body, process_body: false, content_md5: content_md5, if_match: if_match)
      end

      file_info.entries[0]
    end

    def versions_of_file(file)
      file_id = ensure_id(file)
      uri = "#{FILES_URI}/#{file_id}/versions"
      versions, response = get(uri)
      versions.entries
    end

    def promote_old_version_of_file(file, file_version)
      file_id = ensure_id(file)
      file_version_id = ensure_id(file_version)

      uri = "#{FILES_URI}/#{file_id}/versions/current"
      attributes = { type: 'file_version', id: file_version_id }
      new_version, res = post(uri, attributes)
      new_version
    end

    def delete_file(file, if_match: nil)
      file_id = ensure_id(file)
      uri = "#{FILES_URI}/#{file_id}"
      result, response = delete(uri, if_match: if_match)
      result
    end

    def delete_old_version_of_file(file, file_version, if_match: nil)
      file_id = ensure_id(file)
      file_version_id = ensure_id(file_version)

      uri = "#{FILES_URI}/#{file_id}/versions/#{file_version_id}"
      result, response = delete(uri, if_match: if_match)
      result
    end

    def copy_file(file, parent, name: nil)
      file_id = ensure_id(file)
      parent_id = ensure_id(parent)

      uri = "#{FILES_URI}/#{file_id}/copy"
      attributes = { parent: { id: parent_id } }
      attributes[:name] = name unless name.nil?
      new_file, res = post(uri, attributes)
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
      body, response = get(uri, query: query, success_codes: [302, 202, 200], process_response: false)

      if response.status == 202 || response.status == 302
        location = response.header['Location'][0]
        thumbnail, response = get(location, process_response: false)
      else # 200
        thumbnail = body
      end

      thumbnail
    end

    def create_shared_link_for_file(file, access: nil, unshared_at: nil, can_download: nil, can_preview: nil, password: nil)
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

      trashed_file, response = get(uri, query: query)
      trashed_file
    end

    def delete_trashed_file(file)
      file_id = ensure_id(file)
      uri = "#{FILES_URI}/#{file_id}/trash"

      result, response = delete(uri)
      result
    end

    def restore_trashed_file(file, name: nil, parent: nil)
      file_id = ensure_id(file)
      parent_id = ensure_id(parent)

      uri = "#{FILES_URI}/#{file_id}"
      restore_trashed_item(uri, name, parent_id)
    end

    private

    def preflight_check(path_to_file, filename, parent_id)
      size = File.size(path_to_file)

      # TODO: need to make sure that figuring out the filename from the path_to_file works for people using Windows
      attributes = { name: filename, parent: { id: parent_id.to_s }, size: size }
      body_json, res = options("#{FILES_URI}/content", attributes)
    end

    def preflight_check_new_version_of_file(path_to_file, file_id)
      size = File.size(path_to_file)
      attributes = { size: size }
      body_json, res = options("#{FILES_URI}/#{file_id}/content", attributes)
    end
  end
end

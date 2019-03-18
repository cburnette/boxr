# frozen_string_literal: true

module Boxr
  class Client
    def folder_from_path(path)
      path = path.slice(1..-1) if path.start_with?('/')

      path_folders = path.split('/')

      folder = path_folders.inject(Boxr::ROOT) do |parent_folder, folder_name|
        folders = folder_items(parent_folder, fields: %i[id name]).folders
        folder = folders.select { |f| f.name == folder_name }.first
        raise BoxrError.new(boxr_message: "Folder not found: '#{folder_name}'") if folder.nil?

        folder
      end
    end

    def folder_from_id(folder_id, fields: [])
      folder_id = ensure_id(folder_id)
      query = build_fields_query(fields, FOLDER_AND_FILE_FIELDS_QUERY)
      uri = "#{FOLDERS_URI}/#{folder_id}"

      folder, response = get(uri, query: query)
      folder
    end
    alias folder folder_from_id

    def folder_items(folder, fields: [], offset: nil, limit: nil)
      folder_id = ensure_id(folder)
      query = build_fields_query(fields, FOLDER_AND_FILE_FIELDS_QUERY)
      uri = "#{FOLDERS_URI}/#{folder_id}/items"

      if offset.nil? || limit.nil?
        items = get_all_with_pagination(uri, query: query, offset: 0, limit: FOLDER_ITEMS_LIMIT)
      else
        query[:offset] = offset
        query[:limit] = limit
        items, response = get(uri, query: query)
        items['entries']
      end
    end

    def root_folder_items(fields: [], offset: nil, limit: nil)
      folder_items(Boxr::ROOT, fields: fields, offset: offset, limit: limit)
    end

    def create_folder(name, parent)
      parent_id = ensure_id(parent)

      uri = FOLDERS_URI.to_s
      attributes = { name: name, parent: { id: parent_id } }

      created_folder, response = post(uri, attributes)
      created_folder
    end

    def update_folder(folder, name: nil, description: nil, parent: nil, shared_link: nil,
                      folder_upload_email_access: nil, owned_by: nil, sync_state: nil, tags: nil,
                      can_non_owners_invite: nil, if_match: nil)
      folder_id = ensure_id(folder)
      parent_id = ensure_id(parent)
      owned_by_id = ensure_id(owned_by)
      uri = "#{FOLDERS_URI}/#{folder_id}"

      attributes = {}
      attributes[:name] = name unless name.nil?
      attributes[:description] = description unless description.nil?
      attributes[:parent] = { id: parent_id } unless parent_id.nil?
      attributes[:shared_link] = shared_link unless shared_link.nil?
      attributes[:folder_upload_email] = { access: folder_upload_email_access } unless folder_upload_email_access.nil?
      attributes[:owned_by] = { id: owned_by_id } unless owned_by_id.nil?
      attributes[:sync_state] = sync_state unless sync_state.nil?
      attributes[:tags] = tags unless tags.nil?
      attributes[:can_non_owners_invite] = can_non_owners_invite unless can_non_owners_invite.nil?

      updated_folder, response = put(uri, attributes, if_match: if_match)
      updated_folder
    end

    def move_folder(folder, new_parent, name: nil, if_match: nil)
      update_folder(folder, parent: new_parent, name: name, if_match: if_match)
    end

    def delete_folder(folder, recursive: false, if_match: nil)
      folder_id = ensure_id(folder)
      uri = "#{FOLDERS_URI}/#{folder_id}"
      query = { recursive: recursive }

      result, response = delete(uri, query: query, if_match: if_match)
      result
    end

    def copy_folder(folder, dest_folder, name: nil)
      folder_id = ensure_id(folder)
      dest_folder_id = ensure_id(dest_folder)

      uri = "#{FOLDERS_URI}/#{folder_id}/copy"
      attributes = { parent: { id: dest_folder_id } }
      attributes[:name] = name unless name.nil?

      new_folder, response = post(uri, attributes)
      new_folder
    end

    def create_shared_link_for_folder(folder, access: nil, unshared_at: nil, can_download: nil, can_preview: nil, password: nil)
      folder_id = ensure_id(folder)
      uri = "#{FOLDERS_URI}/#{folder_id}"
      create_shared_link(uri, folder_id, access, unshared_at, can_download, can_preview, password)
    end

    def disable_shared_link_for_folder(folder)
      folder_id = ensure_id(folder)
      uri = "#{FOLDERS_URI}/#{folder_id}"
      disable_shared_link(uri)
    end

    def trash(fields: [], offset: nil, limit: nil)
      uri = "#{FOLDERS_URI}/trash/items"
      query = build_fields_query(fields, FOLDER_AND_FILE_FIELDS_QUERY)

      if offset.nil? || limit.nil?
        items = get_all_with_pagination(uri, query: query, offset: 0, limit: FOLDER_ITEMS_LIMIT)
      else
        query[:offset] = offset
        query[:limit] = limit
        items, response = get(uri, query: query)
        items['entries']
      end
    end

    def trashed_folder(folder, fields: [])
      folder_id = ensure_id(folder)
      uri = "#{FOLDERS_URI}/#{folder_id}/trash"
      query = build_fields_query(fields, FOLDER_AND_FILE_FIELDS_QUERY)

      folder, response = get(uri, query: query)
      folder
    end

    def delete_trashed_folder(folder)
      folder_id = ensure_id(folder)
      uri = "#{FOLDERS_URI}/#{folder_id}/trash"
      result, response = delete(uri)
      result
    end

    def restore_trashed_folder(folder, name: nil, parent: nil)
      folder_id = ensure_id(folder)
      parent_id = ensure_id(parent)

      uri = "#{FOLDERS_URI}/#{folder_id}"
      restore_trashed_item(uri, name, parent_id)
    end
  end
end

module Boxr
	class Client

		def folder_items(folder_id, fields: [])
			query = build_fields_query(fields, FOLDER_AND_FILE_FIELDS_QUERY)
			uri = "#{FOLDERS_URI}/#{folder_id}/items"

			items = get_with_pagination uri, query: query, limit: FOLDER_ITEMS_LIMIT
		end

		def create_folder(name, parent_id)
			uri = "#{FOLDERS_URI}"
			attributes = {:name => name, :parent => {:id => parent_id}}
			
			created_folder, response = post uri, attributes
			created_folder
		end

		def folder_info(folder_id, fields: [])
			query = build_fields_query(fields, FOLDER_AND_FILE_FIELDS_QUERY)
			uri = "#{FOLDERS_URI}/#{folder_id}"

			folder, response = get uri, query: query
			folder
		end

		def update_folder_info(folder_id, name: nil, description: nil, parent_id: nil, shared_link: nil,
													 folder_upload_email: nil, owned_by_id: nil, sync_state: nil, tags: nil,
													 can_non_owners_invite: nil, if_match: nil)
			uri = "#{FOLDERS_URI}/#{folder_id}"

			attributes = {}
			attributes[:name] = name unless name.nil?
			attributes[:description] = description unless description.nil?
			attributes[:parent_id] = {id: parent_id} unless parent_id.nil?
			attributes[:shared_link] = shared_link unless shared_link.nil?
			attributes[:folder_upload_email] = folder_upload_email unless folder_upload_email.nil?
			attributes[:owned_by_id] = {owned_by: owned_by_id} unless owned_by_id.nil?
			attributes[:sync_state] = sync_state unless sync_state.nil?
			attributes[:tags] = tags unless tags.nil? 
			attributes[:can_non_owners_invite] = can_non_owners_invite unless can_non_owners_invite.nil?

			updated_folder, response = put uri, attributes, if_match: if_match
			updated_folder
		end

		def delete_folder(folder_id, recursive: false, if_match: nil)
			uri = "#{FOLDERS_URI}/#{folder_id}"
			query = {:recursive => recursive}

			result, response = delete uri, query, if_match: if_match
			result
		end

		def copy_folder(folder_id, dest_folder_id, name: nil)
			uri = "#{FOLDERS_URI}/#{folder_id}/copy"
			attributes = {:parent => {:id => dest_folder_id}}
			attributes[:name] = name unless name.nil?

			new_folder, response = post uri, attributes
			new_folder
		end

	  def create_shared_link_for_folder(folder_id, access: nil, unshared_at: nil, can_download: nil, can_preview: nil)
			uri = "#{FOLDERS_URI}/#{folder_id}"
			create_shared_link(uri, folder_id, access, unshared_at, can_download, can_preview)
		end

		def disable_shared_link_for_folder(folder_id)
			uri = "#{FOLDERS_URI}/#{folder_id}"
			disable_shared_link(uri, folder_id)
		end

		def folder_collaborations(folder_id)
			uri = "#{FOLDERS_URI}/#{folder_id}/collaborations"
			collaborations, response = get uri
			collaborations
		end

		def trash(fields: [])
			uri = "#{FOLDERS_URI}/trash/items"
			query = build_fields_query(fields, FOLDER_AND_FILE_FIELDS_QUERY)

			items = get_with_pagination uri, query: query, limit: FOLDER_ITEMS_LIMIT
		end

		def trashed_folder(folder_id)
			uri = "#{FOLDERS_URI}/#{folder_id}/trash"
			item, response = get uri
			item
		end

		def delete_trashed_folder(folder_id)
			uri = "#{FOLDERS_URI}/#{folder_id}/trash"
			result, response = delete uri
			result
		end

		def restore_trashed_folder(folder_id, name: nil, parent_id: nil)
			uri = "#{FOLDERS_URI}/#{folder_id}"
			restore_trashed_item(uri, name, parent_id)
		end

	end
end
module Boxr
	class Client

		def shared_item(shared_link, shared_link_password: nil)
			box_api_header = "shared_link=#{shared_link}"
			box_api_header += "&shared_link_password=#{shared_link_password}" unless shared_link_password.nil?

			file_or_folder, response = get(SHARED_ITEMS_URI, box_api_header: box_api_header)
			file_or_folder
		end

		def create_shared_link(uri, item_id, access, unshared_at, can_download, can_preview)
			if access.nil?
				attributes = {shared_link: {}}
			else
				attributes = {shared_link: {access: access}}
				attributes[:shared_link][:unshared_at] = unshared_at.to_datetime.rfc3339 if unshared_at
				attributes[:shared_link][:permissions] = {} unless can_download.nil? && can_preview.nil?
				attributes[:shared_link][:permissions][:can_download] = can_download unless can_download.nil?
				attributes[:shared_link][:permissions][:can_preview] = can_preview unless can_preview.nil?
			end

			updated_item, response = put uri, attributes
			updated_item
		end

		def disable_shared_link(uri, item_id)
			attributes = {shared_link: nil}

			updated_item, response = put uri, attributes
			updated_item
		end

	end
end
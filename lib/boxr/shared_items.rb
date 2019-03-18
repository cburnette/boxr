# frozen_string_literal: true

module Boxr
  class Client
    def shared_item(shared_link, shared_link_password: nil)
      box_api_header = "shared_link=#{shared_link}"
      box_api_header += "&shared_link_password=#{shared_link_password}" unless shared_link_password.nil?

      file_or_folder, response = get(SHARED_ITEMS_URI, box_api_header: box_api_header)
      file_or_folder
    end
  end
end

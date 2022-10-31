# frozen_string_literal: true

module Boxr
  class Client
    def create_zip_download(targets, download_file_name: nil)
      attributes = {
        download_file_name: download_file_name,
        items: targets
      }
      zip_download, _response = post(ZIP_DOWNLOADS_URI, attributes, success_codes: [200, 202])
      zip_download
    end
  end
end

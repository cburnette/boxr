module Boxr
  class Client

    def get_watermark_on_file(file_id)

      file_id = ensure_id(file_id)
      uri = "#{FILES_URI}/#{file_id}/watermark"

      file, response = get(uri)
      file
    end

    def apply_watermark_on_file(file_id)

      file_id = ensure_id(file_id)
      uri = "#{FILES_URI}/#{file_id}/watermark"

      attributes = {}
      attributes[:watermark] = {:imprint => "default"}

      file, response = put(uri, attributes, content_type: "application/json")
      file
    end

    def remove_watermark_on_file(file_id)

      file_id = ensure_id(file_id)
      uri = "#{FILES_URI}/#{file_id}/watermark"

      result, response = delete(uri)
      result
    end

    def get_watermark_on_folder(folder_id)

      folder_id = ensure_id(folder_id)
      uri = "#{FOLDERS_URI}/#{folder_id}/watermark"

      folder, response = get(uri)
      folder
    end

    def apply_watermark_on_folder(folder_id)

      folder_id = ensure_id(folder_id)
      uri = "#{FOLDERS_URI}/#{folder_id}/watermark"

      attributes = {}
      attributes[:watermark] = {:imprint => "default"}

      folder, response = put(uri, attributes, content_type: "application/json")
      folder
    end

    def remove_watermark_on_folder(folder_id)

      folder_id = ensure_id(folder_id)
      uri = "#{FOLDERS_URI}/#{folder_id}/watermark"

      result, response = delete(uri)
      result
    end


  end
end

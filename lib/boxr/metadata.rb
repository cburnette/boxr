module Boxr
  class Client

    def create_metadata(file, metadata, type: :properties)
      file_id = ensure_id(file)
      uri = "#{METADATA_URI}/#{file_id}/metadata/#{type}"
      metadata, response = post(uri, metadata, content_type: "application/json")
      metadata
    end

    def metadata(file, type: :properties)
      file_id = ensure_id(file)
      uri = "#{METADATA_URI}/#{file_id}/metadata/#{type}"
      metadata, response = get(uri)
      metadata
    end

    def update_metadata(file, updates, type: :properties)
      file_id = ensure_id(file)
      uri = "#{METADATA_URI}/#{file_id}/metadata/#{type}"
      metadata, response = put(uri, updates, content_type: "application/json-patch+json")
      metadata
    end

    def delete_metadata(file, type: :properties)
      file_id = ensure_id(file)
      uri = "#{METADATA_URI}/#{file_id}/metadata/#{type}"
      result, response = delete(uri)
      result
    end

  end
end
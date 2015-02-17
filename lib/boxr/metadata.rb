module Boxr
  class Client

    def create_metadata(file, metadata, scope: :global, template: :properties)
      file_id = ensure_id(file)
      uri = "#{METADATA_URI}/#{file_id}/metadata/#{scope}/#{template}"
      metadata, response = post(uri, metadata, content_type: "application/json")
      metadata
    end

    def metadata(file, scope: :global, template: :properties)
      file_id = ensure_id(file)
      uri = "#{METADATA_URI}/#{file_id}/metadata/#{scope}/#{template}"
      metadata, response = get(uri)
      metadata
    end

    def update_metadata(file, updates, scope: :global, template: :properties)
      file_id = ensure_id(file)
      uri = "#{METADATA_URI}/#{file_id}/metadata/#{scope}/#{template}"
      metadata, response = put(uri, updates, content_type: "application/json-patch+json")
      metadata
    end

    def delete_metadata(file, scope: :global, template: :properties)
      file_id = ensure_id(file)
      uri = "#{METADATA_URI}/#{file_id}/metadata/#{scope}/#{template}"
      result, response = delete(uri)
      result
    end

  end
end
# frozen_string_literal: true

module Boxr
  class Client
    def create_metadata(file, metadata, scope: :global, template: :properties)
      file_id = ensure_id(file)
      uri = "#{FILE_METADATA_URI}/#{file_id}/metadata/#{scope}/#{template}"
      metadata, response = post(uri, metadata, content_type: 'application/json')
      metadata
    end

    def create_folder_metadata(folder, metadata, scope, template)
      folder_id = ensure_id(folder)
      uri = "#{FOLDER_METADATA_URI}/#{folder_id}/metadata/#{scope}/#{template}"
      metadata, response = post(uri, metadata, content_type: 'application/json')
      metadata
    end

    def metadata(file, scope: :global, template: :properties)
      file_id = ensure_id(file)
      uri = "#{FILE_METADATA_URI}/#{file_id}/metadata/#{scope}/#{template}"
      metadata, response = get(uri)
      metadata
    end

    def folder_metadata(folder, scope, template)
      folder_id = ensure_id(folder)
      uri = "#{FOLDER_METADATA_URI}/#{folder_id}/metadata/#{scope}/#{template}"
      metadata, response = get(uri)
      metadata
    end

    def all_metadata(file)
      file_id = ensure_id(file)
      uri = "#{FILE_METADATA_URI}/#{file_id}/metadata"
      all_metadata, response = get(uri)
      all_metadata
    end

    def update_metadata(file, updates, scope: :global, template: :properties)
      file_id = ensure_id(file)
      uri = "#{FILE_METADATA_URI}/#{file_id}/metadata/#{scope}/#{template}"

      # in the event just one update is specified ensure that it is packaged inside an array
      updates = [updates] unless updates.is_a? Array

      metadata, response = put(uri, updates, content_type: 'application/json-patch+json')
      metadata
    end

    def update_folder_metadata(folder, updates, scope, template)
      folder_id = ensure_id(folder)
      uri = "#{FOLDER_METADATA_URI}/#{folder_id}/metadata/#{scope}/#{template}"

      # in the event just one update is specified ensure that it is packaged inside an array
      updates = [updates] unless updates.is_a? Array

      metadata, response = put(uri, updates, content_type: 'application/json-patch+json')
      metadata
    end

    def delete_metadata(file, scope: :global, template: :properties)
      file_id = ensure_id(file)
      uri = "#{FILE_METADATA_URI}/#{file_id}/metadata/#{scope}/#{template}"
      result, response = delete(uri)
      result
    end

    def delete_folder_metadata(folder, scope, template)
      folder_id = ensure_id(folder)
      uri = "#{FOLDER_METADATA_URI}/#{folder_id}/metadata/#{scope}/#{template}"
      result, response = delete(uri)
      result
    end

    def enterprise_metadata
      uri = "#{METADATA_TEMPLATES_URI}/enterprise"
      ent_metadata, response = get(uri)
      ent_metadata
    end

    def metadata_schema(scope, template_key)
      uri = "#{METADATA_TEMPLATES_URI}/#{scope}/#{template_key}/schema"
      schema, response = get(uri)
      schema
    end
  end
end

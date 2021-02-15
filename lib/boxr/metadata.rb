module Boxr
  class Client

    def create_metadata(file, metadata, scope: :global, template: :properties)
      file_id = ensure_id(file)
      uri = "#{FILE_METADATA_URI}/#{file_id}/metadata/#{scope}/#{template}"
      metadata, response = post(uri, metadata, content_type: "application/json")
      metadata
    end

    def create_folder_metadata(folder, metadata, scope, template)
      folder_id = ensure_id(folder)
      uri = "#{FOLDER_METADATA_URI}/#{folder_id}/metadata/#{scope}/#{template}"
      metadata, response = post(uri, metadata, content_type: "application/json")
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

    def all_folder_metadata(folder)
      folder_id = ensure_id(folder)
      uri = "#{FOLDER_METADATA_URI}/#{folder_id}/metadata"
      all_metadata, response = get(uri)
      all_metadata
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

      #in the event just one update is specified ensure that it is packaged inside an array
      updates = [updates] unless updates.is_a? Array

      metadata, response = put(uri, updates, content_type: "application/json-patch+json")
      metadata
    end

    def update_folder_metadata(folder, updates, scope, template)
      folder_id = ensure_id(folder)
      uri = "#{FOLDER_METADATA_URI}/#{folder_id}/metadata/#{scope}/#{template}"

      #in the event just one update is specified ensure that it is packaged inside an array
      updates = [updates] unless updates.is_a? Array

      metadata, response = put(uri, updates, content_type: "application/json-patch+json")
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
    alias :get_enterprise_templates :enterprise_metadata

    def metadata_schema(scope, template_key)
      uri = "#{METADATA_TEMPLATES_URI}/#{scope}/#{template_key}/schema"
      schema, response = get(uri)
      schema
    end
    alias :get_metadata_template_by_name :metadata_schema

    def get_metadata_template_by_id(template_id)
      template_id = ensure_id(template_id)
      uri = "#{METADATA_TEMPLATES_URI}/#{template_id}"
      schema, response = get(uri)
      schema
    end

    def create_metadata_template(display_name, template_key: nil, fields: [], hidden: nil)
      uri = "#{METADATA_TEMPLATES_URI}/schema"
      schema = {
        scope: "enterprise",
        displayName: display_name,
      }
      schema[:templateKey] = template_key unless template_key.nil?
      schema[:hidden] = hidden unless hidden.nil?
      schema[:fields] = fields unless fields.empty?

      metadata_template, response = post(uri, schema, content_type: "application/json")
      metadata_template
    end

    def delete_metadata_template(scope, template_key)
      uri = "#{METADATA_TEMPLATES_URI}/#{scope}/#{template_key}/schema"
      result, response = delete(uri)
      result
    end
  end
end

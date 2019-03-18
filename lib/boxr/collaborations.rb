# frozen_string_literal: true

module Boxr
  class Client
    def folder_collaborations(folder, fields: [])
      folder_id = ensure_id(folder)
      query = build_fields_query(fields, COLLABORATION_FIELDS_QUERY)
      uri = "#{FOLDERS_URI}/#{folder_id}/collaborations"

      collaborations, response = get(uri, query: query)
      collaborations['entries']
    end

    def add_collaboration(folder, accessible_by, role, fields: [], notify: nil)
      folder_id = ensure_id(folder)
      query = build_fields_query(fields, COLLABORATION_FIELDS_QUERY)
      query[:notify] = notify unless notify.nil?

      attributes = { item: { id: folder_id, type: :folder } }
      attributes[:accessible_by] = accessible_by
      attributes[:role] = validate_role(role)

      collaboration, response = post(COLLABORATIONS_URI, attributes, query: query)
      collaboration
    end

    def edit_collaboration(collaboration, role: nil, status: nil)
      collaboration_id = ensure_id(collaboration)
      uri = "#{COLLABORATIONS_URI}/#{collaboration_id}"
      attributes = {}
      attributes[:role] = validate_role(role) unless role.nil?
      attributes[:status] = status unless status.nil?

      updated_collaboration, response = put(uri, attributes)
      updated_collaboration
    end

    def remove_collaboration(collaboration)
      collaboration_id = ensure_id(collaboration)
      uri = "#{COLLABORATIONS_URI}/#{collaboration_id}"
      result, response = delete(uri)
      result
    end

    def collaboration(collaboration_id, fields: [], status: nil)
      collaboration_id = ensure_id(collaboration_id)
      uri = "#{COLLABORATIONS_URI}/#{collaboration_id}"

      query = build_fields_query(fields, COLLABORATION_FIELDS_QUERY)
      query[:status] = status unless status.nil?

      collaboration, response = get(uri, query: query)
      collaboration
    end

    # these are pending collaborations for the current user; use the As-User Header to request for different users
    def pending_collaborations(fields: [])
      query = build_fields_query(fields, COLLABORATION_FIELDS_QUERY)
      query[:status] = :pending
      pending_collaborations, response = get(COLLABORATIONS_URI, query: query)
      pending_collaborations['entries']
    end

    private

    def validate_role(role)
      case role
      when :previewer_uploader
        role = 'previewer uploader'
      when :viewer_uploader
        role = 'viewer uploader'
      when :co_owner
        role = 'co-owner'
      end

      role = role.to_s
      raise BoxrError.new(boxr_message: "Invalid collaboration role: '#{role}'") unless VALID_COLLABORATION_ROLES.include?(role)

      role
    end
  end
end

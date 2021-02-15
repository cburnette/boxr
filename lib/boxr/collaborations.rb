module Boxr
  class Client

    def folder_collaborations(folder, fields: [], offset: 0, limit: DEFAULT_LIMIT)
      folder_id = ensure_id(folder)
      query = build_fields_query(fields, COLLABORATION_FIELDS_QUERY)
      uri = "#{FOLDERS_URI}/#{folder_id}/collaborations"
      collaborations = get_all_with_pagination(uri, query: query, offset: offset, limit: limit)
    end

    def file_collaborations(file, fields: [], limit: DEFAULT_LIMIT, marker: nil)
      file_id = ensure_id(file)
      query = build_fields_query(fields, COLLABORATION_FIELDS_QUERY)
      query[:limit] = limit
      query[:marker] = marker unless marker.nil?

      uri = "#{FILES_URI}/#{file_id}/collaborations"

      collaborations, response = get(uri, query: query)
      collaborations['entries']
    end

    def group_collaborations(group, offset: 0, limit: DEFAULT_LIMIT)
      group_id = ensure_id(group)
      uri = "#{GROUPS_URI}/#{group_id}/collaborations"

      collaborations = get_all_with_pagination(uri, offset: offset, limit: limit)
    end

    def add_collaboration(item, accessible_by, role, fields: [], notify: nil, type: :folder)
      item_id = ensure_id(item)
      query = build_fields_query(fields, COLLABORATION_FIELDS_QUERY)
      query[:notify] = notify unless notify.nil?

      attributes = {item: {id: item_id, type: type}}
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

    #these are pending collaborations for the current user; use the As-User Header to request for different users
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

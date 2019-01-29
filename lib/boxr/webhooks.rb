module Boxr
  class Client
    def webhooks(fields: [])
      query = build_fields_query(fields, GROUP_FIELDS_QUERY)
      groups = get_all_with_pagination(GROUPS_URI, query: query, offset: 0, limit: DEFAULT_LIMIT)
    end

    def create_webhook(name)
      attributes = {name: name}
      new_group, response = post(GROUPS_URI, attributes)
      new_group
    end

    def webhook(group)
      group_id = ensure_id(group)
      uri = "#{GROUPS_URI}/#{group_id}/memberships"
      memberships = get_all_with_pagination(uri, offset: 0, limit: DEFAULT_LIMIT)
    end

    def update_webhook(group, name)
      group_id = ensure_id(group)
      uri = "#{GROUPS_URI}/#{group_id}"
      attributes = {name: name}

      updated_group, response = put(uri, attributes)
      updated_group
    end
    alias :rename_group :update_group

    def delete_webhook(group)
      group_id = ensure_id(group)
      uri = "#{GROUPS_URI}/#{group_id}"
      result, response = delete(uri)
      result
    end
  end
end

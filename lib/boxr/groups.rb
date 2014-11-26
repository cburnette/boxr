module Boxr
	class Client

		def groups(fields: [])
			query = build_fields_query(fields, GROUP_FIELDS_QUERY)
			groups = get_with_pagination(GROUPS_URI, query: query)
		end

		def create_group(name)
			attributes = {name: name}
			new_group, response = post(GROUPS_URI, attributes)
			new_group 
		end

		def update_group(group_id, name)
			uri = "#{GROUPS_URI}/#{group_id}"
			attributes = {name: name}

			updated_group, response = put(uri, attributes)
			updated_group
		end

		def delete_group(group_id)
			uri = "#{GROUPS_URI}/#{group_id}"
			result, response = delete(uri)
			result
		end

		def group_memberships(group_id)
			uri = "#{GROUPS_URI}/#{group_id}/memberships"
			memberships = get_with_pagination(uri)
		end

		def group_memberships_for_user(user_id)
			uri = "#{USERS_URI}/#{user_id}/memberships"
			memberships = get_with_pagination(uri)
		end

		def group_memberships_for_me
			uri = "#{USERS_URI}/me/memberships"
			memberships = get_with_pagination(uri)
		end

		def group_membership(membership_id)
			uri = "#{GROUP_MEMBERSHIPS_URI}/#{membership_id}"
			membership, response = get(uri)
			membership
		end

		def add_user_to_group(user_id, group_id, role: nil)
			attributes = {user: {id: user_id}, group: {id: group_id}}
			attributes[:role] = role unless role.nil?
			membership, response = post(GROUP_MEMBERSHIPS_URI, attributes)
			membership
		end

		def update_group_membership(membership_id, role)
			uri = "#{GROUP_MEMBERSHIPS_URI}/#{membership_id}"
			attributes = {role: role}
			updated_membership, response = put(uri, attributes)
			updated_membership
		end

		def delete_group_membership(membership_id)
			uri = "#{GROUP_MEMBERSHIPS_URI}/#{membership_id}"
			result, response = delete(uri)
			result
		end

		def group_collaborations(group_id)
			uri = "#{GROUPS_URI}/#{group_id}/collaborations"
			collaborations = get_with_pagination(uri)
		end

	end
end
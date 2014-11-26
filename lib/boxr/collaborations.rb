module Boxr
	class Client

		#make sure 'role' value is a string as Box has role values with spaces and dashes; e.g. 'previewer uploader'
		def add_collaboration(folder_id, accessible_by, role, fields: [], notify: nil)
			query = build_fields_query(fields, COLLABORATION_FIELDS_QUERY)
			query[:notify] = :notify unless notify.nil?

			attributes = {item: {id: folder_id, type: :folder}}
			attributes[:accessible_by] = accessible_by
			attributes[:role] = role

			collaboration, response = post(COLLABORATIONS_URI, attributes, query: query)
			collaboration
		end

		def edit_collaboration(collaboration_id, role: nil, status: nil)
			uri = "#{COLLABORATIONS_URI}/#{collaboration_id}"
			attributes = {}
			attributes[:role] = role unless role.nil?
			attributes[:status] = status unless status.nil?

			updated_collaboration, response = put(uri, attributes)
			updated_collaboration
		end

		def remove_collaboration(collaboration_id)
			uri = "#{COLLABORATIONS_URI}/#{collaboration_id}"
			result, response = delete(uri)
			result
		end

		def collaboration(collaboration_id, fields: [], status: nil)
			uri = "#{COLLABORATIONS_URI}/#{collaboration_id}"

			query = build_fields_query(fields, COLLABORATION_FIELDS_QUERY)
			query[:status] = status unless status.nil?

			collaboration, response = get(uri, query: query)
			collaboration
		end

		#these are pending collaborations for the current users; use the As-User Header to request for different users
		def pending_collaborations
			query = {status: :pending}
			pending_collaborations, response = get(COLLABORATIONS_URI, query: query)
			pending_collaborations['entries']
		end


	end
end
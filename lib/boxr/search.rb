module Boxr
	class Client

		def search(query, scope: nil, file_extensions: nil, created_at_range: nil, updated_at_range: nil, size_range: nil, 
											owner_user_ids: nil, ancestor_folder_ids: nil, content_types: nil, type: nil, 
											limit: 30, offset: 0)

			query = {query: query}
			query[:scope] = scope unless scope.nil?
			query[:file_extensions] = file_extensions unless file_extensions.nil?
			query[:created_at_range] = created_at_range unless created_at_range.nil?
			query[:updated_at_range] = updated_at_range unless updated_at_range.nil?
			query[:size_range] = size_range unless size_range.nil?
			query[:owner_user_ids] = owner_user_ids unless owner_user_ids.nil?
			query[:ancestor_folder_ids] = ancestor_folder_ids unless ancestor_folder_ids.nil?
			query[:content_types] = content_types unless content_types.nil?
			query[:type] = type unless type.nil?
			query[:limit] = limit unless limit.nil?
			query[:offset] = offset unless offset.nil?

			results, response = get SEARCH_URI, query: query
			[results["entries"],results.total_count]
		end

	end
end
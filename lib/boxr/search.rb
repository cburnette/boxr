# frozen_string_literal: true

module Boxr
  class Client
    def search(query = nil, scope: nil, file_extensions: [],
               created_at_range_from_date: nil, created_at_range_to_date: nil,
               updated_at_range_from_date: nil, updated_at_range_to_date: nil,
               size_range_lower_bound_bytes: nil, size_range_upper_bound_bytes: nil,
               owner_user_ids: [], ancestor_folder_ids: [], content_types: [], trash_content: nil,
               mdfilters: nil, type: nil, limit: 30, offset: 0)

      unless mdfilters.nil?
        unless mdfilters.is_a? String   # if a string is passed in assume it is already formatted correctly
          unless mdfilters.is_a? Array
            mdfilters = [mdfilters]     # if just one mdfilter is specified ensure that it is packaged inside an array
          end
          mdfilters = JSON.dump(mdfilters)
        end
      end

      # build range strings
      created_at_range_string = build_date_range_field(created_at_range_from_date, created_at_range_to_date)
      updated_at_range_string = build_date_range_field(updated_at_range_from_date, updated_at_range_to_date)
      size_range_string = build_size_range_field(size_range_lower_bound_bytes, size_range_upper_bound_bytes)

      # build comma separated strings
      file_extensions_string = to_comma_separated_string(file_extensions)
      owner_user_ids_string = to_comma_separated_string(owner_user_ids)
      ancestor_folder_ids_string = to_comma_separated_string(ancestor_folder_ids)
      content_types_string = to_comma_separated_string(content_types)

      search_query = {}
      search_query[:query] = query unless query.nil?
      search_query[:scope] = scope unless scope.nil?
      search_query[:file_extensions] = file_extensions_string unless file_extensions_string.nil?
      search_query[:created_at_range] = created_at_range_string unless created_at_range_string.nil?
      search_query[:updated_at_range] = updated_at_range_string unless updated_at_range_string.nil?
      search_query[:size_range] = size_range_string unless size_range_string.nil?
      search_query[:owner_user_ids] = owner_user_ids_string unless owner_user_ids_string.nil?
      search_query[:ancestor_folder_ids] = ancestor_folder_ids_string unless ancestor_folder_ids_string.nil?
      search_query[:content_types] = content_types_string unless content_types_string.nil?
      search_query[:trash_content] = trash_content unless trash_content.nil?
      search_query[:mdfilters] = mdfilters unless mdfilters.nil?
      search_query[:type] = type unless type.nil?
      search_query[:limit] = limit unless limit.nil?
      search_query[:offset] = offset unless offset.nil?

      results, response = get(SEARCH_URI, query: search_query)
      results.entries
    end

    private

    def build_date_range_field(from, to)
      from_string = from.nil? ? '' : from.to_datetime.rfc3339
      to_string = to.nil? ? '' : to.to_datetime.rfc3339
      build_range_string(from_string, to_string)
    end

    def build_size_range_field(lower, upper)
      lower_string = lower.nil? ? '' : lower.to_i
      upper_string = upper.nil? ? '' : upper.to_i
      build_range_string(lower_string, upper_string)
    end
  end
end

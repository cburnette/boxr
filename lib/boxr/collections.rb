# frozen_string_literal: true

module Boxr
  class Client
    def collections
      collections = get_all_with_pagination(COLLECTIONS_URI, offset: 0, limit: DEFAULT_LIMIT)
    end

    def collection_items(collection, fields: [])
      collection_id = ensure_id(collection)
      uri = "#{COLLECTIONS_URI}/#{collection_id}/items"
      query = build_fields_query(fields, FOLDER_AND_FILE_FIELDS_QUERY)
      items = get_all_with_pagination(uri, query: query, offset: 0, limit: DEFAULT_LIMIT)
    end
  end
end

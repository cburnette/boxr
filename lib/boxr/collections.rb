module Boxr
  class Client

    def collections(offset: 0, limit: DEFAULT_LIMIT)
      collections, response = get_with_paginations(COLLECTIONS_URI, offset: offset, limit: limit)
      collections['entries']
    end

  end
end
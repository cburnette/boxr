module Boxr
  class Client

    def collections(limit: 100, offset: 0)
      collections, response = get(COLLECTIONS_URI)
      collections['entries']
    end

  end
end
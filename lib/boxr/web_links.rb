module Boxr
  class Client

    def create_web_link(url, parent, name: nil, description: nil)

      parent_id = ensure_id(parent)
      web_link_url = verify_url(url)
      uri = "#{WEB_LINKS_URI}"

      attributes = {}
      attributes[:url] = web_link_url
      attributes[:parent] = {:id => parent_id}
      attributes[:name] = name unless name.nil?
      attributes[:description] = description unless description.nil?

      created_link, response = post(uri, attributes)
      created_link
    end

    def get_web_link(web_link)

      web_link_id = ensure_id(web_link)
      uri = "#{WEB_LINKS_URI}/#{web_link_id}"

      web_link, response = get(uri)
      web_link
    end

    def update_web_link(web_link, url: nil, parent: nil, name: nil, description: nil)

      web_link_id = ensure_id(web_link)
      parent_id = ensure_id(parent)
      uri = "#{WEB_LINKS_URI}/#{web_link_id}"

      attributes = {}
      attributes[:url] = url unless url.nil?
      attributes[:name] = name unless name.nil?
      attributes[:description] = description unless description.nil?
      attributes[:parent] = {id: parent_id} unless parent_id.nil?

      updated_web_link, response = put(uri, attributes)
      updated_web_link
    end

    def delete_web_link(web_link)

      web_link_id = ensure_id(web_link)
      uri = "#{WEB_LINKS_URI}/#{web_link_id}"

      result, response = delete(uri)
      result
    end

    def trashed_web_link(web_link, fields: [])
      web_link_id = ensure_id(web_link)
      uri = "#{WEB_LINKS_URI}/#{web_link_id}/trash"
      query = build_fields_query(fields, WEB_LINK_FIELDS_QUERY)

      web_link, response = get(uri, query: query)
      web_link
    end
    alias :get_trashed_web_link :trashed_web_link

    def delete_trashed_web_link(web_link)
      web_link_id = ensure_id(web_link)
      uri = "#{WEB_LINKS_URI}/#{web_link_id}/trash"
      result, response = delete(uri)
      result
    end

    def restore_trashed_web_link(web_link, name: nil, parent: nil)
      web_link_id = ensure_id(web_link)
      parent_id = ensure_id(parent)

      uri = "#{WEB_LINKS_URI}/#{web_link_id}"
      restore_trashed_item(uri, name, parent_id)
    end

    private

    def verify_url(item)
      return item if item.class == String and (item.include? 'https://' or item.include? 'http://')
      raise BoxrError.new(boxr_message: "Invalid url. Must include 'http://' or 'https://'")
    end

  end
end

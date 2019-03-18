# frozen_string_literal: true

module Boxr
  class Client
    def create_web_link(url, parent, name: nil, description: nil)
      parent_id = ensure_id(parent)
      web_link_url = verify_url(url)
      uri = WEB_LINKS_URI.to_s

      attributes = {}
      attributes[:url] = web_link_url
      attributes[:parent] = { id: parent_id }
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
      attributes[:parent] = { id: parent_id } unless parent_id.nil?

      updated_web_link, response = put(uri, attributes)
      updated_web_link
    end

    def delete_web_link(web_link)
      web_link_id = ensure_id(web_link)
      uri = "#{WEB_LINKS_URI}/#{web_link_id}"

      result, response = delete(uri)
      result
    end

    private

    def verify_url(item)
      return item if (item.class == String) && (item.include?('https://') || item.include?('http://'))

      raise BoxrError.new(boxr_message: "Invalid url. Must include 'http://' or 'https://'")
    end
  end
end

# frozen_string_literal: true

module Boxr
  class Client
    def get_user_avatar(user_id)
      user_id = ensure_id(user_id)
      uri = "#{USERS_URI}/#{user_id}/avatar"

      avatar_data, = get(uri, process_response: false)
      avatar_data
    end

    def create_user_avatar(user_id, pic, pic_file_name: nil, pic_content_type: nil)
      user_id = ensure_id(user_id)
      uri = "#{USERS_URI}/#{user_id}/avatar"

      body = { pic: pic }
      body[:pic_file_name] = pic_file_name unless pic_file_name.nil?
      body[:pic_content_type] = pic_content_type unless pic_content_type.nil?

      avatar, = post(uri, body, process_body: false, content_type: 'multipart/form-data')
      avatar
    end

    def delete_user_avatar(user_id)
      user_id = ensure_id(user_id)
      uri = "#{USERS_URI}/#{user_id}/avatar"

      result, = delete(uri)
      result
    end
  end
end

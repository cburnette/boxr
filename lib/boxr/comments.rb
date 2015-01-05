module Boxr
  class Client

    def file_comments(file_id, fields: [])
      uri = "#{FILES_URI}/#{file_id}/comments"
      query = build_fields_query(fields, COMMENT_FIELDS_QUERY)

      comments = get_with_pagination uri, query: query
    end

    def add_comment_to_file(file_id, message: nil, tagged_message: nil)
      add_comment(:file, file_id, message, tagged_message)
    end

    def reply_to_comment(comment_id, message: nil, tagged_message: nil)
      add_comment(:comment, comment_id, message, tagged_message)
    end

    def change_comment(comment_id, message)
      uri = "#{COMMENTS_URI}/#{comment_id}"
      attributes = {message: message}
      updated_comment, response = put uri, attributes
      updated_comment
    end

    def comment(comment_id, fields: [])
      uri ="#{COMMENTS_URI}/#{comment_id}"
      comment, response = get uri
      comment
    end

    def delete_comment(comment_id)
      uri = "#{COMMENTS_URI}/#{comment_id}"
      result, response = delete uri
      result
    end


    private

    def add_comment(type, id, message, tagged_message)
      uri = COMMENTS_URI
      attributes = {item: {type: type, id: id}}
      attributes[:message] = message unless message.nil?
      attributes[:tagged_message] = tagged_message unless tagged_message.nil?

      new_comment, response = post uri, attributes
      new_comment
    end

  end
end
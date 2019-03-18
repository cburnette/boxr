# frozen_string_literal: true

require 'base64'
module Boxr
  class Client
    attr_reader :access_token, :refresh_token, :client_id, :client_secret, :identifier, :as_user_id

    # API_URI = "https://wcheng.inside-box.net/api/2.0"
    # UPLOAD_URI = "https://upload.wcheng.inside-box.net/api/2.0"

    API_URI = 'https://api.box.com/2.0'
    UPLOAD_URI = 'https://upload.box.com/api/2.0'
    FILES_URI = "#{API_URI}/files"
    FILES_UPLOAD_URI = "#{UPLOAD_URI}/files/content"
    FOLDERS_URI = "#{API_URI}/folders"
    USERS_URI = "#{API_URI}/users"
    GROUPS_URI = "#{API_URI}/groups"
    GROUP_MEMBERSHIPS_URI = "#{API_URI}/group_memberships"
    COLLABORATIONS_URI = "#{API_URI}/collaborations"
    COLLECTIONS_URI = "#{API_URI}/collections"
    COMMENTS_URI = "#{API_URI}/comments"
    SEARCH_URI = "#{API_URI}/search"
    TASKS_URI = "#{API_URI}/tasks"
    TASK_ASSIGNMENTS_URI = "#{API_URI}/task_assignments"
    SHARED_ITEMS_URI = "#{API_URI}/shared_items"
    FILE_METADATA_URI = "#{API_URI}/files"
    FOLDER_METADATA_URI = "#{API_URI}/folders"
    METADATA_TEMPLATES_URI = "#{API_URI}/metadata_templates"
    EVENTS_URI = "#{API_URI}/events"
    WEB_LINKS_URI = "#{API_URI}/web_links"
    WEBHOOKS_URI = "#{API_URI}/webhooks"

    DEFAULT_LIMIT = 100
    FOLDER_ITEMS_LIMIT = 1000

    FOLDER_AND_FILE_FIELDS = %i[type id sequence_id etag name created_at modified_at description
                                size path_collection created_by modified_by trashed_at purged_at
                                content_created_at content_modified_at owned_by shared_link folder_upload_email
                                parent item_status item_collection sync_state has_collaborations permissions tags
                                sha1 shared_link version_number comment_count lock extension is_package can_non_owners_invite].freeze
    FOLDER_AND_FILE_FIELDS_QUERY = FOLDER_AND_FILE_FIELDS.join(',')

    COMMENT_FIELDS = %i[type id is_reply_comment message tagged_message created_by created_at item modified_at].freeze
    COMMENT_FIELDS_QUERY = COMMENT_FIELDS.join(',')

    TASK_FIELDS = %i[type id item due_at action message task_assignment_collection is_completed created_by created_at].freeze
    TASK_FIELDS_QUERY = TASK_FIELDS.join(',')

    COLLABORATION_FIELDS = %i[type id created_by created_at modified_at expires_at status accessible_by role acknowledged_at item].freeze
    COLLABORATION_FIELDS_QUERY = COLLABORATION_FIELDS.join(',')

    USER_FIELDS = %i[type id name login created_at modified_at role language timezone space_amount space_used
                     max_upload_size tracking_codes can_see_managed_users is_sync_enabled is_external_collab_restricted
                     status job_title phone address avatar_uri is_exempt_from_device_limits is_exempt_from_login_verification
                     enterprise my_tags].freeze
    USER_FIELDS_QUERY = USER_FIELDS.join(',')

    GROUP_FIELDS = %i[type id name created_at modified_at].freeze
    GROUP_FIELDS_QUERY = GROUP_FIELDS.join(',')

    VALID_COLLABORATION_ROLES = ['editor', 'viewer', 'previewer', 'uploader', 'previewer uploader', 'viewer uploader', 'co-owner', 'owner'].freeze

    def initialize(access_token = ENV['BOX_DEVELOPER_TOKEN'],
                   refresh_token: nil,
                   client_id: ENV['BOX_CLIENT_ID'],
                   client_secret: ENV['BOX_CLIENT_SECRET'],
                   enterprise_id: ENV['BOX_ENTERPRISE_ID'],
                   jwt_private_key: Base64.strict_decode64(ENV['JWT_PRIVATE_KEY']),
                   jwt_private_key_password: ENV['JWT_PRIVATE_KEY_PASSWORD'],
                   jwt_public_key_id: ENV['JWT_PUBLIC_KEY_ID'],
                   identifier: nil,
                   as_user: nil,
                   &token_refresh_listener)

      @access_token = access_token
      raise BoxrError.new(boxr_message: 'Access token cannot be nil') if @access_token.nil?

      @refresh_token = refresh_token
      @client_id = client_id
      @client_secret = client_secret
      @enterprise_id = enterprise_id
      @jwt_private_key = jwt_private_key
      @jwt_private_key_password = jwt_private_key_password
      @jwt_public_key_id = jwt_public_key_id
      @identifier = identifier
      @as_user_id = ensure_id(as_user)
      @token_refresh_listener = token_refresh_listener
    end

    private

    def get(uri, query: nil, success_codes: [200], process_response: true, if_match: nil, box_api_header: nil, follow_redirect: true)
      uri = Addressable::URI.encode(uri)

      res = with_auto_token_refresh do
        headers = standard_headers
        headers['If-Match'] = if_match unless if_match.nil?
        headers['BoxApi'] = box_api_header unless box_api_header.nil?

        BOX_CLIENT.get(uri, query: query, header: headers, follow_redirect: follow_redirect)
      end

      check_response_status(res, success_codes)

      if process_response
        return processed_response(res)
      else
        return res.body, res
      end
    end

    def get_all_with_pagination(uri, query: {}, offset: 0, limit: DEFAULT_LIMIT, follow_redirect: true)
      uri = Addressable::URI.encode(uri)
      entries = []

      begin
        query[:limit] = limit
        query[:offset] = offset
        res = with_auto_token_refresh do
          headers = standard_headers
          BOX_CLIENT.get(uri, query: query, header: headers, follow_redirect: follow_redirect)
        end

        if res.status == 200
          body_json = JSON.load(res.body)
          total_count = body_json['total_count']
          offset += limit

          entries << body_json['entries']
        else
          raise BoxrError.new(status: res.status, body: res.body, header: res.header)
        end
      end until offset - total_count >= 0

      BoxrCollection.new(entries.flatten.map{ |i| BoxrMash.new(i) })
    end

    def post(uri, body, query: nil, success_codes: [201], process_body: true, content_md5: nil, content_type: nil, if_match: nil)
      uri = Addressable::URI.encode(uri)
      body = JSON.dump(body) if process_body

      res = with_auto_token_refresh do
        headers = standard_headers
        headers['If-Match'] = if_match unless if_match.nil?
        headers['Content-MD5'] = content_md5 unless content_md5.nil?
        headers['Content-Type'] = content_type unless content_type.nil?

        BOX_CLIENT.post(uri, body: body, query: query, header: headers)
      end

      check_response_status(res, success_codes)

      processed_response(res)
    end

    def put(uri, body, query: nil, success_codes: [200, 201], content_type: nil, if_match: nil)
      uri = Addressable::URI.encode(uri)

      res = with_auto_token_refresh do
        headers = standard_headers
        headers['If-Match'] = if_match unless if_match.nil?
        headers['Content-Type'] = content_type unless content_type.nil?

        BOX_CLIENT.put(uri, body: JSON.dump(body), query: query, header: headers)
      end

      check_response_status(res, success_codes)

      processed_response(res)
    end

    def delete(uri, query: nil, success_codes: [204], if_match: nil)
      uri = Addressable::URI.encode(uri)

      res = with_auto_token_refresh do
        headers = standard_headers
        headers['If-Match'] = if_match unless if_match.nil?

        BOX_CLIENT.delete(uri, query: query, header: headers)
      end

      check_response_status(res, success_codes)

      processed_response(res)
    end

    def options(uri, body, success_codes: [200])
      uri = Addressable::URI.encode(uri)

      res = with_auto_token_refresh do
        headers = standard_headers
        BOX_CLIENT.options(uri, body: JSON.dump(body), header: headers)
      end

      check_response_status(res, success_codes)

      processed_response(res)
    end

    def standard_headers
      headers = { 'Authorization' => "Bearer #{@access_token}" }
      if @jwt_private_key.nil?
        headers['As-User'] = @as_user_id.to_s unless @as_user_id.nil?
      end
      headers
    end

    def with_auto_token_refresh
      return yield unless @refresh_token || @jwt_private_key

      res = yield
      if res.status == 401
        auth_header = res.header['WWW-Authenticate'][0]
        if auth_header&.include?('invalid_token')
          if @refresh_token
            new_tokens = Boxr.refresh_tokens(@refresh_token, client_id: client_id, client_secret: client_secret)
            @access_token = new_tokens.access_token
            @refresh_token = new_tokens.refresh_token
            @token_refresh_listener&.call(@access_token, @refresh_token, @identifier)
          else
            if @as_user_id
              new_token = Boxr.get_user_token(@as_user_id, private_key: @jwt_private_key, private_key_password: @jwt_private_key_password, public_key_id: @jwt_public_key_id, client_id: @client_id, client_secret: @client_secret)
              @access_token = new_token.access_token
            else
              new_token = Boxr.get_enterprise_token(private_key: @jwt_private_key, private_key_password: @jwt_private_key_password, public_key_id: @jwt_public_key_id, enterprise_id: @enterprise_id, client_id: @client_id, client_secret: @client_secret)
              @access_token = new_token.access_token
            end
          end

          res = yield
        end
      end

      res
    end

    def check_response_status(res, success_codes)
      raise BoxrError.new(status: res.status, body: res.body, header: res.header) unless success_codes.include?(res.status)
    end

    def processed_response(res)
      body_json = JSON.load(res.body)
      [BoxrMash.new(body_json), res]
    end

    def build_fields_query(fields, all_fields_query)
      if fields == :all
        { fields: all_fields_query }
      elsif fields.is_a?(Array) && !fields.empty?
        { fields: fields.join(',') }
      else
        {}
      end
    end

    def to_comma_separated_string(values)
      return values if values.is_a?(String) || values.is_a?(Symbol)

      values.join(',') if values.is_a?(Array) && !values.empty?
    end

    def build_range_string(from, to)
      range_string = "#{from},#{to}"
      range_string = nil if range_string == ','
      range_string
    end

    def ensure_id(item)
      # Ruby 2.4 unified Fixnum and Bignum into Integer.  This tests for Ruby 2.4
      if 1.class == Integer
        return item if item.class == String || item.class == Integer || item.nil?
      else
        return item if item.class == String || item.class == Integer || item.class == Integer || item.nil?
      end

      return item.id if item.respond_to?(:id)

      raise BoxrError.new(boxr_message: 'Expecting an id of class String or Fixnum, or object that responds to :id')
    end

    def restore_trashed_item(uri, name, parent)
      parent_id = ensure_id(parent)

      attributes = {}
      attributes[:name] = name unless name.nil?
      attributes[:parent] = { id: parent_id } unless parent_id.nil?

      restored_item, response = post(uri, attributes)
      restored_item
    end

    def create_shared_link(uri, _item_id, access, unshared_at, can_download, can_preview, password)
      attributes = { shared_link: { access: access } }
      attributes[:shared_link][:unshared_at] = unshared_at.to_datetime.rfc3339 unless unshared_at.nil?
      attributes[:shared_link][:password] = password unless password.nil?
      attributes[:shared_link][:permissions] = {} unless can_download.nil? && can_preview.nil?
      attributes[:shared_link][:permissions][:can_download] = can_download unless can_download.nil?
      attributes[:shared_link][:permissions][:can_preview] = can_preview unless can_preview.nil?

      updated_item, response = put(uri, attributes)
      updated_item
    end

    def disable_shared_link(uri)
      attributes = { shared_link: nil }

      updated_item, response = put(uri, attributes)
      updated_item
    end
  end
end

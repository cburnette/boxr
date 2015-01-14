module Boxr
  
  class Client

    attr_reader :access_token, :refresh_token, :box_client_id, :box_client_secret, :identifier, :as_user_id, 

    API_URI = "https://api.box.com/2.0"
    UPLOAD_URI = "https://upload.box.com/api/2.0"
    FILES_URI = "#{API_URI}/files"
    FILES_UPLOAD_URI = "#{UPLOAD_URI}/files/content"
    FOLDERS_URI = "#{API_URI}/folders"
    USERS_URI = "#{API_URI}/users"
    GROUPS_URI = "#{API_URI}/groups"
    GROUP_MEMBERSHIPS_URI = "#{API_URI}/group_memberships"
    COLLABORATIONS_URI = "#{API_URI}/collaborations"
    COMMENTS_URI = "#{API_URI}/comments"
    SEARCH_URI = "#{API_URI}/search"
    TASKS_URI = "#{API_URI}/tasks"
    TASK_ASSIGNMENTS_URI = "#{API_URI}/task_assignments"
    SHARED_ITEMS_URI = "#{API_URI}/shared_items"
    METADATA_URI = "#{API_URI}/files"
    EVENTS_URI = "#{API_URI}/events"

    DEFAULT_LIMIT = 100
    FOLDER_ITEMS_LIMIT = 1000

    FOLDER_AND_FILE_FIELDS = [:type,:id,:sequence_id,:etag,:name,:created_at,:modified_at,:description,
                              :size,:path_collection,:created_by,:modified_by,:trashed_at,:purged_at,
                              :content_created_at,:content_modified_at,:owned_by,:shared_link,:folder_upload_email,
                              :parent,:item_status,:item_collection,:sync_state,:has_collaborations,:permissions,:tags,
                              :sha1,:shared_link,:version_number,:comment_count,:lock,:extension,:is_package,:can_non_owners_invite]
    FOLDER_AND_FILE_FIELDS_QUERY = FOLDER_AND_FILE_FIELDS.join(',')

    COMMENT_FIELDS = [:type,:id,:is_reply_comment,:message,:tagged_message,:created_by,:created_at,:item,:modified_at]
    COMMENT_FIELDS_QUERY = COMMENT_FIELDS.join(',')
    
    TASK_FIELDS = [:type,:id,:item,:due_at,:action,:message,:task_assignment_collection,:is_completed,:created_by,:created_at]
    TASK_FIELDS_QUERY = TASK_FIELDS.join(',')

    COLLABORATION_FIELDS = [:type,:id,:created_by,:created_at,:modified_at,:expires_at,:status,:accessible_by,:role,:acknowledged_at,:item]
    COLLABORATION_FIELDS_QUERY = COLLABORATION_FIELDS.join(',')

    USER_FIELDS = [:type,:id,:name,:login,:created_at,:modified_at,:role,:language,:timezone,:space_amount,:space_used,
                   :max_upload_size,:tracking_codes,:can_see_managed_users,:is_sync_enabled,:is_external_collab_restricted,
                   :status,:job_title,:phone,:address,:avatar_uri,:is_exempt_from_device_limits,:is_exempt_from_login_verification,
                   :enterprise,:my_tags]
    USER_FIELDS_QUERY = USER_FIELDS.join(',')

    GROUP_FIELDS = [:type, :id, :name, :created_at, :modified_at]
    GROUP_FIELDS_QUERY = GROUP_FIELDS.join(',')

    #Read this to see why the httpclient gem was chosen: http://bibwild.wordpress.com/2012/04/30/ruby-http-performance-shootout-redux/
    #All instances of Boxr::Client will use this one class instance of HTTPClient; that way persistent HTTPS connections work.
    #Plus, httpclient is thread-safe so we can use the same class instance with multiple instances of Boxr::Client
    BOX_CLIENT = HTTPClient.new
    BOX_CLIENT.send_timeout = 3600 #one hour; needed for lengthy uploads
    BOX_CLIENT.transparent_gzip_decompression = true 

    def self.turn_on_debugging(device=STDOUT)
      BOX_CLIENT.debug_dev = device
      BOX_CLIENT.transparent_gzip_decompression = false
    end

    def self.turn_off_debugging
      BOX_CLIENT.debug_dev = nil
      BOX_CLIENT.transparent_gzip_decompression = true
    end

    def initialize(access_token, refresh_token: nil, box_client_id: ENV['BOX_CLIENT_ID'], box_client_secret: ENV['BOX_CLIENT_SECRET'], 
                    identifier: nil, as_user_id: nil, &token_refresh_listener)
      @access_token = access_token
      @refresh_token = refresh_token
      @box_client_id = box_client_id
      @box_client_secret = box_client_secret
      @identifier = identifier
      @as_user_id = as_user_id
      @token_refresh_listener = token_refresh_listener
    end


    private

    def get(uri, query: nil, success_codes: [200], process_response: true, if_match: nil, box_api_header: nil)
      res = with_auto_token_refresh do
        headers = standard_headers()
        headers['If-Match'] = if_match unless if_match.nil?
        headers['BoxApi'] = box_api_header unless box_api_header.nil?

        BOX_CLIENT.get(uri, query: query, header: headers)
      end

      check_response_status(res, success_codes)

      if process_response
        return processed_response res
      else
        return res.body, res
      end
    end

    def get_with_pagination(uri, query: {}, limit: DEFAULT_LIMIT)
      entries = []
      offset = 0

      begin
        query[:limit] = limit
        query[:offset] = offset
        res = with_auto_token_refresh do
          headers = standard_headers()
          BOX_CLIENT.get(uri, query: query, header: headers)
        end
        
        if (res.status==200)
          body_json = Oj.load(res.body)
          total_count = body_json["total_count"]
          offset = offset + limit

          entries << body_json["entries"]
        else
          raise BoxrException.new(status: res.status, body: res.body, header: res.header)
        end
      end until offset - total_count >= 0

      entries.flatten.map{|i| Hashie::Mash.new(i)}
    end

    def post(uri, body, query: nil, success_codes: [201], process_body: true, content_md5: nil, content_type: nil, if_match: nil)
      body = Oj.dump(body) if process_body

      res = with_auto_token_refresh do
        headers = standard_headers()
        headers['If-Match'] = if_match unless if_match.nil?
        headers["Content-MD5"] = content_md5 unless content_md5.nil?
        headers["Content-Type"] = content_type unless content_type.nil?

        BOX_CLIENT.post(uri, body: body, query: query, header: headers)
      end

      check_response_status(res, success_codes)

      processed_response res
    end

    def put(uri, body, query: nil, success_codes: [200], content_type: nil, if_match: nil)
      res = with_auto_token_refresh do
        headers = standard_headers()
        headers['If-Match'] = if_match unless if_match.nil?
        headers["Content-Type"] = content_type unless content_type.nil?
        
        BOX_CLIENT.put(uri, body: Oj.dump(body), query: query, header: headers)
      end

      check_response_status(res, success_codes)

      processed_response res
    end

    def delete(uri, query: nil, success_codes: [204], if_match: nil)
      res = with_auto_token_refresh do
        headers = standard_headers()
        headers['If-Match'] = if_match unless if_match.nil?
        
        BOX_CLIENT.delete(uri, query: query, header: headers)
      end

      check_response_status(res, success_codes)

      processed_response res
    end

    def options(uri, body, success_codes: [200])
      res = with_auto_token_refresh do
        headers = standard_headers()
        BOX_CLIENT.options(uri, body: Oj.dump(body), header: headers)
      end

      check_response_status(res, success_codes)

      processed_response res
    end

    def standard_headers()
      headers = {"Authorization" => "Bearer #{@access_token}"}
      headers['As-User'] = "#{@as_user_id}" unless @as_user_id.nil?
      headers
    end

    def with_auto_token_refresh
      return yield unless @refresh_token

      res = yield
      if res.status == 401
        auth_header = res.header['WWW-Authenticate'][0]
        if auth_header && auth_header.include?('invalid_token')
          new_tokens = Boxr::refresh_tokens(@refresh_token, box_client_id: box_client_id, box_client_secret: box_client_secret)
          @access_token = new_tokens.access_token
          @refresh_token = new_tokens.refresh_token
          @token_refresh_listener.call(@access_token, @refresh_token, @identifier) if @token_refresh_listener
          res = yield
        end
      end

      res
    end

    def check_response_status(res, success_codes)
      raise BoxrException.new(status: res.status, body: res.body, header: res.header) unless success_codes.include?(res.status)
    end

    def processed_response(res)
      body_json = Oj.load(res.body)
      return Hashie::Mash.new(body_json), res
    end

    def build_fields_query(fields, all_fields_query)
      if fields == :all
        {:fields => all_fields_query}
      elsif fields.is_a?(Array) && fields.length > 0
        {:fields => fields.join(',')}
      else
        {}
      end
    end

    def restore_trashed_item(uri, name, parent_id)
      attributes = {}
      attributes[:name] = name unless name.nil?
      attributes[:parent] = {id: parent_id} unless parent_id.nil?
      
      restored_item, response = post uri, attributes
      restored_item
    end

    def create_shared_link(uri, item_id, access, unshared_at, can_download, can_preview)
      if access.nil?
        attributes = {shared_link: {}}
      else
        attributes = {shared_link: {access: access}}
        attributes[:shared_link][:unshared_at] = unshared_at.to_datetime.rfc3339 unless unshared_at.nil?
        attributes[:shared_link][:permissions] = {} unless can_download.nil? && can_preview.nil?
        attributes[:shared_link][:permissions][:can_download] = can_download unless can_download.nil?
        attributes[:shared_link][:permissions][:can_preview] = can_preview unless can_preview.nil?
      end

      updated_item, response = put uri, attributes
      updated_item
    end

    def disable_shared_link(uri, item_id)
      attributes = {shared_link: nil}

      updated_item, response = put uri, attributes
      updated_item
    end

  end

end
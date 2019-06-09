module Boxr

  JWT_GRANT_TYPE="urn:ietf:params:oauth:grant-type:jwt-bearer"
  TOKEN_EXCHANGE_TOKEN_TYPE="urn:ietf:params:oauth:token-type:access_token"
  TOKEN_EXCHANGE_GRANT_TYPE="urn:ietf:params:oauth:grant-type:token-exchange"

  def self.oauth_url(state, host: "app.box.com", response_type: "code", scope: nil, folder_id: nil, client_id: ENV['BOX_CLIENT_ID'])
    template = Addressable::Template.new("https://{host}/api/oauth2/authorize{?query*}")

    query = {"response_type" => "#{response_type}", "state" => "#{state}", "client_id" => "#{client_id}"}
    query["scope"] = "#{scope}" unless scope.nil?
    query["folder_id"] = "#{folder_id}" unless folder_id.nil?

    uri = template.expand({"host" => "#{host}", "query" => query})
    uri
  end

  def self.get_tokens(code=nil, grant_type: "authorization_code", assertion: nil, scope: nil, username: nil, client_id: ENV['BOX_CLIENT_ID'], client_secret: ENV['BOX_CLIENT_SECRET'])
    uri = "https://api.box.com/oauth2/token"
    body = "grant_type=#{grant_type}&client_id=#{client_id}&client_secret=#{client_secret}"
    body = body + "&code=#{code}" unless code.nil?
    body = body + "&scope=#{scope}" unless scope.nil?
    body = body + "&username=#{username}" unless username.nil?
    body = body + "&assertion=#{assertion}" unless assertion.nil?

    auth_post(uri, body)
  end

  def self.get_enterprise_token(private_key: ENV['JWT_PRIVATE_KEY'], private_key_password: ENV['JWT_PRIVATE_KEY_PASSWORD'],
                                public_key_id: ENV['JWT_PUBLIC_KEY_ID'], enterprise_id: ENV['BOX_ENTERPRISE_ID'],
                                client_id: ENV['BOX_CLIENT_ID'], client_secret: ENV['BOX_CLIENT_SECRET'])
    unlocked_private_key = unlock_key(private_key, private_key_password)
    assertion = jwt_assertion(unlocked_private_key, client_id, enterprise_id, "enterprise", public_key_id)
    get_token(grant_type: JWT_GRANT_TYPE, assertion: assertion, client_id: client_id, client_secret: client_secret)
  end

  def self.get_user_token(user_id, private_key: ENV['JWT_PRIVATE_KEY'], private_key_password: ENV['JWT_PRIVATE_KEY_PASSWORD'],
                          public_key_id: ENV['JWT_PUBLIC_KEY_ID'], client_id: ENV['BOX_CLIENT_ID'], client_secret: ENV['BOX_CLIENT_SECRET'])
    unlocked_private_key = unlock_key(private_key, private_key_password)
    assertion = jwt_assertion(unlocked_private_key, client_id, user_id, "user", public_key_id)
    get_token(grant_type: JWT_GRANT_TYPE, assertion: assertion, client_id: client_id, client_secret: client_secret)
  end

  def self.refresh_tokens(refresh_token, client_id: ENV['BOX_CLIENT_ID'], client_secret: ENV['BOX_CLIENT_SECRET'])
    uri = "https://api.box.com/oauth2/token"
    body = "grant_type=refresh_token&refresh_token=#{refresh_token}&client_id=#{client_id}&client_secret=#{client_secret}"

    auth_post(uri, body)
  end

  def self.revoke_tokens(token, client_id: ENV['BOX_CLIENT_ID'], client_secret: ENV['BOX_CLIENT_SECRET'])
    uri = "https://api.box.com/oauth2/revoke"
    body = "client_id=#{client_id}&client_secret=#{client_secret}&token=#{token}"

    auth_post(uri, body)
  end

  # Exchange a fully-scoped token for one that is down-scoped to specific permissions,
  # defined by the scopes passed in.  You can optionally restrict the token to a
  # particular file.
  #
  # @param [String] subject_token The fully-scoped token to exchange
  #
  # @param [Array<String>] scopes A list of the scopes to allow in the new token
  #
  # @param [Integer, String] file (Optional) The ID of a file resource to restrict
  #   the token to
  # @return [BoxrMash]
  def self.exchange_token(subject_token, scopes:, file: nil)
    resource_url = ( file.present? ) ? "#{Boxr::Client::FILES_URI}/#{file}" : nil
    uri = "https://api.box.com/oauth2/token"

    params = {
      subject_token: subject_token,
      subject_token_type: TOKEN_EXCHANGE_TOKEN_TYPE,
      scope: scopes.join(' '),
      grant_type: TOKEN_EXCHANGE_GRANT_TYPE
    }

    params[:resource] = resource_url unless resource_url.nil?

    auth_post(uri, params.to_query)
  end

  class << self
    alias :get_token :get_tokens
    alias :refresh_token :refresh_tokens
    alias :revoke_token :revoke_tokens
  end

  private


  def self.jwt_assertion(private_key, iss, sub, box_sub_type, public_key_id)
    payload = {
      iss: iss,
      sub: sub,
      box_sub_type: box_sub_type,
      aud: "https://api.box.com/oauth2/token",
      jti: SecureRandom.hex(64),
      exp: (Time.now.utc + 10).to_i
    }

    additional_headers = {}
    additional_headers['kid'] = public_key_id unless public_key_id.nil?

    JWT.encode(payload, private_key, "RS256", additional_headers)
  end

  def self.auth_post(uri, body)
    uri = Addressable::URI.encode(uri)

    res = BOX_CLIENT.post(uri, body: body)

    if(res.status==200)
      body_json = JSON.load(res.body)
      return BoxrMash.new(body_json)
    else
      raise BoxrError.new(status: res.status, body: res.body, header: res.header)
    end
  end

  def self.unlock_key(private_key, private_key_password)
    if private_key.is_a?(OpenSSL::PKey::RSA)
      private_key
    else
      OpenSSL::PKey::RSA.new(private_key, private_key_password)
    end
  end

end

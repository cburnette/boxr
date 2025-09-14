# frozen_string_literal: true

module Boxr
  JWT_GRANT_TYPE = 'urn:ietf:params:oauth:grant-type:jwt-bearer'
  TOKEN_EXCHANGE_TOKEN_TYPE = 'urn:ietf:params:oauth:token-type:access_token'
  TOKEN_EXCHANGE_GRANT_TYPE = 'urn:ietf:params:oauth:grant-type:token-exchange'

  def self.oauth_url(state, host: 'app.box.com', response_type: 'code', scope: nil, folder_id: nil,
                     client_id: ENV['BOX_CLIENT_ID'])
    template = Addressable::Template.new('https://{host}/api/oauth2/authorize{?query*}')

    query = { 'response_type' => response_type.to_s, 'state' => state.to_s,
              'client_id' => client_id.to_s }
    query['scope'] = scope.to_s unless scope.nil?
    query['folder_id'] = folder_id.to_s unless folder_id.nil?

    template.expand({ 'host' => host.to_s, 'query' => query })
  end

  def self.get_tokens(code = nil, grant_type: 'authorization_code', assertion: nil, scope: nil,
                      username: nil, client_id: ENV['BOX_CLIENT_ID'], client_secret: ENV['BOX_CLIENT_SECRET'], box_subject_type: nil, box_subject_id: nil)
    uri = Boxr::Client::AUTH_URI
    body = "grant_type=#{grant_type}&client_id=#{client_id}&client_secret=#{client_secret}"
    body += "&code=#{code}" unless code.nil?
    body += "&scope=#{scope}" unless scope.nil?
    body += "&username=#{username}" unless username.nil?
    body += "&assertion=#{assertion}" unless assertion.nil?
    body += "&box_subject_type=#{box_subject_type}" unless box_subject_type.nil?
    body += "&box_subject_id=#{box_subject_id}" unless box_subject_id.nil?

    auth_post(uri, body)
  end

  def self.get_enterprise_token(private_key: ENV['JWT_PRIVATE_KEY'], private_key_password: ENV['JWT_PRIVATE_KEY_PASSWORD'],
                                public_key_id: ENV['JWT_PUBLIC_KEY_ID'], enterprise_id: ENV['BOX_ENTERPRISE_ID'],
                                client_id: ENV['BOX_CLIENT_ID'], client_secret: ENV['BOX_CLIENT_SECRET'])
    unlocked_private_key = unlock_key(private_key, private_key_password)
    assertion = jwt_assertion(unlocked_private_key, client_id, enterprise_id, 'enterprise',
                              public_key_id)
    get_token(grant_type: JWT_GRANT_TYPE, assertion: assertion, client_id: client_id,
              client_secret: client_secret)
  end

  def self.get_user_token(user_id, private_key: ENV['JWT_PRIVATE_KEY'], private_key_password: ENV['JWT_PRIVATE_KEY_PASSWORD'],
                          public_key_id: ENV['JWT_PUBLIC_KEY_ID'], client_id: ENV['BOX_CLIENT_ID'], client_secret: ENV['BOX_CLIENT_SECRET'])
    unlocked_private_key = unlock_key(private_key, private_key_password)
    assertion = jwt_assertion(unlocked_private_key, client_id, user_id, 'user', public_key_id)
    get_token(grant_type: JWT_GRANT_TYPE, assertion: assertion, client_id: client_id,
              client_secret: client_secret)
  end

  def self.refresh_tokens(refresh_token, client_id: ENV['BOX_CLIENT_ID'],
                          client_secret: ENV['BOX_CLIENT_SECRET'])
    uri = Boxr::Client::AUTH_URI
    body = "grant_type=refresh_token&refresh_token=#{refresh_token}&client_id=#{client_id}&client_secret=#{client_secret}"

    auth_post(uri, body)
  end

  def self.revoke_tokens(token, client_id: ENV['BOX_CLIENT_ID'],
                         client_secret: ENV['BOX_CLIENT_SECRET'])
    uri = Boxr::Client::REVOKE_AUTH_URI
    body = "client_id=#{client_id}&client_secret=#{client_secret}&token=#{token}"

    auth_post(uri, body)
  end

  # Exchange an existing token for a lesser-scoped token
  def self.exchange_token(subject_token, scope, resource_id: nil, resource_type: :file)
    uri = Boxr::Client::AUTH_URI
    resouce_uri = resource_type == :file ? Boxr::Client::FILES_URI : Boxr::Client::FOLDERS_URI
    resource_url = "#{resouce_uri}/#{resource_id}"

    body = "subject_token=#{subject_token}&subject_token_type=#{TOKEN_EXCHANGE_TOKEN_TYPE}&scope=#{scope}&grant_type=#{TOKEN_EXCHANGE_GRANT_TYPE}"
    body += "&resource=#{resource_url}" unless resource_id.nil?

    auth_post(uri, body)
  end

  class << self
    alias get_token get_tokens
    alias refresh_token refresh_tokens
    alias revoke_token revoke_tokens
  end

  def self.jwt_assertion(private_key, iss, sub, box_sub_type, public_key_id)
    payload = {
      iss: iss,
      sub: sub,
      box_sub_type: box_sub_type,
      aud: Boxr::Client::AUTH_URI,
      jti: SecureRandom.hex(64),
      exp: (Time.now.utc + 10).to_i
    }

    additional_headers = {}
    additional_headers['kid'] = public_key_id unless public_key_id.nil?

    JWT.encode(payload, private_key, 'RS256', additional_headers)
  end

  def self.auth_post(uri, body)
    uri = Addressable::URI.encode(uri)

    res = BOX_CLIENT.post(uri, body: body)

    unless res.status == 200
      raise BoxrError.new(status: res.status, body: res.body, header: res.header)
    end

    body_json = JSON.parse(res.body)
    BoxrMash.new(body_json)
  end

  def self.unlock_key(private_key, private_key_password)
    if private_key.is_a?(OpenSSL::PKey::RSA)
      private_key
    else
      OpenSSL::PKey::RSA.new(private_key, private_key_password)
    end
  end
end

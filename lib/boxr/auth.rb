module Boxr

  def self.oauth_url(state, host: "app.box.com", response_type: "code", scope: nil, folder_id: nil, box_client_id: ENV['BOX_CLIENT_ID'])
    template = Addressable::Template.new("https://{host}/api/oauth2/authorize{?query*}")

    query = {"response_type": "#{response_type}", "state": "#{state}", "client_id": "#{box_client_id}"}
    query["scope"] = "#{scope}" unless scope.nil?
    query["folder_id"] = "#{folder_id}" unless folder_id.nil?
    
    uri = template.expand({"host": "#{host}", "query": query})
    uri
  end

  def self.get_tokens(code, grant_type: "authorization_code", username: nil, box_client_id: ENV['BOX_CLIENT_ID'], box_client_secret: ENV['BOX_CLIENT_SECRET'])
    uri = "https://api.box.com/oauth2/token"
    body = "code=#{code}&grant_type=#{grant_type}&client_id=#{box_client_id}&client_secret=#{box_client_secret}"
    body = body + "&username=#{username}" unless username.nil?

    auth_post(uri, body)
  end

  def self.refresh_tokens(refresh_token, box_client_id: ENV['BOX_CLIENT_ID'], box_client_secret: ENV['BOX_CLIENT_SECRET'])
    uri = "https://api.box.com/oauth2/token"
    body = "grant_type=refresh_token&refresh_token=#{refresh_token}&client_id=#{box_client_id}&client_secret=#{box_client_secret}"

    auth_post(uri, body)
  end

  def self.revoke_tokens(token, box_client_id: ENV['BOX_CLIENT_ID'], box_client_secret: ENV['BOX_CLIENT_SECRET'])
    uri = "https://api.box.com/oauth2/revoke"
    body = "client_id=#{box_client_id}&client_secret=#{box_client_secret}&token=#{token}"

    auth_post(uri, body)
  end

  private

  def self.auth_post(uri, body)
    uri = Addressable::URI.encode(uri)

    res = BOX_CLIENT.post(uri, body: body)

    if(res.status==200)
      body_json = Oj.load(res.body)
      return Hashie::Mash.new(body_json)
    else
      raise BoxrError.new(status: res.status, body: res.body, header: res.header)
    end
  end

end
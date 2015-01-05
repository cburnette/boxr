module Boxr

	def self.oauth_url(state, response_type: "code", scope: nil, folder_id: nil)
		uri = "https://app.box.com/api/oauth2/authorize?response_type=#{response_type}&state=#{state}&client_id=#{ENV['BOX_CLIENT_ID']}"
		uri = uri + "&scope=#{scope}" unless scope.nil?
		uri = uri + "&folder_id=#{folder_id}" unless folder_id.nil?
		uri
	end

	def self.get_token(code, grant_type: "authorization_code", username: nil)
		uri = "https://api.box.com/oauth2/token"
		body = "code=#{code}&grant_type=#{grant_type}&client_id=#{ENV['BOX_CLIENT_ID']}&client_secret=#{ENV['BOX_CLIENT_SECRET']}"
		body = body + "&username=#{username}" unless username.nil?

		auth_post(uri, body)
	end

	def self.refresh_token(refresh_token)
		uri = "https://api.box.com/oauth2/token"
		body = "grant_type=refresh_token&refresh_token=#{refresh_token}&client_id=#{ENV['BOX_CLIENT_ID']}&client_secret=#{ENV['BOX_CLIENT_SECRET']}"

		auth_post(uri, body)
	end

	def self.revoke_token(token)
		uri = "https://api.box.com/oauth2/revoke"
		body = "client_id=#{ENV['BOX_CLIENT_ID']}&client_secret=#{ENV['BOX_CLIENT_SECRET']}&token=#{token}"

		auth_post(uri, body)
	end

	private

	def self.auth_post(uri, body)
		client = HTTPClient.new
		res = client.post(uri, body: body)

		if(res.status==200)
			body_json = Oj.load(res.body)
			return Hashie::Mash.new(body_json)
		else
			raise BoxrException.new(status: res.status, body: res.body, header: res.header)
		end
	end

end
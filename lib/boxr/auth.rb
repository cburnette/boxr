module Boxr

	def self.oauth_url(state, response_type: "code", scope: nil, folder_id: nil)
		uri = "https://app.box.com/api/oauth2/authorize?response_type=#{response_type}&state=#{state}&client_id=#{ENV['BOX_CLIENT_ID']}"
		uri = uri + "&scope=#{scope}" unless scope.nil?
		uri = uri + "&folder_id=#{folder_id}" unless folder_id.nil?
		uri
	end

	def self.get_tokens(code, grant_type: "authorization_code", username: nil)
		uri = "https://api.box.com/oauth2/token"
		body = "code=#{code}&grant_type=#{grant_type}&client_id=#{ENV['BOX_CLIENT_ID']}&client_secret=#{ENV['BOX_CLIENT_SECRET']}"
		body = body + "&username=#{username}" unless username.nil?

		client = HTTPClient.new
		res = client.post(uri, body: body)

		if(res.status==200)
			body_json = Oj.load(res.body)
			mash = Hashie::Mash.new(body_json)
			return mash
		else
			raise BoxrException.new(status: res.status, body: res.body, header: res.header)
		end
	end

end
module Boxr

	def self.oauth_url(state, response_type: "code", scope: nil, folder_id: nil)
		uri = "https://app.box.com/api/oauth2/authorize?response_type=#{response_type}&state=#{state}&client_id=#{ENV['BOX_CLIENT_ID']}"
		uri = uri + "&scope=#{scope}" unless scope.nil?
		uri = uri + "&folder_id=#{folder_id}" unless folder_id.nil?
		uri
	end

	def self.get_tokens(code, grant_type: "authorization_code", username: nil)
		uri = "https://api.box.com/oauth2/token?code=#{code}&grant_type=#{grant_type}&client_id=#{ENV['BOX_CLIENT_ID']}&client_secret=#{ENV['BOX_CLIENT_SECRET']}"
		uri = uri + "&username=#{username}" unless username.nil?

		client = HTTPClient.new
		client.debug_dev = STDOUT
		res = client.post(uri)
		puts res.status
		puts res.body 

	end

end
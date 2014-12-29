module Boxr

	def self.oauth_url(state, response_type: :code, redirect_uri: nil, scope: nil, folder_id: nil)
		url = "https://app.box.com/api/oauth2/authorize?response_type=#{response_type}&state=#{state}&client_id=#{ENV['BOX_CLIENT_ID']}"
		url = url + "&redirect_uri=#{redirect_uri}" unless redirect_uri.nil?
		url = url + "&scope=#{scope}" unless scope.nil?
		url = url + "&folder_id=#{folder_id}" unless folder_id.nil?
	end

end
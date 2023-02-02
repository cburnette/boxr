#rake spec SPEC_OPTS="-e \"invokes auth operations"\"
describe 'auth operations' do
  it "invokes auth operations" do
    private_key = OpenSSL::PKey::RSA.new(File.read(ENV['JWT_PRIVATE_KEY_PATH']), ENV['JWT_PRIVATE_KEY_PASSWORD'])

    puts "get enterprise token"
    enterprise_token = Boxr::get_enterprise_token(private_key: private_key)
    expect(enterprise_token).to include('access_token', 'expires_in')

    puts "downgrade token"
    child_token = Boxr::exchange_token(enterprise_token['access_token'], 'root_readonly')
    expect(child_token).to include('access_token','expires_in')

    # Currently cannot test due to user requiring
    puts "get user token"
    second_test_user = BOX_CLIENT.create_user("Second Test User", login: "second_test_user@#{('a'..'z').to_a.shuffle[0,10].join}.com", role: 'user', is_platform_access_only: true)
    user_token = Boxr::get_user_token(second_test_user.id, private_key: private_key)
    expect(user_token).to include('access_token','expires_in')

    puts "revoke user token"
    user_client = Boxr::Client.new(user_token['access_token'])
    expect(user_client.root_folder_items).to eq []
    Boxr::revoke_token(user_token['access_token'])
    expect{user_client.root_folder_items}.to raise_error{Boxr::BoxrError}

    puts 'get_tokens - client_credentials_grant'
    user_token = Boxr::get_token(code=nil,
                                 grant_type: 'client_credentials',
                                 box_subject_type: 'enterprise',
                                 box_subject_id: ENV['BOX_ENTERPRISE_ID'],
                                 client_id: ENV['BOX_OAUTH_CLIENT_ID'],
                                 client_secret: ENV['BOX_OAUTH_CLIENT_SECRET'])
    expect(user_token).to include('access_token','expires_in')

    puts "cleanup data"
    BOX_CLIENT.delete_user(second_test_user, force: true)
  end

end

describe 'additional_fields', :skip_reset do
	it "works with box_subject_type and box_subject_id" do
    allow(Boxr).to receive(:auth_post).and_wrap_original { | _m, *args | args }
		token_response = Boxr.get_tokens(code = nil,
																			grant_type: 'client_credentials',
																			box_subject_type: 'enterprise',
																			box_subject_id: '12345',
																			client_id: '123456789',
																			client_secret: '123456789')
    expect(token_response[1]).to include("grant_type=client_credentials")
    expect(token_response[1]).to include("client_id=123456789")
    expect(token_response[1]).to include("box_subject_id=12345")
	end
end

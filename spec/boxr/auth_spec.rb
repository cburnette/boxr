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

    puts "cleanup data"
    BOX_CLIENT.delete_user(second_test_user, force: true)
  end

  describe '.oauth_url' do
    subject do
      Boxr.oauth_url(
        state,
        host: host,
        response_type: response_type,
        scope: scope,
        folder_id: folder_id,
        client_id: client_id,
        redirect_uri: redirect_uri
      ).to_s
    end

    let(:state) { '123' }
    let(:host) { 'app.box.com' }
    let(:response_type) { 'code' }
    let(:scope) { 'name,email' }
    let(:folder_id) { 'somefolderid' }
    let(:client_id) { 'asdfasdfsadf' }
    let(:redirect_uri) { 'http://google.com' }

    it do
      is_expected.to eq(
        'https://app.box.com/api/oauth2/authorize?response_type=code&state=123&client_id=asdfasdfsadf&scope=name%2Cemail&folder_id=somefolderid&redirect_uri=http%3A%2F%2Fgoogle.com'
      )
    end
  end
end

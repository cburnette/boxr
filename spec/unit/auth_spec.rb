# frozen_string_literal: true

require 'spec_helper'

describe Boxr do
  let(:client_id) { 'test_client_id' }
  let(:client_secret) { 'test_client_secret' }
  let(:code) { 'test_auth_code' }
  let(:refresh_token) { 'test_refresh_token' }
  let(:access_token) { 'test_access_token' }
  let(:user_id) { 'test_user_id' }
  let(:enterprise_id) { 'test_enterprise_id' }
  let(:public_key_id) { 'test_public_key_id' }
  let(:private_key) { OpenSSL::PKey::RSA.new(2048) }
  let(:private_key_password) { 'test_password' }
  let(:scope) { 'root_readonly' }
  let(:resource_id) { 'test_resource_id' }
  let(:subject_token) { 'test_subject_token' }

  let(:mock_response) { instance_double(HTTP::Message, status: 200, header: {}, body: '{"access_token":"test_token","expires_in":3600}') }
  let(:mock_error_response) { instance_double(HTTP::Message, status: 400, header: {}, body: '{"error":"invalid_request"}') }

  before do
    allow(Boxr::BOX_CLIENT).to receive(:post).and_return(mock_response)
    allow(JSON).to receive(:load).and_return({ 'access_token' => 'test_token',
                                               'expires_in' => 3600 })
    allow(SecureRandom).to receive(:hex).and_return('test_jti')
    allow(Time).to receive(:now).and_return(Time.at(1_609_459_200))
  end

  describe '.oauth_url' do
    it 'generates oauth URL with required parameters' do
      result = described_class.oauth_url('test_state', client_id: client_id)

      expect(result.to_s).to include('https://app.box.com/api/oauth2/authorize')
      expect(result.to_s).to include('response_type=code')
      expect(result.to_s).to include('state=test_state')
      expect(result.to_s).to include("client_id=#{client_id}")
    end

    it 'includes optional scope parameter' do
      result = described_class.oauth_url('test_state', client_id: client_id, scope: scope)

      expect(result.to_s).to include("scope=#{scope}")
    end

    it 'includes optional folder_id parameter' do
      result = described_class.oauth_url('test_state', client_id: client_id, folder_id: '12345')

      expect(result.to_s).to include('folder_id=12345')
    end

    it 'uses custom host when provided' do
      result = described_class.oauth_url('test_state', client_id: client_id, host: 'custom.box.com')

      expect(result.to_s).to include('https://custom.box.com/api/oauth2/authorize')
    end

    it 'uses different response_type when provided' do
      result = described_class.oauth_url('test_state', client_id: client_id, response_type: 'token')

      expect(result.to_s).to include('response_type=token')
    end
  end

  describe '.get_tokens' do
    it 'gets tokens with authorization code' do
      result = described_class.get_tokens(code, client_id: client_id, client_secret: client_secret)

      expect(Boxr::BOX_CLIENT).to have_received(:post).with(
        Boxr::Client::AUTH_URI,
        body: "grant_type=authorization_code&client_id=#{client_id}&client_secret=#{client_secret}&code=#{code}"
      )
      expect(result).to be_a(BoxrMash)
    end

    it 'gets tokens with custom grant type' do
      described_class.get_tokens(nil, grant_type: 'client_credentials', client_id: client_id,
                                      client_secret: client_secret)

      expect(Boxr::BOX_CLIENT).to have_received(:post).with(
        Boxr::Client::AUTH_URI,
        body: "grant_type=client_credentials&client_id=#{client_id}&client_secret=#{client_secret}"
      )
    end

    it 'includes scope when provided' do
      described_class.get_tokens(code, scope: scope, client_id: client_id,
                                       client_secret: client_secret)

      expect(Boxr::BOX_CLIENT).to have_received(:post).with(
        Boxr::Client::AUTH_URI,
        body: "grant_type=authorization_code&client_id=#{client_id}&client_secret=#{client_secret}&code=#{code}&scope=#{scope}"
      )
    end

    it 'includes username when provided' do
      described_class.get_tokens(code, username: 'test_user', client_id: client_id,
                                       client_secret: client_secret)

      expect(Boxr::BOX_CLIENT).to have_received(:post).with(
        Boxr::Client::AUTH_URI,
        body: "grant_type=authorization_code&client_id=#{client_id}&client_secret=#{client_secret}&code=#{code}&username=test_user"
      )
    end

    it 'includes assertion when provided' do
      described_class.get_tokens(nil, assertion: 'test_assertion', client_id: client_id,
                                      client_secret: client_secret)

      expect(Boxr::BOX_CLIENT).to have_received(:post).with(
        Boxr::Client::AUTH_URI,
        body: "grant_type=authorization_code&client_id=#{client_id}&client_secret=#{client_secret}&assertion=test_assertion"
      )
    end

    it 'includes box_subject_type and box_subject_id when provided' do
      described_class.get_tokens(nil, box_subject_type: 'enterprise',
                                      box_subject_id: enterprise_id, client_id: client_id, client_secret: client_secret)

      expect(Boxr::BOX_CLIENT).to have_received(:post).with(
        Boxr::Client::AUTH_URI,
        body: "grant_type=authorization_code&client_id=#{client_id}&client_secret=#{client_secret}&box_subject_type=enterprise&box_subject_id=#{enterprise_id}"
      )
    end

    it 'raises BoxrError on failure' do
      allow(Boxr::BOX_CLIENT).to receive(:post).and_return(mock_error_response)

      expect do
        described_class.get_tokens(code, client_id: client_id, client_secret: client_secret)
      end
        .to raise_error(Boxr::BoxrError)
    end
  end

  describe '.get_enterprise_token' do
    before do
      allow(described_class).to receive_messages(unlock_key: private_key,
                                                 jwt_assertion: 'test_jwt_assertion', get_token: BoxrMash.new({ 'access_token' => 'test_token' }))
    end

    it 'gets enterprise token with JWT' do
      result = described_class.get_enterprise_token(
        private_key: private_key,
        private_key_password: private_key_password,
        public_key_id: public_key_id,
        enterprise_id: enterprise_id,
        client_id: client_id,
        client_secret: client_secret
      )

      expect(described_class).to have_received(:unlock_key).with(private_key, private_key_password)
      expect(described_class).to have_received(:jwt_assertion).with(
        private_key, client_id, enterprise_id, 'enterprise', public_key_id
      )
      expect(described_class).to have_received(:get_token).with(
        grant_type: Boxr::JWT_GRANT_TYPE,
        assertion: 'test_jwt_assertion',
        client_id: client_id,
        client_secret: client_secret
      )
      expect(result).to be_a(BoxrMash)
    end
  end

  describe '.get_user_token' do
    before do
      allow(described_class).to receive_messages(unlock_key: private_key,
                                                 jwt_assertion: 'test_jwt_assertion', get_token: BoxrMash.new({ 'access_token' => 'test_token' }))
    end

    it 'gets user token with JWT' do
      result = described_class.get_user_token(
        user_id,
        private_key: private_key,
        private_key_password: private_key_password,
        public_key_id: public_key_id,
        client_id: client_id,
        client_secret: client_secret
      )

      expect(described_class).to have_received(:unlock_key).with(private_key, private_key_password)
      expect(described_class).to have_received(:jwt_assertion).with(
        private_key, client_id, user_id, 'user', public_key_id
      )
      expect(described_class).to have_received(:get_token).with(
        grant_type: Boxr::JWT_GRANT_TYPE,
        assertion: 'test_jwt_assertion',
        client_id: client_id,
        client_secret: client_secret
      )
      expect(result).to be_a(BoxrMash)
    end
  end

  describe '.refresh_tokens' do
    it 'refreshes tokens' do
      result = described_class.refresh_tokens(refresh_token, client_id: client_id,
                                                             client_secret: client_secret)

      expect(Boxr::BOX_CLIENT).to have_received(:post).with(
        Boxr::Client::AUTH_URI,
        body: "grant_type=refresh_token&refresh_token=#{refresh_token}&client_id=#{client_id}&client_secret=#{client_secret}"
      )
      expect(result).to be_a(BoxrMash)
    end
  end

  describe '.revoke_tokens' do
    it 'revokes tokens' do
      result = described_class.revoke_tokens(access_token, client_id: client_id,
                                                           client_secret: client_secret)

      expect(Boxr::BOX_CLIENT).to have_received(:post).with(
        Boxr::Client::REVOKE_AUTH_URI,
        body: "client_id=#{client_id}&client_secret=#{client_secret}&token=#{access_token}"
      )
      expect(result).to be_a(BoxrMash)
    end
  end

  describe '.exchange_token' do
    it 'exchanges token for file resource' do
      result = described_class.exchange_token(subject_token, scope, resource_id: resource_id,
                                                                    resource_type: :file)

      expected_body = "subject_token=#{subject_token}&subject_token_type=#{Boxr::TOKEN_EXCHANGE_TOKEN_TYPE}&scope=#{scope}&grant_type=#{Boxr::TOKEN_EXCHANGE_GRANT_TYPE}&resource=#{Boxr::Client::FILES_URI}/#{resource_id}"
      expect(Boxr::BOX_CLIENT).to have_received(:post).with(
        Boxr::Client::AUTH_URI,
        body: expected_body
      )
      expect(result).to be_a(BoxrMash)
    end

    it 'exchanges token for folder resource' do
      result = described_class.exchange_token(subject_token, scope, resource_id: resource_id,
                                                                    resource_type: :folder)

      expected_body = "subject_token=#{subject_token}&subject_token_type=#{Boxr::TOKEN_EXCHANGE_TOKEN_TYPE}&scope=#{scope}&grant_type=#{Boxr::TOKEN_EXCHANGE_GRANT_TYPE}&resource=#{Boxr::Client::FOLDERS_URI}/#{resource_id}"
      expect(Boxr::BOX_CLIENT).to have_received(:post).with(
        Boxr::Client::AUTH_URI,
        body: expected_body
      )
      expect(result).to be_a(BoxrMash)
    end

    it 'exchanges token without resource' do
      result = described_class.exchange_token(subject_token, scope)

      expected_body = "subject_token=#{subject_token}&subject_token_type=#{Boxr::TOKEN_EXCHANGE_TOKEN_TYPE}&scope=#{scope}&grant_type=#{Boxr::TOKEN_EXCHANGE_GRANT_TYPE}"
      expect(Boxr::BOX_CLIENT).to have_received(:post).with(
        Boxr::Client::AUTH_URI,
        body: expected_body
      )
      expect(result).to be_a(BoxrMash)
    end
  end

  describe 'aliases' do
    it 'aliases get_token to get_tokens' do
      expect(described_class.method(:get_token)).to eq(described_class.method(:get_tokens))
    end

    it 'aliases refresh_token to refresh_tokens' do
      expect(described_class.method(:refresh_token)).to eq(described_class.method(:refresh_tokens))
    end

    it 'aliases revoke_token to revoke_tokens' do
      expect(described_class.method(:revoke_token)).to eq(described_class.method(:revoke_tokens))
    end
  end

  describe 'private methods' do
    describe '.jwt_assertion' do
      it 'creates JWT assertion with correct payload' do
        allow(JWT).to receive(:encode).and_return('test_jwt')

        result = described_class.send(:jwt_assertion, private_key, client_id, user_id, 'user',
                                      public_key_id)

        expect(JWT).to have_received(:encode).with(
          hash_including(
            iss: client_id,
            sub: user_id,
            box_sub_type: 'user',
            aud: Boxr::Client::AUTH_URI,
            jti: 'test_jti',
            exp: 1_609_459_210
          ),
          private_key,
          'RS256',
          { 'kid' => public_key_id }
        )
        expect(result).to eq('test_jwt')
      end

      it 'creates JWT assertion without public key id' do
        allow(JWT).to receive(:encode).and_return('test_jwt')

        result = described_class.send(:jwt_assertion, private_key, client_id, user_id, 'user', nil)

        expect(JWT).to have_received(:encode).with(
          anything,
          private_key,
          'RS256',
          {}
        )
        expect(result).to eq('test_jwt')
      end
    end

    describe '.unlock_key' do
      it 'returns key when already OpenSSL::PKey::RSA' do
        result = described_class.send(:unlock_key, private_key, private_key_password)
        expect(result).to eq(private_key)
      end

      it 'creates new RSA key from string' do
        key_string = private_key.to_pem
        allow(OpenSSL::PKey::RSA).to receive(:new).with(key_string,
                                                        private_key_password).and_return(private_key)

        result = described_class.send(:unlock_key, key_string, private_key_password)

        expect(OpenSSL::PKey::RSA).to have_received(:new).with(key_string, private_key_password)
        expect(result).to eq(private_key)
      end
    end

    describe '.auth_post' do
      it 'makes successful auth post request' do
        result = described_class.send(:auth_post, 'https://api.box.com/oauth2/token', 'test_body')

        expect(Boxr::BOX_CLIENT).to have_received(:post).with('https://api.box.com/oauth2/token',
                                                              body: 'test_body')
        expect(result).to be_a(BoxrMash)
      end

      it 'raises BoxrError on failure' do
        allow(Boxr::BOX_CLIENT).to receive(:post).and_return(mock_error_response)

        expect { described_class.send(:auth_post, 'https://api.box.com/oauth2/token', 'test_body') }
          .to raise_error(Boxr::BoxrError)
      end
    end
  end
end

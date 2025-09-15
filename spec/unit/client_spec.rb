# frozen_string_literal: true

require 'spec_helper'

describe Boxr::Client do
  let(:access_token) { 'test_access_token' }
  let(:refresh_token) { 'test_refresh_token' }
  let(:client_id) { 'test_client_id' }
  let(:client_secret) { 'test_client_secret' }
  let(:enterprise_id) { 'test_enterprise_id' }
  let(:jwt_private_key) { 'test_private_key' }
  let(:jwt_private_key_password) { 'test_password' }
  let(:jwt_public_key_id) { 'test_public_key_id' }
  let(:identifier) { 'test_identifier' }
  let(:as_user_id) { 'test_user_id' }
  let(:proxy) { 'http://proxy.example.com:8080' }

  let(:mock_response) { instance_double(HTTP::Message, status: 200, header: {}, body: '{"test": "data"}') }
  let(:mock_post_response) { instance_double(HTTP::Message, status: 201, header: {}, body: '{"test": "data"}') }
  let(:mock_delete_response) { instance_double(HTTP::Message, status: 204, header: {}, body: '') }
  let(:mock_error_response) { instance_double(HTTP::Message, status: 400, header: {}, body: '{"error": "bad_request"}') }
  let(:mock_401_response) { instance_double(HTTP::Message, status: 401, header: { 'WWW-Authenticate' => ['Bearer realm="Service", error="invalid_token"'] }) }

  before do
    allow(Boxr::BOX_CLIENT).to receive_messages(
      get: mock_response, post: mock_post_response, put: mock_response,
      delete: mock_delete_response, options: mock_response
    )
    allow(JSON).to receive(:parse).and_return({ 'test' => 'data' })
  end

  describe '#initialize' do
    context 'with minimal parameters' do
      it 'initializes with access token from environment' do
        allow(ENV).to receive(:[]).and_call_original
        allow(ENV).to receive(:[]).with('BOX_DEVELOPER_TOKEN').and_return(access_token)
        allow(ENV).to receive(:[]).with('BOX_CLIENT_ID').and_return(nil)
        allow(ENV).to receive(:[]).with('BOX_CLIENT_SECRET').and_return(nil)
        allow(ENV).to receive(:[]).with('BOX_ENTERPRISE_ID').and_return(nil)
        allow(ENV).to receive(:[]).with('JWT_PRIVATE_KEY').and_return(nil)
        allow(ENV).to receive(:[]).with('JWT_PRIVATE_KEY_PASSWORD').and_return(nil)
        allow(ENV).to receive(:[]).with('JWT_PUBLIC_KEY_ID').and_return(nil)
        client = described_class.new
        expect(client.access_token).to eq(access_token)
      end

      it 'raises error when access token is nil' do
        allow(ENV).to receive(:[]).and_call_original
        allow(ENV).to receive(:[]).with('BOX_DEVELOPER_TOKEN').and_return(nil)
        allow(ENV).to receive(:[]).with('BOX_CLIENT_ID').and_return(nil)
        allow(ENV).to receive(:[]).with('BOX_CLIENT_SECRET').and_return(nil)
        allow(ENV).to receive(:[]).with('BOX_ENTERPRISE_ID').and_return(nil)
        allow(ENV).to receive(:[]).with('JWT_PRIVATE_KEY').and_return(nil)
        allow(ENV).to receive(:[]).with('JWT_PRIVATE_KEY_PASSWORD').and_return(nil)
        allow(ENV).to receive(:[]).with('JWT_PUBLIC_KEY_ID').and_return(nil)
        expect { described_class.new }.to raise_error(Boxr::BoxrError, /Access token cannot be nil/)
      end
    end

    context 'with all parameters' do
      let(:client) do
        described_class.new(
          access_token,
          refresh_token: refresh_token,
          client_id: client_id,
          client_secret: client_secret,
          enterprise_id: enterprise_id,
          jwt_private_key: jwt_private_key,
          jwt_private_key_password: jwt_private_key_password,
          jwt_public_key_id: jwt_public_key_id,
          identifier: identifier,
          as_user: as_user_id,
          proxy: proxy
        )
      end

      it 'sets all attributes correctly' do
        expect(client.access_token).to eq(access_token)
        expect(client.refresh_token).to eq(refresh_token)
        expect(client.client_id).to eq(client_id)
        expect(client.client_secret).to eq(client_secret)
        expect(client.identifier).to eq(identifier)
        expect(client.as_user_id).to eq(as_user_id)
      end

      it 'sets proxy on BOX_CLIENT' do
        expect(Boxr::BOX_CLIENT).to receive(:proxy=).with(proxy)
        client
      end
    end

    context 'with as_user parameter' do
      it 'handles string user ID' do
        client = described_class.new(access_token, as_user: 'user123')
        expect(client.as_user_id).to eq('user123')
      end

      it 'handles user object with id method' do
        user_obj = double('User', id: 'user123')
        client = described_class.new(access_token, as_user: user_obj)
        expect(client.as_user_id).to eq('user123')
      end

      it 'handles integer user ID' do
        client = described_class.new(access_token, as_user: 123)
        expect(client.as_user_id).to eq(123)
      end

      it 'raises error for invalid user ID' do
        expect do
          described_class.new(access_token, as_user: Object.new)
        end.to raise_error(Boxr::BoxrError, /Expecting an id of class String or Fixnum/)
      end
    end
  end

  describe 'HTTP methods' do
    let(:client) { described_class.new(access_token) }

    describe '#get' do
      it 'makes GET request with standard headers' do
        client.send(:get, 'https://api.box.com/test')
        expect(Boxr::BOX_CLIENT).to have_received(:get).with(
          'https://api.box.com/test',
          query: nil,
          header: { 'Authorization' => "Bearer #{access_token}" },
          follow_redirect: true
        )
      end

      it 'includes query parameters' do
        client.send(:get, 'https://api.box.com/test', query: { param: 'value' })
        expect(Boxr::BOX_CLIENT).to have_received(:get).with(
          'https://api.box.com/test',
          query: { param: 'value' },
          header: { 'Authorization' => "Bearer #{access_token}" },
          follow_redirect: true
        )
      end

      it 'includes If-Match header when provided' do
        client.send(:get, 'https://api.box.com/test', if_match: 'etag123')
        expect(Boxr::BOX_CLIENT).to have_received(:get).with(
          'https://api.box.com/test',
          query: nil,
          header: { 'Authorization' => "Bearer #{access_token}", 'If-Match' => 'etag123' },
          follow_redirect: true
        )
      end

      it 'includes BoxApi header when provided' do
        client.send(:get, 'https://api.box.com/test', box_api_header: 'shared_link=abc123')
        expect(Boxr::BOX_CLIENT).to have_received(:get).with(
          'https://api.box.com/test',
          query: nil,
          header: { 'Authorization' => "Bearer #{access_token}", 'BoxApi' => 'shared_link=abc123' },
          follow_redirect: true
        )
      end

      it 'processes response by default' do
        result = client.send(:get, 'https://api.box.com/test')
        expect(result).to be_a(Array)
        expect(result[0]).to be_a(BoxrMash)
      end

      it 'returns raw response when process_response is false' do
        result = client.send(:get, 'https://api.box.com/test', process_response: false)
        expect(result).to eq(['{"test": "data"}', mock_response])
      end

      it 'raises error on non-success status' do
        allow(Boxr::BOX_CLIENT).to receive(:get).and_return(mock_error_response)
        expect do
          client.send(:get, 'https://api.box.com/test')
        end.to raise_error(Boxr::BoxrError)
      end
    end

    describe '#post' do
      it 'makes POST request with JSON body' do
        client.send(:post, 'https://api.box.com/test', { key: 'value' })
        expect(Boxr::BOX_CLIENT).to have_received(:post).with(
          'https://api.box.com/test',
          body: '{"key":"value"}',
          query: nil,
          header: { 'Authorization' => "Bearer #{access_token}" }
        )
      end

      it 'includes custom headers' do
        client.send(:post, 'https://api.box.com/test', { key: 'value' },
                    if_match: 'etag123', content_md5: 'md5hash', content_type: 'application/json')
        expect(Boxr::BOX_CLIENT).to have_received(:post).with(
          'https://api.box.com/test',
          body: '{"key":"value"}',
          query: nil,
          header: {
            'Authorization' => "Bearer #{access_token}",
            'If-Match' => 'etag123',
            'Content-MD5' => 'md5hash',
            'Content-Type' => 'application/json'
          }
        )
      end

      it 'skips JSON processing when process_body is false' do
        client.send(:post, 'https://api.box.com/test', 'raw body', process_body: false)
        expect(Boxr::BOX_CLIENT).to have_received(:post).with(
          'https://api.box.com/test',
          body: 'raw body',
          query: nil,
          header: { 'Authorization' => "Bearer #{access_token}" }
        )
      end
    end

    describe '#put' do
      it 'makes PUT request with JSON body' do
        client.send(:put, 'https://api.box.com/test', { key: 'value' })
        expect(Boxr::BOX_CLIENT).to have_received(:put).with(
          'https://api.box.com/test',
          body: '{"key":"value"}',
          query: nil,
          header: { 'Authorization' => "Bearer #{access_token}" }
        )
      end

      it 'includes custom headers' do
        client.send(:put, 'https://api.box.com/test', { key: 'value' },
                    content_type: 'application/json', content_range: 'bytes 0-1023/2048')
        expect(Boxr::BOX_CLIENT).to have_received(:put).with(
          'https://api.box.com/test',
          body: '{"key":"value"}',
          query: nil,
          header: {
            'Authorization' => "Bearer #{access_token}",
            'Content-Type' => 'application/json',
            'Content-Range' => 'bytes 0-1023/2048'
          }
        )
      end
    end

    describe '#delete' do
      it 'makes DELETE request' do
        client.send(:delete, 'https://api.box.com/test')
        expect(Boxr::BOX_CLIENT).to have_received(:delete).with(
          'https://api.box.com/test',
          query: nil,
          header: { 'Authorization' => "Bearer #{access_token}" }
        )
      end

      it 'includes If-Match header when provided' do
        client.send(:delete, 'https://api.box.com/test', if_match: 'etag123')
        expect(Boxr::BOX_CLIENT).to have_received(:delete).with(
          'https://api.box.com/test',
          query: nil,
          header: { 'Authorization' => "Bearer #{access_token}", 'If-Match' => 'etag123' }
        )
      end
    end

    describe '#options' do
      it 'makes OPTIONS request with JSON body' do
        client.send(:options, 'https://api.box.com/test', { key: 'value' })
        expect(Boxr::BOX_CLIENT).to have_received(:options).with(
          'https://api.box.com/test',
          body: '{"key":"value"}',
          header: { 'Authorization' => "Bearer #{access_token}" }
        )
      end
    end
  end

  describe '#get_all_with_pagination' do
    let(:client) { described_class.new(access_token) }
    let(:mock_paginated_response) do
      instance_double(HTTP::Message, status: 200,
                                     body: '{"entries": [{"id": "1"}], "total_count": 1}')
    end

    before do
      allow(Boxr::BOX_CLIENT).to receive(:get).and_return(mock_paginated_response)
      allow(JSON).to receive(:parse).and_return({ 'entries' => [{ 'id' => '1' }],
                                                  'total_count' => 1 })
    end

    it 'retrieves all pages of data' do
      result = client.send(:get_all_with_pagination, 'https://api.box.com/test')
      expect(result).to be_a(BoxrCollection)
      expect(result.size).to eq(1)
    end

    it 'uses custom offset and limit' do
      client.send(:get_all_with_pagination, 'https://api.box.com/test', offset: 10, limit: 50)
      expect(Boxr::BOX_CLIENT).to have_received(:get).with(
        'https://api.box.com/test',
        query: { limit: 50, offset: 10 },
        header: { 'Authorization' => "Bearer #{access_token}" },
        follow_redirect: true
      )
    end

    it 'raises error on non-200 status' do
      allow(Boxr::BOX_CLIENT).to receive(:get).and_return(mock_error_response)
      expect do
        client.send(:get_all_with_pagination, 'https://api.box.com/test')
      end.to raise_error(Boxr::BoxrError)
    end
  end

  describe '#standard_headers' do
    let(:client) { described_class.new(access_token) }

    it 'includes Authorization header' do
      headers = client.send(:standard_headers)
      expect(headers).to eq({ 'Authorization' => "Bearer #{access_token}" })
    end

    context 'with as_user_id and no JWT' do
      let(:client) { described_class.new(access_token, as_user: as_user_id) }

      it 'includes As-User header' do
        headers = client.send(:standard_headers)
        expect(headers).to eq({
                                'Authorization' => "Bearer #{access_token}",
                                'As-User' => as_user_id.to_s
                              })
      end
    end

    context 'with JWT private key' do
      let(:client) do
        described_class.new(access_token, jwt_private_key: jwt_private_key, as_user: as_user_id)
      end

      it 'does not include As-User header' do
        headers = client.send(:standard_headers)
        expect(headers).to eq({ 'Authorization' => "Bearer #{access_token}" })
      end
    end
  end

  describe '#with_auto_token_refresh' do
    let(:client) { described_class.new(access_token, refresh_token: refresh_token) }

    context 'without refresh token or JWT' do
      let(:client) { described_class.new(access_token) }

      it 'yields without token refresh' do
        expect { |b| client.send(:with_auto_token_refresh, &b) }.to yield_control
      end
    end

    context 'with refresh token' do
      let(:client) do
        described_class.new(access_token, refresh_token: refresh_token, client_id: nil,
                                          client_secret: nil)
      end

      before do
        allow(Boxr).to receive(:refresh_tokens).and_return(
          BoxrMash.new(access_token: 'new_token', refresh_token: 'new_refresh_token')
        )
      end

      it 'refreshes token on 401 with invalid_token' do
        allow(Boxr::BOX_CLIENT).to receive(:get).and_return(mock_401_response, mock_response)
        client.send(:with_auto_token_refresh) { Boxr::BOX_CLIENT.get('test') }
        expect(Boxr).to have_received(:refresh_tokens).with(refresh_token, client_id: nil,
                                                                           client_secret: nil)
        expect(client.access_token).to eq('new_token')
        expect(client.refresh_token).to eq('new_refresh_token')
      end

      it 'calls token refresh listener' do
        listener_calls = []
        listener = proc { |access_token, refresh_token, identifier|
          listener_calls << [access_token, refresh_token, identifier]
        }
        client = described_class.new(access_token,
                                     refresh_token: refresh_token, identifier: identifier, &listener)
        allow(Boxr::BOX_CLIENT).to receive(:get).and_return(mock_401_response, mock_response)
        allow(Boxr).to receive(:refresh_tokens).and_return(
          BoxrMash.new(access_token: 'new_token', refresh_token: 'new_refresh_token')
        )

        client.send(:with_auto_token_refresh) { Boxr::BOX_CLIENT.get('test') }
        expect(listener_calls).to eq([['new_token', 'new_refresh_token', identifier]])
      end
    end

    context 'with JWT private key' do
      let(:client) do
        described_class.new(
          access_token,
          jwt_private_key: jwt_private_key,
          jwt_private_key_password: jwt_private_key_password,
          jwt_public_key_id: jwt_public_key_id,
          client_id: client_id,
          client_secret: client_secret,
          enterprise_id: enterprise_id,
          as_user: as_user_id
        )
      end

      before do
        allow(Boxr).to receive_messages(get_user_token: BoxrMash.new(access_token: 'new_token'),
                                        get_enterprise_token: BoxrMash.new(access_token: 'new_token'))
      end

      it 'refreshes user token on 401 with as_user_id' do
        allow(Boxr::BOX_CLIENT).to receive(:get).and_return(mock_401_response, mock_response)
        client.send(:with_auto_token_refresh) { Boxr::BOX_CLIENT.get('test') }
        expect(Boxr).to have_received(:get_user_token).with(
          as_user_id,
          private_key: jwt_private_key,
          private_key_password: jwt_private_key_password,
          public_key_id: jwt_public_key_id,
          client_id: client_id,
          client_secret: client_secret
        )
        expect(client.access_token).to eq('new_token')
      end

      it 'refreshes enterprise token on 401 without as_user_id' do
        client = described_class.new(
          access_token,
          jwt_private_key: jwt_private_key,
          jwt_private_key_password: jwt_private_key_password,
          jwt_public_key_id: jwt_public_key_id,
          client_id: client_id,
          client_secret: client_secret,
          enterprise_id: enterprise_id
        )
        allow(Boxr::BOX_CLIENT).to receive(:get).and_return(mock_401_response, mock_response)
        client.send(:with_auto_token_refresh) { Boxr::BOX_CLIENT.get('test') }
        expect(Boxr).to have_received(:get_enterprise_token).with(
          private_key: jwt_private_key,
          private_key_password: jwt_private_key_password,
          public_key_id: jwt_public_key_id,
          enterprise_id: enterprise_id,
          client_id: client_id,
          client_secret: client_secret
        )
        expect(client.access_token).to eq('new_token')
      end
    end
  end

  describe '#check_response_status' do
    let(:client) { described_class.new(access_token) }

    it 'does not raise error for success status' do
      expect { client.send(:check_response_status, mock_response, [200]) }.not_to raise_error
    end

    it 'raises BoxrError for error status' do
      expect do
        client.send(:check_response_status, mock_error_response, [200])
      end.to raise_error(Boxr::BoxrError)
    end
  end

  describe '#processed_response' do
    let(:client) { described_class.new(access_token) }

    it 'returns BoxrMash and response' do
      result = client.send(:processed_response, mock_response)
      expect(result).to be_a(Array)
      expect(result[0]).to be_a(BoxrMash)
      expect(result[1]).to eq(mock_response)
    end
  end

  describe '#build_fields_query' do
    let(:client) { described_class.new(access_token) }

    it 'returns all fields when :all' do
      result = client.send(:build_fields_query, :all, 'field1,field2')
      expect(result).to eq({ fields: 'field1,field2' })
    end

    it 'returns joined fields for array' do
      result = client.send(:build_fields_query, %i[field1 field2], 'field1,field2')
      expect(result).to eq({ fields: 'field1,field2' })
    end

    it 'returns empty hash for empty array' do
      result = client.send(:build_fields_query, [], 'field1,field2')
      expect(result).to eq({})
    end

    it 'returns empty hash for nil' do
      result = client.send(:build_fields_query, nil, 'field1,field2')
      expect(result).to eq({})
    end
  end

  describe '#to_comma_separated_string' do
    let(:client) { described_class.new(access_token) }

    it 'returns string as-is' do
      result = client.send(:to_comma_separated_string, 'test')
      expect(result).to eq('test')
    end

    it 'returns symbol as-is' do
      result = client.send(:to_comma_separated_string, :test)
      expect(result).to eq(:test)
    end

    it 'joins array elements' do
      result = client.send(:to_comma_separated_string, %w[item1 item2])
      expect(result).to eq('item1,item2')
    end

    it 'returns nil for empty array' do
      result = client.send(:to_comma_separated_string, [])
      expect(result).to be_nil
    end

    it 'returns nil for non-array' do
      result = client.send(:to_comma_separated_string, 123)
      expect(result).to be_nil
    end
  end

  describe '#build_range_string' do
    let(:client) { described_class.new(access_token) }

    it 'builds range string from two values' do
      result = client.send(:build_range_string, 0, 100)
      expect(result).to eq('0,100')
    end

    it 'returns nil for empty range' do
      result = client.send(:build_range_string, nil, nil)
      expect(result).to be_nil
    end
  end

  describe '#ensure_id' do
    let(:client) { described_class.new(access_token) }

    it 'returns string as-is' do
      result = client.send(:ensure_id, '123')
      expect(result).to eq('123')
    end

    it 'returns integer as-is' do
      result = client.send(:ensure_id, 123)
      expect(result).to eq(123)
    end

    it 'returns nil as-is' do
      result = client.send(:ensure_id, nil)
      expect(result).to be_nil
    end

    it 'extracts id from object with id method' do
      obj = double('Object', id: '123')
      result = client.send(:ensure_id, obj)
      expect(result).to eq('123')
    end

    it 'raises error for invalid object' do
      expect do
        client.send(:ensure_id, Object.new)
      end.to raise_error(Boxr::BoxrError, /Expecting an id of class String or Fixnum/)
    end
  end

  describe '#restore_trashed_item' do
    let(:client) { described_class.new(access_token) }
    let(:mock_restored_item) { BoxrMash.new(id: '123', name: 'restored') }

    before do
      allow(client).to receive(:post).and_return([mock_restored_item, mock_response])
    end

    it 'restores item with name and parent' do
      result = client.send(:restore_trashed_item, 'https://api.box.com/test', 'new_name',
                           'parent123')
      expect(result).to eq(mock_restored_item)
      expect(client).to have_received(:post).with(
        'https://api.box.com/test',
        { name: 'new_name', parent: { id: 'parent123' } }
      )
    end

    it 'restores item without name' do
      result = client.send(:restore_trashed_item, 'https://api.box.com/test', nil, 'parent123')
      expect(result).to eq(mock_restored_item)
      expect(client).to have_received(:post).with(
        'https://api.box.com/test',
        { parent: { id: 'parent123' } }
      )
    end

    it 'restores item without parent' do
      result = client.send(:restore_trashed_item, 'https://api.box.com/test', 'new_name', nil)
      expect(result).to eq(mock_restored_item)
      expect(client).to have_received(:post).with(
        'https://api.box.com/test',
        { name: 'new_name' }
      )
    end
  end

  describe '#create_shared_link' do
    let(:client) { described_class.new(access_token) }
    let(:mock_updated_item) { BoxrMash.new(id: '123', shared_link: { access: 'open' }) }

    before do
      allow(client).to receive(:put).and_return([mock_updated_item, mock_response])
    end

    it 'creates shared link with access only' do
      result = client.send(:create_shared_link, 'https://api.box.com/test', 'item123', 'open', nil,
                           nil, nil, nil)
      expect(result).to eq(mock_updated_item)
      expect(client).to have_received(:put).with(
        'https://api.box.com/test',
        { shared_link: { access: 'open' } }
      )
    end

    it 'creates shared link with all parameters' do
      unshared_at = Time.now + 3600
      result = client.send(:create_shared_link, 'https://api.box.com/test', 'item123', 'open',
                           unshared_at, true, false, 'password123')
      expect(result).to eq(mock_updated_item)
      expect(client).to have_received(:put).with(
        'https://api.box.com/test',
        {
          shared_link: {
            access: 'open',
            unshared_at: unshared_at.to_datetime.rfc3339,
            password: 'password123',
            permissions: {
              can_download: true,
              can_preview: false
            }
          }
        }
      )
    end
  end

  describe '#disable_shared_link' do
    let(:client) { described_class.new(access_token) }
    let(:mock_updated_item) { BoxrMash.new(id: '123', shared_link: nil) }

    before do
      allow(client).to receive(:put).and_return([mock_updated_item, mock_response])
    end

    it 'disables shared link' do
      result = client.send(:disable_shared_link, 'https://api.box.com/test')
      expect(result).to eq(mock_updated_item)
      expect(client).to have_received(:put).with(
        'https://api.box.com/test',
        { shared_link: nil }
      )
    end
  end

  describe 'constants' do
    it 'defines API URIs' do
      expect(Boxr::Client::API_URI).to eq('https://api.box.com/2.0')
      expect(Boxr::Client::AUTH_URI).to eq('https://api.box.com/oauth2/token')
      expect(Boxr::Client::UPLOAD_URI).to eq('https://upload.box.com/api/2.0')
    end

    it 'defines field constants' do
      expect(Boxr::Client::FOLDER_AND_FILE_FIELDS).to be_a(Array)
      expect(Boxr::Client::COMMENT_FIELDS).to be_a(Array)
      expect(Boxr::Client::TASK_FIELDS).to be_a(Array)
      expect(Boxr::Client::COLLABORATION_FIELDS).to be_a(Array)
      expect(Boxr::Client::USER_FIELDS).to be_a(Array)
      expect(Boxr::Client::GROUP_FIELDS).to be_a(Array)
      expect(Boxr::Client::WEB_LINK_FIELDS).to be_a(Array)
    end

    it 'defines query field constants' do
      expect(Boxr::Client::FOLDER_AND_FILE_FIELDS_QUERY).to be_a(String)
      expect(Boxr::Client::COMMENT_FIELDS_QUERY).to be_a(String)
      expect(Boxr::Client::TASK_FIELDS_QUERY).to be_a(String)
      expect(Boxr::Client::COLLABORATION_FIELDS_QUERY).to be_a(String)
      expect(Boxr::Client::USER_FIELDS_QUERY).to be_a(String)
      expect(Boxr::Client::GROUP_FIELDS_QUERY).to be_a(String)
      expect(Boxr::Client::WEB_LINK_FIELDS_QUERY).to be_a(String)
    end

    it 'defines limits' do
      expect(Boxr::Client::DEFAULT_LIMIT).to eq(100)
      expect(Boxr::Client::FOLDER_ITEMS_LIMIT).to eq(1000)
    end

    it 'defines valid collaboration roles' do
      expect(Boxr::Client::VALID_COLLABORATION_ROLES).to include('editor', 'viewer', 'co-owner')
    end
  end
end

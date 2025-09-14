# frozen_string_literal: true

require 'spec_helper'

describe Boxr::Client do
  let(:client) { described_class.new }
  let(:test_user) { Hashie::Mash.new(id: '12345', name: 'Test User', type: 'user') }
  let(:test_user_2) { Hashie::Mash.new(id: '67890', name: 'Test User 2', type: 'user') }
  let(:test_email_alias) { Hashie::Mash.new(id: 'alias123', email: 'alias@example.com') }
  let(:mock_response) { instance_double(HTTP::Message, status: 200, header: {}) }
  let(:mock_users_response) do
    BoxrMash.new(entries: [test_user, test_user_2], total_count: 2)
  end
  let(:mock_aliases_response) do
    BoxrMash.new(entries: [test_email_alias], total_count: 1)
  end

  describe '#current_user' do
    before do
      allow(client).to receive_messages(
        build_fields_query: {},
        get: [test_user, mock_response]
      )
    end

    it 'retrieves current user' do
      result = client.current_user
      expect(result).to eq(test_user)
      expect(client).to have_received(:build_fields_query).with([], Boxr::Client::USER_FIELDS_QUERY)
      expect(client).to have_received(:get).with(
        "#{Boxr::Client::USERS_URI}/me",
        query: {}
      )
    end

    it 'retrieves current user with custom fields' do
      fields = %i[id name]
      result = client.current_user(fields: fields)
      expect(result).to eq(test_user)
      expect(client).to have_received(:build_fields_query).with(fields, Boxr::Client::USER_FIELDS_QUERY)
    end

    it 'aliases to me' do
      result = client.me
      expect(result).to eq(test_user)
    end
  end

  describe '#user_from_id' do
    before do
      allow(client).to receive_messages(
        build_fields_query: {},
        get: [test_user, mock_response]
      )
    end

    it 'retrieves user by ID' do
      result = client.user_from_id('12345')
      expect(result).to eq(test_user)
      expect(client).to have_received(:build_fields_query).with([], Boxr::Client::USER_FIELDS_QUERY)
      expect(client).to have_received(:get).with(
        "#{Boxr::Client::USERS_URI}/12345",
        query: {}
      )
    end

    it 'retrieves user by ID with custom fields' do
      fields = %i[id name]
      result = client.user_from_id('12345', fields: fields)
      expect(result).to eq(test_user)
      expect(client).to have_received(:build_fields_query).with(fields, Boxr::Client::USER_FIELDS_QUERY)
    end

    it 'handles user object' do
      result = client.user_from_id(test_user)
      expect(result).to eq(test_user)
    end

    it 'aliases to user' do
      result = client.user('12345')
      expect(result).to eq(test_user)
    end
  end

  describe '#all_users' do
    before do
      allow(client).to receive_messages(
        build_fields_query: {},
        get_all_with_pagination: mock_users_response,
        get: [mock_users_response, mock_response]
      )
    end

    it 'retrieves all users with default parameters' do
      result = client.all_users
      expect(result).to eq(mock_users_response)
      expect(client).to have_received(:build_fields_query).with([], Boxr::Client::USER_FIELDS_QUERY)
      expect(client).to have_received(:get_all_with_pagination).with(
        Boxr::Client::USERS_URI,
        query: {},
        offset: 0,
        limit: Boxr::Client::DEFAULT_LIMIT
      )
    end

    it 'retrieves all users with custom fields' do
      fields = %i[id name]
      result = client.all_users(fields: fields)
      expect(result).to eq(mock_users_response)
      expect(client).to have_received(:build_fields_query).with(fields, Boxr::Client::USER_FIELDS_QUERY)
    end

    it 'retrieves all users with filter term' do
      result = client.all_users(filter_term: 'test')
      expect(result).to eq(mock_users_response)
      expect(client).to have_received(:get_all_with_pagination).with(
        Boxr::Client::USERS_URI,
        query: { filter_term: 'test' },
        offset: 0,
        limit: Boxr::Client::DEFAULT_LIMIT
      )
    end

    it 'retrieves users with custom offset and limit' do
      result = client.all_users(offset: 10, limit: 50)
      expect(result).to eq([test_user, test_user_2])
      expect(client).to have_received(:get).with(
        Boxr::Client::USERS_URI,
        query: { offset: 10, limit: 50 }
      )
    end
  end

  describe '#create_user' do
    before do
      allow(client).to receive(:post).and_return([test_user, mock_response])
    end

    it 'creates user with name only' do
      result = client.create_user('New User')
      expect(result).to eq(test_user)
      expect(client).to have_received(:post).with(
        Boxr::Client::USERS_URI,
        { name: 'New User' }
      )
    end

    it 'creates user with login' do
      result = client.create_user('New User', login: 'user@example.com')
      expect(result).to eq(test_user)
      expect(client).to have_received(:post).with(
        Boxr::Client::USERS_URI,
        { name: 'New User', login: 'user@example.com' }
      )
    end

    it 'creates user with role' do
      result = client.create_user('New User', role: 'admin')
      expect(result).to eq(test_user)
      expect(client).to have_received(:post).with(
        Boxr::Client::USERS_URI,
        { name: 'New User', role: 'admin' }
      )
    end

    it 'creates user with all optional parameters' do
      result = client.create_user(
        'New User',
        login: 'user@example.com',
        role: 'user',
        language: 'en',
        is_sync_enabled: true,
        job_title: 'Developer',
        phone: '123-456-7890',
        address: '123 Main St',
        space_amount: 1_073_741_824,
        tracking_codes: [{ name: 'department', value: 'engineering' }],
        can_see_managed_users: true,
        is_external_collab_restricted: false,
        status: 'active',
        timezone: 'America/New_York',
        is_exempt_from_device_limits: false,
        is_exempt_from_login_verification: false,
        is_platform_access_only: false
      )
      expect(result).to eq(test_user)
      expect(client).to have_received(:post).with(
        Boxr::Client::USERS_URI,
        {
          name: 'New User',
          login: 'user@example.com',
          role: 'user',
          language: 'en',
          is_sync_enabled: true,
          job_title: 'Developer',
          phone: '123-456-7890',
          address: '123 Main St',
          space_amount: 1_073_741_824,
          tracking_codes: [{ name: 'department', value: 'engineering' }],
          can_see_managed_users: true,
          is_external_collab_restricted: false,
          status: 'active',
          timezone: 'America/New_York',
          is_exempt_from_device_limits: false,
          is_exempt_from_login_verification: false,
          is_platform_access_only: false
        }
      )
    end

    it 'creates platform user without login' do
      result = client.create_user('Platform User', is_platform_access_only: true)
      expect(result).to eq(test_user)
      expect(client).to have_received(:post).with(
        Boxr::Client::USERS_URI,
        { name: 'Platform User', is_platform_access_only: true }
      )
    end
  end

  describe '#update_user' do
    before do
      allow(client).to receive(:put).and_return([test_user, mock_response])
    end

    it 'updates user with name' do
      result = client.update_user('12345', name: 'Updated User')
      expect(result).to eq(test_user)
      expect(client).to have_received(:put).with(
        "#{Boxr::Client::USERS_URI}/12345",
        { name: 'Updated User' },
        query: {}
      )
    end

    it 'updates user with notify parameter' do
      result = client.update_user('12345', name: 'Updated User', notify: true)
      expect(result).to eq(test_user)
      expect(client).to have_received(:put).with(
        "#{Boxr::Client::USERS_URI}/12345",
        { name: 'Updated User' },
        query: { notify: true }
      )
    end

    it 'updates user with enterprise parameter' do
      result = client.update_user('12345', name: 'Updated User', enterprise: false)
      expect(result).to eq(test_user)
      expect(client).to have_received(:put).with(
        "#{Boxr::Client::USERS_URI}/12345",
        { name: 'Updated User' },
        query: {}
      )
    end

    it 'handles user object' do
      result = client.update_user(test_user, name: 'Updated User')
      expect(result).to eq(test_user)
    end

    it 'updates user with all optional parameters' do
      result = client.update_user(
        '12345',
        name: 'Updated User',
        role: 'admin',
        language: 'en',
        is_sync_enabled: false,
        job_title: 'Senior Developer',
        phone: '987-654-3210',
        address: '456 Oak Ave',
        space_amount: 2_147_483_648,
        tracking_codes: [{ name: 'team', value: 'backend' }],
        can_see_managed_users: false,
        status: 'inactive',
        timezone: 'America/Los_Angeles',
        is_exempt_from_device_limits: true,
        is_exempt_from_login_verification: true,
        is_exempt_from_reset_required: true,
        is_external_collab_restricted: true
      )
      expect(result).to eq(test_user)
      expect(client).to have_received(:put).with(
        "#{Boxr::Client::USERS_URI}/12345",
        {
          name: 'Updated User',
          role: 'admin',
          language: 'en',
          is_sync_enabled: false,
          job_title: 'Senior Developer',
          phone: '987-654-3210',
          address: '456 Oak Ave',
          space_amount: 2_147_483_648,
          tracking_codes: [{ name: 'team', value: 'backend' }],
          can_see_managed_users: false,
          status: 'inactive',
          timezone: 'America/Los_Angeles',
          is_exempt_from_device_limits: true,
          is_exempt_from_login_verification: true,
          is_exempt_from_reset_required: true,
          is_external_collab_restricted: true
        },
        query: {}
      )
    end

    it 'handles enterprise nil to roll out of enterprise' do
      result = client.update_user('12345', enterprise: nil)
      expect(result).to eq(test_user)
      expect(client).to have_received(:put).with(
        "#{Boxr::Client::USERS_URI}/12345",
        { enterprise: nil },
        query: {}
      )
    end
  end

  describe '#delete_user' do
    before do
      allow(client).to receive(:delete).and_return([true, mock_response])
    end

    it 'deletes user by ID' do
      result = client.delete_user('12345')
      expect(result).to be true
      expect(client).to have_received(:delete).with(
        "#{Boxr::Client::USERS_URI}/12345",
        query: {}
      )
    end

    it 'deletes user with notify parameter' do
      result = client.delete_user('12345', notify: true)
      expect(result).to be true
      expect(client).to have_received(:delete).with(
        "#{Boxr::Client::USERS_URI}/12345",
        query: { notify: true }
      )
    end

    it 'deletes user with force parameter' do
      result = client.delete_user('12345', force: true)
      expect(result).to be true
      expect(client).to have_received(:delete).with(
        "#{Boxr::Client::USERS_URI}/12345",
        query: { force: true }
      )
    end

    it 'deletes user with both notify and force parameters' do
      result = client.delete_user('12345', notify: false, force: true)
      expect(result).to be true
      expect(client).to have_received(:delete).with(
        "#{Boxr::Client::USERS_URI}/12345",
        query: { notify: false, force: true }
      )
    end

    it 'handles user object' do
      result = client.delete_user(test_user)
      expect(result).to be true
    end
  end

  describe '#move_users_folder' do
    before do
      allow(client).to receive(:put).and_return([test_user, mock_response])
    end

    it 'moves user folder with default source folder' do
      result = client.move_users_folder('12345', 0, '67890')
      expect(result).to eq(test_user)
      expect(client).to have_received(:put).with(
        "#{Boxr::Client::USERS_URI}/12345/folders/0",
        { owned_by: { id: '67890' } }
      )
    end

    it 'moves user folder with custom source folder' do
      result = client.move_users_folder('12345', 'folder123', '67890')
      expect(result).to eq(test_user)
      expect(client).to have_received(:put).with(
        "#{Boxr::Client::USERS_URI}/12345/folders/folder123",
        { owned_by: { id: '67890' } }
      )
    end

    it 'handles user objects' do
      result = client.move_users_folder(test_user, 0, test_user_2)
      expect(result).to eq(test_user)
    end
  end

  describe '#email_aliases_for_user' do
    before do
      allow(client).to receive(:get).and_return([mock_aliases_response, mock_response])
    end

    it 'retrieves email aliases for user by ID' do
      result = client.email_aliases_for_user('12345')
      expect(result).to eq([test_email_alias])
      expect(client).to have_received(:get).with("#{Boxr::Client::USERS_URI}/12345/email_aliases")
    end

    it 'handles user object' do
      result = client.email_aliases_for_user(test_user)
      expect(result).to eq([test_email_alias])
    end
  end

  describe '#add_email_alias_for_user' do
    before do
      allow(client).to receive(:post).and_return([test_user, mock_response])
    end

    it 'adds email alias for user by ID' do
      result = client.add_email_alias_for_user('12345', 'alias@example.com')
      expect(result).to eq(test_user)
      expect(client).to have_received(:post).with(
        "#{Boxr::Client::USERS_URI}/12345/email_aliases",
        { email: 'alias@example.com' }
      )
    end

    it 'handles user object' do
      result = client.add_email_alias_for_user(test_user, 'alias@example.com')
      expect(result).to eq(test_user)
    end
  end

  describe '#remove_email_alias_for_user' do
    before do
      allow(client).to receive(:delete).and_return([true, mock_response])
    end

    it 'removes email alias for user by ID and alias ID' do
      result = client.remove_email_alias_for_user('12345', 'alias123')
      expect(result).to be true
      expect(client).to have_received(:delete).with("#{Boxr::Client::USERS_URI}/12345/email_aliases/alias123")
    end

    it 'handles user and alias objects' do
      result = client.remove_email_alias_for_user(test_user, test_email_alias)
      expect(result).to be true
    end
  end
end

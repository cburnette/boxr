require 'spec_helper'

describe Boxr::Client do
  let(:client) { described_class.new }
  let(:test_group) { Hashie::Mash.new(id: '12345', name: 'Test Group', type: 'group') }
  let(:test_user) { Hashie::Mash.new(id: '67890', name: 'Test User', type: 'user') }
  let(:test_membership) { Hashie::Mash.new(id: 'membership123', role: 'member', user: test_user, group: test_group) }
  let(:mock_response) { instance_double(HTTP::Message, status: 200, header: {}) }
  let(:mock_groups_response) do
    BoxrMash.new(entries: [test_group], total_count: 1)
  end
  let(:mock_memberships_response) do
    BoxrMash.new(entries: [test_membership], total_count: 1)
  end

  describe '#groups' do
    before do
      allow(client).to receive_messages(
        build_fields_query: {},
        get_all_with_pagination: mock_groups_response
      )
    end

    it 'retrieves groups with default parameters' do
      result = client.groups

      expect(result).to eq(mock_groups_response)
      expect(client).to have_received(:build_fields_query).with([], Boxr::Client::GROUP_FIELDS_QUERY)
      expect(client).to have_received(:get_all_with_pagination).with(
        Boxr::Client::GROUPS_URI,
        query: {},
        offset: 0,
        limit: Boxr::Client::DEFAULT_LIMIT
      )
    end

    it 'retrieves groups with custom fields' do
      fields = [:id, :name]
      result = client.groups(fields: fields)

      expect(result).to eq(mock_groups_response)
      expect(client).to have_received(:build_fields_query).with(fields, Boxr::Client::GROUP_FIELDS_QUERY)
    end

    it 'retrieves groups with custom offset and limit' do
      result = client.groups(offset: 10, limit: 50)

      expect(result).to eq(mock_groups_response)
      expect(client).to have_received(:get_all_with_pagination).with(
        Boxr::Client::GROUPS_URI,
        query: {},
        offset: 10,
        limit: 50
      )
    end
  end

  describe '#group_from_id' do
    before do
      allow(client).to receive_messages(
        build_fields_query: {},
        get: [test_group, mock_response]
      )
    end

    it 'retrieves group by ID' do
      result = client.group_from_id('12345')

      expect(result).to eq(test_group)
      expect(client).to have_received(:build_fields_query).with([], Boxr::Client::GROUP_FIELDS_QUERY)
      expect(client).to have_received(:get).with(
        "#{Boxr::Client::GROUPS_URI}/12345",
        query: {}
      )
    end

    it 'retrieves group by ID with custom fields' do
      fields = [:id, :name]
      result = client.group_from_id('12345', fields: fields)

      expect(result).to eq(test_group)
      expect(client).to have_received(:build_fields_query).with(fields, Boxr::Client::GROUP_FIELDS_QUERY)
    end

    it 'handles group object' do
      result = client.group_from_id(test_group)

      expect(result).to eq(test_group)
    end

    it 'aliases to group' do
      result = client.group('12345')

      expect(result).to eq(test_group)
    end
  end

  describe '#create_group' do
    before do
      allow(client).to receive(:post).and_return([test_group, mock_response])
    end

    it 'creates group with name' do
      result = client.create_group('New Group')

      expect(result).to eq(test_group)
      expect(client).to have_received(:post).with(
        Boxr::Client::GROUPS_URI,
        { name: 'New Group' }
      )
    end
  end

  describe '#update_group' do
    before do
      allow(client).to receive_messages(
        put: [test_group, mock_response]
      )
    end

    it 'updates group with new name' do
      result = client.update_group('12345', 'Updated Group')

      expect(result).to eq(test_group)
      expect(client).to have_received(:put).with(
        "#{Boxr::Client::GROUPS_URI}/12345",
        { name: 'Updated Group' }
      )
    end

    it 'handles group object' do
      result = client.update_group(test_group, 'Updated Group')

      expect(result).to eq(test_group)
    end

    it 'aliases to rename_group' do
      result = client.rename_group('12345', 'Renamed Group')

      expect(result).to eq(test_group)
    end
  end

  describe '#delete_group' do
    before do
      allow(client).to receive_messages(
        delete: [true, mock_response]
      )
    end

    it 'deletes group by ID' do
      result = client.delete_group('12345')

      expect(result).to be true
      expect(client).to have_received(:delete).with("#{Boxr::Client::GROUPS_URI}/12345")
    end

    it 'handles group object' do
      result = client.delete_group(test_group)

      expect(result).to be true
    end
  end

  describe '#group_memberships' do
    before do
      allow(client).to receive_messages(
        get_all_with_pagination: mock_memberships_response
      )
    end

    it 'retrieves group memberships with default parameters' do
      result = client.group_memberships('12345')

      expect(result).to eq(mock_memberships_response)
      expect(client).to have_received(:get_all_with_pagination).with(
        "#{Boxr::Client::GROUPS_URI}/12345/memberships",
        offset: 0,
        limit: Boxr::Client::DEFAULT_LIMIT
      )
    end

    it 'retrieves group memberships with custom offset and limit' do
      result = client.group_memberships('12345', offset: 10, limit: 50)

      expect(result).to eq(mock_memberships_response)
      expect(client).to have_received(:get_all_with_pagination).with(
        "#{Boxr::Client::GROUPS_URI}/12345/memberships",
        offset: 10,
        limit: 50
      )
    end

    it 'handles group object' do
      result = client.group_memberships(test_group)

      expect(result).to eq(mock_memberships_response)
    end
  end

  describe '#group_memberships_for_user' do
    before do
      allow(client).to receive_messages(
        get_all_with_pagination: mock_memberships_response
      )
    end

    it 'retrieves user memberships with default parameters' do
      result = client.group_memberships_for_user('67890')

      expect(result).to eq(mock_memberships_response)
      expect(client).to have_received(:get_all_with_pagination).with(
        "#{Boxr::Client::USERS_URI}/67890/memberships",
        offset: 0,
        limit: Boxr::Client::DEFAULT_LIMIT
      )
    end

    it 'retrieves user memberships with custom offset and limit' do
      result = client.group_memberships_for_user('67890', offset: 10, limit: 50)

      expect(result).to eq(mock_memberships_response)
      expect(client).to have_received(:get_all_with_pagination).with(
        "#{Boxr::Client::USERS_URI}/67890/memberships",
        offset: 10,
        limit: 50
      )
    end

    it 'handles user object' do
      result = client.group_memberships_for_user(test_user)

      expect(result).to eq(mock_memberships_response)
    end
  end

  describe '#group_memberships_for_me' do
    before do
      allow(client).to receive(:get_all_with_pagination).and_return(mock_memberships_response)
    end

    it 'retrieves current user memberships with default parameters' do
      result = client.group_memberships_for_me

      expect(result).to eq(mock_memberships_response)
      expect(client).to have_received(:get_all_with_pagination).with(
        "#{Boxr::Client::USERS_URI}/me/memberships",
        offset: 0,
        limit: Boxr::Client::DEFAULT_LIMIT
      )
    end

    it 'retrieves current user memberships with custom offset and limit' do
      result = client.group_memberships_for_me(offset: 10, limit: 50)

      expect(result).to eq(mock_memberships_response)
      expect(client).to have_received(:get_all_with_pagination).with(
        "#{Boxr::Client::USERS_URI}/me/memberships",
        offset: 10,
        limit: 50
      )
    end
  end

  describe '#group_membership_from_id' do
    before do
      allow(client).to receive_messages(
        get: [test_membership, mock_response]
      )
    end

    it 'retrieves membership by ID' do
      result = client.group_membership_from_id('membership123')

      expect(result).to eq(test_membership)
      expect(client).to have_received(:get).with("#{Boxr::Client::GROUP_MEMBERSHIPS_URI}/membership123")
    end

    it 'handles membership object' do
      result = client.group_membership_from_id(test_membership)

      expect(result).to eq(test_membership)
    end

    it 'aliases to group_membership' do
      result = client.group_membership('membership123')

      expect(result).to eq(test_membership)
    end
  end

  describe '#add_user_to_group' do
    before do
      allow(client).to receive_messages(
        post: [test_membership, mock_response]
      )
    end

    it 'adds user to group without role' do
      result = client.add_user_to_group('67890', '12345')

      expect(result).to eq(test_membership)
      expect(client).to have_received(:post).with(
        Boxr::Client::GROUP_MEMBERSHIPS_URI,
        { user: { id: '67890' }, group: { id: '12345' } }
      )
    end

    it 'adds user to group with role' do
      result = client.add_user_to_group('67890', '12345', role: 'admin')

      expect(result).to eq(test_membership)
      expect(client).to have_received(:post).with(
        Boxr::Client::GROUP_MEMBERSHIPS_URI,
        { user: { id: '67890' }, group: { id: '12345' }, role: 'admin' }
      )
    end

    it 'handles user and group objects' do
      result = client.add_user_to_group(test_user, test_group)

      expect(result).to eq(test_membership)
    end

    it 'handles nil role' do
      result = client.add_user_to_group('67890', '12345', role: nil)

      expect(result).to eq(test_membership)
      expect(client).to have_received(:post).with(
        Boxr::Client::GROUP_MEMBERSHIPS_URI,
        { user: { id: '67890' }, group: { id: '12345' } }
      )
    end
  end

  describe '#update_group_membership' do
    before do
      allow(client).to receive_messages(
        put: [test_membership, mock_response]
      )
    end

    it 'updates membership role' do
      result = client.update_group_membership('membership123', 'admin')

      expect(result).to eq(test_membership)
      expect(client).to have_received(:put).with(
        "#{Boxr::Client::GROUP_MEMBERSHIPS_URI}/membership123",
        { role: 'admin' }
      )
    end

    it 'handles membership object' do
      result = client.update_group_membership(test_membership, 'admin')

      expect(result).to eq(test_membership)
    end
  end

  describe '#delete_group_membership' do
    before do
      allow(client).to receive_messages(
        delete: [true, mock_response]
      )
    end

    it 'deletes membership by ID' do
      result = client.delete_group_membership('membership123')

      expect(result).to be true
      expect(client).to have_received(:delete).with("#{Boxr::Client::GROUP_MEMBERSHIPS_URI}/membership123")
    end

    it 'handles membership object' do
      result = client.delete_group_membership(test_membership)

      expect(result).to be true
    end
  end
end

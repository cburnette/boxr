# frozen_string_literal: true

require 'spec_helper'

describe Boxr::Client do
  let(:client) { described_class.new }
  let(:test_collection) { Hashie::Mash.new(id: '12345', name: 'Test Collection') }
  let(:test_file) { Hashie::Mash.new(id: '67890', name: 'test.txt', type: 'file') }
  let(:test_folder) { Hashie::Mash.new(id: '11111', name: 'test_folder', type: 'folder') }
  let(:mock_response) { instance_double(HTTP::Message, status: 200, header: {}) }
  let(:mock_collections_response) do
    BoxrMash.new(entries: [test_collection], total_count: 1)
  end
  let(:mock_collection_items_response) do
    BoxrMash.new(entries: [test_file, test_folder], total_count: 2)
  end

  describe '#collections' do
    before do
      allow(client).to receive(:get_all_with_pagination).and_return(mock_collections_response)
    end

    it 'retrieves all collections' do
      result = client.collections
      expect(result).to eq(mock_collections_response)
    end

    it 'calls get_all_with_pagination with correct parameters' do
      client.collections
      expect(client).to have_received(:get_all_with_pagination).with(
        Boxr::Client::COLLECTIONS_URI,
        offset: 0,
        limit: Boxr::Client::DEFAULT_LIMIT
      )
    end
  end

  describe '#collection_items' do
    before do
      allow(client).to receive_messages(
        build_fields_query: {},
        get_all_with_pagination: mock_collection_items_response
      )
    end

    it 'retrieves collection items with collection object' do
      result = client.collection_items(test_collection)
      expect(result).to eq(mock_collection_items_response)
    end

    it 'retrieves collection items with collection ID string' do
      result = client.collection_items('12345')
      expect(result).to eq(mock_collection_items_response)
    end

    it 'calls get_all_with_pagination with correct URI' do
      client.collection_items(test_collection)
      expect(client).to have_received(:get_all_with_pagination).with(
        "#{Boxr::Client::COLLECTIONS_URI}/12345/items",
        query: {},
        offset: 0,
        limit: Boxr::Client::DEFAULT_LIMIT
      )
    end

    it 'retrieves collection items with custom fields' do
      fields = %i[name size created_at]
      client.collection_items(test_collection, fields: fields)

      expect(client).to have_received(:build_fields_query).with(
        fields, Boxr::Client::FOLDER_AND_FILE_FIELDS_QUERY
      )
    end

    it 'retrieves collection items with empty fields array' do
      client.collection_items(test_collection, fields: [])

      expect(client).to have_received(:build_fields_query).with(
        [], Boxr::Client::FOLDER_AND_FILE_FIELDS_QUERY
      )
    end

    it 'handles collection with mixed item types' do
      allow(mock_collection_items_response).to receive(:entries).and_return([test_file,
                                                                             test_folder])

      result = client.collection_items(test_collection)
      expect(result.entries).to include(test_file, test_folder)
    end
  end

  describe '#collection_from_id' do
    before do
      allow(client).to receive_messages(
        build_fields_query: {},
        get: [test_collection, mock_response]
      )
    end

    it 'retrieves collection by ID' do
      result = client.collection_from_id('12345')
      expect(result).to eq(test_collection)
    end

    it 'retrieves collection with collection object' do
      result = client.collection_from_id(test_collection)
      expect(result).to eq(test_collection)
    end

    it 'calls get with correct URI' do
      client.collection_from_id('12345')
      expect(client).to have_received(:get).with(
        "#{Boxr::Client::COLLECTIONS_URI}/12345"
      )
    end
  end

  describe '#collection' do
    it 'is aliased to collection_from_id' do
      expect(client.method(:collection)).to eq(client.method(:collection_from_id))
    end
  end
end

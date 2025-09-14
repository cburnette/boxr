# frozen_string_literal: true

require 'spec_helper'

describe Boxr::Client do
  let(:client) { described_class.new }
  let(:mock_response) { instance_double(HTTP::Message, status: 200, header: {}) }
  let(:test_file) { Hashie::Mash.new(id: '67890', name: 'test.txt', type: 'file') }
  let(:test_folder) { Hashie::Mash.new(id: '12345', name: 'test_folder', type: 'folder') }
  let(:mock_search_results) do
    BoxrMash.new(
      entries: [test_file, test_folder],
      total_count: 2
    )
  end

  describe '#search' do
    before do
      allow(client).to receive(:get).and_return([mock_search_results, mock_response])
    end

    it 'performs basic search with query only' do
      result = client.search('test query')

      expect(result).to eq([test_file, test_folder])
      expect(client).to have_received(:get).with(
        Boxr::Client::SEARCH_URI,
        query: { query: 'test query', limit: 30, offset: 0 }
      )
    end

    it 'performs search with all parameters' do
      from_date = Date.new(2023, 1, 1)
      to_date = Date.new(2023, 12, 31)
      mdfilters = [{ templateKey: 'test', filters: [{ fieldKey: 'status', values: ['active'] }] }]

      result = client.search(
        'test query',
        scope: 'user_content',
        file_extensions: %w[pdf doc],
        created_at_range_from_date: from_date,
        created_at_range_to_date: to_date,
        updated_at_range_from_date: from_date,
        updated_at_range_to_date: to_date,
        size_range_lower_bound_bytes: 1024,
        size_range_upper_bound_bytes: 1_048_576,
        owner_user_ids: %w[user1 user2],
        ancestor_folder_ids: %w[folder1 folder2],
        content_types: %w[name description],
        trash_content: false,
        mdfilters: mdfilters,
        type: 'file',
        limit: 50,
        offset: 10
      )

      expect(result).to eq([test_file, test_folder])
      expect(client).to have_received(:get).with(
        Boxr::Client::SEARCH_URI,
        query: {
          query: 'test query',
          scope: 'user_content',
          file_extensions: 'pdf,doc',
          created_at_range: '2023-01-01T00:00:00+00:00,2023-12-31T00:00:00+00:00',
          updated_at_range: '2023-01-01T00:00:00+00:00,2023-12-31T00:00:00+00:00',
          size_range: '1024,1048576',
          owner_user_ids: 'user1,user2',
          ancestor_folder_ids: 'folder1,folder2',
          content_types: 'name,description',
          trash_content: false,
          mdfilters: JSON.dump(mdfilters),
          type: 'file',
          limit: 50,
          offset: 10
        }
      )
    end

    it 'handles search with no query' do
      result = client.search

      expect(result).to eq([test_file, test_folder])
      expect(client).to have_received(:get).with(
        Boxr::Client::SEARCH_URI,
        query: { limit: 30, offset: 0 }
      )
    end

    it 'handles search with nil query' do
      result = client.search(nil)

      expect(result).to eq([test_file, test_folder])
      expect(client).to have_received(:get).with(
        Boxr::Client::SEARCH_URI,
        query: { limit: 30, offset: 0 }
      )
    end

    it 'handles empty arrays for comma-separated fields' do
      result = client.search(
        'test',
        file_extensions: [],
        owner_user_ids: [],
        ancestor_folder_ids: [],
        content_types: []
      )

      expect(result).to eq([test_file, test_folder])
      expect(client).to have_received(:get).with(
        Boxr::Client::SEARCH_URI,
        query: { query: 'test', limit: 30, offset: 0 }
      )
    end

    it 'handles single item arrays for comma-separated fields' do
      result = client.search(
        'test',
        file_extensions: ['pdf'],
        owner_user_ids: ['user1'],
        ancestor_folder_ids: ['folder1'],
        content_types: ['name']
      )

      expect(result).to eq([test_file, test_folder])
      expect(client).to have_received(:get).with(
        Boxr::Client::SEARCH_URI,
        query: {
          query: 'test',
          file_extensions: 'pdf',
          owner_user_ids: 'user1',
          ancestor_folder_ids: 'folder1',
          content_types: 'name',
          limit: 30,
          offset: 0
        }
      )
    end

    it 'handles mdfilters as string' do
      mdfilters_string = '{"templateKey":"test","filters":[{"fieldKey":"status","values":["active"]}]}'
      result = client.search('test', mdfilters: mdfilters_string)

      expect(result).to eq([test_file, test_folder])
      expect(client).to have_received(:get).with(
        Boxr::Client::SEARCH_URI,
        query: {
          query: 'test',
          mdfilters: mdfilters_string,
          limit: 30,
          offset: 0
        }
      )
    end

    it 'handles mdfilters as single hash' do
      mdfilter = { templateKey: 'test', filters: [{ fieldKey: 'status', values: ['active'] }] }
      result = client.search('test', mdfilters: mdfilter)

      expect(result).to eq([test_file, test_folder])
      expect(client).to have_received(:get).with(
        Boxr::Client::SEARCH_URI,
        query: {
          query: 'test',
          mdfilters: JSON.dump([mdfilter]),
          limit: 30,
          offset: 0
        }
      )
    end

    it 'handles mdfilters as array' do
      mdfilters = [
        { templateKey: 'test1', filters: [{ fieldKey: 'status', values: ['active'] }] },
        { templateKey: 'test2', filters: [{ fieldKey: 'priority', values: ['high'] }] }
      ]
      result = client.search('test', mdfilters: mdfilters)

      expect(result).to eq([test_file, test_folder])
      expect(client).to have_received(:get).with(
        Boxr::Client::SEARCH_URI,
        query: {
          query: 'test',
          mdfilters: JSON.dump(mdfilters),
          limit: 30,
          offset: 0
        }
      )
    end

    it 'handles nil mdfilters' do
      result = client.search('test', mdfilters: nil)

      expect(result).to eq([test_file, test_folder])
      expect(client).to have_received(:get).with(
        Boxr::Client::SEARCH_URI,
        query: { query: 'test', limit: 30, offset: 0 }
      )
    end

    it 'handles date range with only from date' do
      from_date = Date.new(2023, 1, 1)
      result = client.search('test', created_at_range_from_date: from_date)

      expect(result).to eq([test_file, test_folder])
      expect(client).to have_received(:get).with(
        Boxr::Client::SEARCH_URI,
        query: {
          query: 'test',
          created_at_range: '2023-01-01T00:00:00+00:00,',
          limit: 30,
          offset: 0
        }
      )
    end

    it 'handles date range with only to date' do
      to_date = Date.new(2023, 12, 31)
      result = client.search('test', created_at_range_to_date: to_date)

      expect(result).to eq([test_file, test_folder])
      expect(client).to have_received(:get).with(
        Boxr::Client::SEARCH_URI,
        query: {
          query: 'test',
          created_at_range: ',2023-12-31T00:00:00+00:00',
          limit: 30,
          offset: 0
        }
      )
    end

    it 'handles size range with only lower bound' do
      result = client.search('test', size_range_lower_bound_bytes: 1024)

      expect(result).to eq([test_file, test_folder])
      expect(client).to have_received(:get).with(
        Boxr::Client::SEARCH_URI,
        query: {
          query: 'test',
          size_range: '1024,',
          limit: 30,
          offset: 0
        }
      )
    end

    it 'handles size range with only upper bound' do
      result = client.search('test', size_range_upper_bound_bytes: 1_048_576)

      expect(result).to eq([test_file, test_folder])
      expect(client).to have_received(:get).with(
        Boxr::Client::SEARCH_URI,
        query: {
          query: 'test',
          size_range: ',1048576',
          limit: 30,
          offset: 0
        }
      )
    end

    it 'handles nil date range parameters' do
      result = client.search('test', created_at_range_from_date: nil, created_at_range_to_date: nil)

      expect(result).to eq([test_file, test_folder])
      expect(client).to have_received(:get).with(
        Boxr::Client::SEARCH_URI,
        query: { query: 'test', limit: 30, offset: 0 }
      )
    end

    it 'handles nil size range parameters' do
      result = client.search('test', size_range_lower_bound_bytes: nil,
                                     size_range_upper_bound_bytes: nil)

      expect(result).to eq([test_file, test_folder])
      expect(client).to have_received(:get).with(
        Boxr::Client::SEARCH_URI,
        query: { query: 'test', limit: 30, offset: 0 }
      )
    end

    it 'handles custom limit and offset' do
      result = client.search('test', limit: 100, offset: 50)

      expect(result).to eq([test_file, test_folder])
      expect(client).to have_received(:get).with(
        Boxr::Client::SEARCH_URI,
        query: { query: 'test', limit: 100, offset: 50 }
      )
    end

    it 'handles nil limit and offset' do
      result = client.search('test', limit: nil, offset: nil)

      expect(result).to eq([test_file, test_folder])
      expect(client).to have_received(:get).with(
        Boxr::Client::SEARCH_URI,
        query: { query: 'test' }
      )
    end
  end

  describe 'private helper methods' do
    describe '#build_date_range_field' do
      it 'builds date range with both dates' do
        from_date = Date.new(2023, 1, 1)
        to_date = Date.new(2023, 12, 31)

        result = client.send(:build_date_range_field, from_date, to_date)

        expect(result).to eq('2023-01-01T00:00:00+00:00,2023-12-31T00:00:00+00:00')
      end

      it 'builds date range with only from date' do
        from_date = Date.new(2023, 1, 1)

        result = client.send(:build_date_range_field, from_date, nil)

        expect(result).to eq('2023-01-01T00:00:00+00:00,')
      end

      it 'builds date range with only to date' do
        to_date = Date.new(2023, 12, 31)

        result = client.send(:build_date_range_field, nil, to_date)

        expect(result).to eq(',2023-12-31T00:00:00+00:00')
      end

      it 'returns nil when both dates are nil' do
        result = client.send(:build_date_range_field, nil, nil)

        expect(result).to be_nil
      end

      it 'handles DateTime objects' do
        from_datetime = DateTime.new(2023, 1, 1, 12, 30, 45)
        to_datetime = DateTime.new(2023, 12, 31, 18, 15, 30)

        result = client.send(:build_date_range_field, from_datetime, to_datetime)

        expect(result).to eq('2023-01-01T12:30:45+00:00,2023-12-31T18:15:30+00:00')
      end
    end

    describe '#build_size_range_field' do
      it 'builds size range with both bounds' do
        result = client.send(:build_size_range_field, 1024, 1_048_576)

        expect(result).to eq('1024,1048576')
      end

      it 'builds size range with only lower bound' do
        result = client.send(:build_size_range_field, 1024, nil)

        expect(result).to eq('1024,')
      end

      it 'builds size range with only upper bound' do
        result = client.send(:build_size_range_field, nil, 1_048_576)

        expect(result).to eq(',1048576')
      end

      it 'returns nil when both bounds are nil' do
        result = client.send(:build_size_range_field, nil, nil)

        expect(result).to be_nil
      end

      it 'handles string numbers' do
        result = client.send(:build_size_range_field, '1024', '1048576')

        expect(result).to eq('1024,1048576')
      end

      it 'handles float numbers' do
        result = client.send(:build_size_range_field, 1024.5, 1_048_576.7)

        expect(result).to eq('1024,1048576')
      end
    end
  end
end

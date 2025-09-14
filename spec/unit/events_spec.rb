# frozen_string_literal: true

require 'spec_helper'

describe Boxr::Client do
  let(:client) { described_class.new('fake_token') }
  let(:mock_response) { instance_double(HTTP::Message, status: 200, header: {}, body: '') }
  let(:events_data) do
    BoxrMash.new(
      entries: [
        {
          event_id: '12345',
          event_type: 'ITEM_CREATE',
          created_at: '2023-01-01T00:00:00Z',
          source: { id: 'file123', type: 'file', name: 'test.txt' }
        }
      ],
      chunk_size: 1,
      next_stream_position: 12_346
    )
  end

  describe '#user_events' do
    before do
      allow(Boxr::BOX_CLIENT).to receive(:get).and_return(mock_response)
      allow(JSON).to receive(:parse).and_return(events_data)
    end

    it 'returns events as an array' do
      response = client.user_events(0)
      expect(response.events).to be_an(Array)
    end

    it 'returns correct number of events' do
      response = client.user_events(0)
      expect(response.events.length).to eq(1)
    end

    it 'returns correct event type' do
      response = client.user_events(0)
      expect(response.events.first.event_type).to eq('ITEM_CREATE')
    end

    it 'returns correct chunk size' do
      response = client.user_events(0)
      expect(response.chunk_size).to eq(1)
    end

    it 'returns correct next stream position' do
      response = client.user_events(0)
      expect(response.next_stream_position).to eq(12_346)
    end

    it 'fetches user events with custom parameters' do
      events_data = {
        entries: [],
        chunk_size: 0,
        next_stream_position: 100
      }

      allow(Boxr::BOX_CLIENT).to receive(:get).and_return(mock_response)
      allow(JSON).to receive(:parse).and_return(events_data)

      response = client.user_events(100, stream_type: :admin_logs, limit: 50)

      expect(response.events).to be_an(Array)
      expect(response.events.length).to eq(0)
    end
  end

  describe '#enterprise_events' do
    it 'fetches enterprise events with default parameters' do
      events_data = {
        entries: [
          {
            event_id: '67890',
            event_type: 'LOGIN',
            created_at: '2023-01-01T00:00:00Z',
            source: { id: 'user123', type: 'user', name: 'test@example.com' }
          }
        ],
        chunk_size: 1,
        next_stream_position: 67_891
      }

      # Mock get_enterprise_events to return a response with events, then empty
      first_response = double('response', events: events_data[:entries],
                                          next_stream_position: 67_891)
      empty_response = double('response', events: [], next_stream_position: 67_891)

      allow(client).to receive(:get_enterprise_events).and_return(first_response, empty_response)

      response = client.enterprise_events

      expect(response.events).to be_an(Array)
      expect(response.events.length).to eq(1)
      expect(response.events.first.event_type).to eq('LOGIN')
      expect(response.next_stream_position).to eq(67_891)
    end

    it 'fetches enterprise events with date filters' do
      created_after = Time.parse('2023-01-01T00:00:00Z')
      created_before = Time.parse('2023-01-02T00:00:00Z')

      empty_response = double('response', events: [], next_stream_position: 0)
      allow(client).to receive(:get_enterprise_events).and_return(empty_response)

      response = client.enterprise_events(
        created_after: created_after,
        created_before: created_before
      )

      expect(response.events).to be_an(Array)
    end

    it 'fetches enterprise events with event type filter' do
      events_data = [
        {
          event_id: '11111',
          event_type: 'ITEM_UPDATE',
          created_at: '2023-01-01T00:00:00Z',
          source: { id: 'file456', type: 'file', name: 'updated.txt' }
        }
      ]

      first_response = double('response', events: events_data, next_stream_position: 11_112)
      empty_response = double('response', events: [], next_stream_position: 11_112)
      allow(client).to receive(:get_enterprise_events).and_return(first_response, empty_response)

      response = client.enterprise_events(event_type: 'ITEM_UPDATE')

      expect(response.events).to be_an(Array)
      expect(response.events.length).to eq(1)
      expect(response.events.first.event_type).to eq('ITEM_UPDATE')
    end

    it 'handles pagination by fetching all events' do
      first_events_data = [
        { event_id: '1', event_type: 'LOGIN', created_at: '2023-01-01T00:00:00Z' }
      ]

      first_response = double('response', events: first_events_data, next_stream_position: 100)
      empty_response = double('response', events: [], next_stream_position: 100)
      allow(client).to receive(:get_enterprise_events).and_return(first_response, empty_response)

      response = client.enterprise_events

      expect(response.events).to be_an(Array)
      expect(response.events.length).to eq(1)
      expect(response.events.first.event_type).to eq('LOGIN')
    end
  end

  describe '#enterprise_events_stream' do
    let(:first_response) do
      BoxrMash.new(events: [{ event_id: '1', event_type: 'LOGIN' }],
                   next_stream_position: 100)
    end
    let(:second_response) do
      BoxrMash.new(events: [], next_stream_position: 100)
    end

    before do
      allow(client).to receive(:enterprise_events).and_return(first_response, second_response)
      allow(client).to receive(:sleep) # Mock sleep to prevent actual delay
    end

    it 'yields events in a stream with block' do
      events_received = []
      loops = 0

      client.enterprise_events_stream(0, limit: 500, refresh_period: 1) do |response|
        events_received.concat(response.events)
        loops += 1
        break if loops > 10
      end

      expect(events_received).to be_an(Array)
      expect(events_received.length).to eq(1)
      expect(events_received.first[:event_type]).to eq('LOGIN')
    end
  end

  describe '#get_enterprise_events (private method)' do
    before do
      allow(Boxr::BOX_CLIENT).to receive(:get).and_return(mock_response)
      allow(JSON).to receive(:parse).and_return(events_data)
    end

    it 'constructs query parameters correctly' do
      created_after = Time.parse('2023-01-01T00:00:00Z')
      created_before = Time.parse('2023-01-02T00:00:00Z')

      response = client.send(:get_enterprise_events, created_after, created_before, 50,
                             'ITEM_CREATE', 100)

      expect(response.events).to be_an(Array)
    end
  end
end

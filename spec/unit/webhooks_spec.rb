require 'spec_helper'

describe Boxr::Client do
  let(:client) { described_class.new }
  let(:webhook_id) { '12345' }
  let(:target_id) { '67890' }
  let(:target_type) { 'file' }
  let(:triggers) { %w[FILE.UPLOADED FILE.DOWNLOADED] }
  let(:address) { 'https://example.com/webhook' }
  let(:webhook_data) do
    BoxrMash.new(id: webhook_id, target: { id: target_id, type: target_type }, triggers: triggers,
                 address: address)
  end
  let(:webhooks_collection) { BoxrMash.new(entries: [webhook_data], total_count: 1) }
  let(:mock_response) { instance_double(HTTP::Message, status: 200, header: {}) }

  describe '#create_webhook' do
    before do
      allow(client).to receive(:post).and_return([webhook_data, mock_response])
    end

    it 'creates webhook with required parameters' do
      result = client.create_webhook(target_id, target_type, triggers, address)

      expected_attributes = {
        target: { id: target_id, type: target_type },
        triggers: triggers,
        address: address
      }
      expect(client).to have_received(:post).with(Boxr::Client::WEBHOOKS_URI, expected_attributes)
      expect(result).to eq(webhook_data)
    end

    it 'creates webhook with folder target' do
      folder_target_type = 'folder'
      result = client.create_webhook(target_id, folder_target_type, triggers, address)

      expected_attributes = {
        target: { id: target_id, type: folder_target_type },
        triggers: triggers,
        address: address
      }
      expect(client).to have_received(:post).with(Boxr::Client::WEBHOOKS_URI, expected_attributes)
      expect(result).to eq(webhook_data)
    end

    it 'creates webhook with single trigger' do
      single_trigger = ['FILE.UPLOADED']
      result = client.create_webhook(target_id, target_type, single_trigger, address)

      expected_attributes = {
        target: { id: target_id, type: target_type },
        triggers: single_trigger,
        address: address
      }
      expect(client).to have_received(:post).with(Boxr::Client::WEBHOOKS_URI, expected_attributes)
      expect(result).to eq(webhook_data)
    end
  end

  describe '#get_webhooks' do
    before do
      allow(client).to receive(:get).and_return([webhooks_collection, mock_response])
    end

    it 'retrieves all webhooks without parameters' do
      result = client.get_webhooks

      expect(client).to have_received(:get).with(Boxr::Client::WEBHOOKS_URI, query: {})
      expect(result).to eq(webhooks_collection)
    end

    it 'retrieves webhooks with marker' do
      marker = 'next_marker'
      result = client.get_webhooks(marker: marker)

      expect(client).to have_received(:get).with(Boxr::Client::WEBHOOKS_URI,
                                                 query: { marker: marker })
      expect(result).to eq(webhooks_collection)
    end

    it 'retrieves webhooks with limit' do
      limit = 50
      result = client.get_webhooks(limit: limit)

      expect(client).to have_received(:get).with(Boxr::Client::WEBHOOKS_URI,
                                                 query: { limit: limit })
      expect(result).to eq(webhooks_collection)
    end

    it 'retrieves webhooks with both marker and limit' do
      marker = 'next_marker'
      limit = 25
      result = client.get_webhooks(marker: marker, limit: limit)

      expect(client).to have_received(:get).with(Boxr::Client::WEBHOOKS_URI,
                                                 query: { marker: marker, limit: limit })
      expect(result).to eq(webhooks_collection)
    end

    it 'filters out nil parameters' do
      result = client.get_webhooks(marker: nil, limit: 10)

      expect(client).to have_received(:get).with(Boxr::Client::WEBHOOKS_URI, query: { limit: 10 })
      expect(result).to eq(webhooks_collection)
    end
  end

  describe '#get_webhook' do
    before do
      allow(client).to receive(:get).and_return([webhook_data, mock_response])
    end

    it 'retrieves webhook by ID string' do
      result = client.get_webhook(webhook_id)

      expect(client).to have_received(:get).with("#{Boxr::Client::WEBHOOKS_URI}/#{webhook_id}")
      expect(result).to eq(webhook_data)
    end

    it 'retrieves webhook by webhook object' do
      webhook_obj = BoxrMash.new(id: webhook_id)
      result = client.get_webhook(webhook_obj)

      expect(client).to have_received(:get).with("#{Boxr::Client::WEBHOOKS_URI}/#{webhook_id}")
      expect(result).to eq(webhook_data)
    end

    it 'handles webhook object with string ID' do
      webhook_obj = BoxrMash.new(id: webhook_id.to_s)
      result = client.get_webhook(webhook_obj)

      expect(client).to have_received(:get).with("#{Boxr::Client::WEBHOOKS_URI}/#{webhook_id}")
      expect(result).to eq(webhook_data)
    end
  end

  describe '#update_webhook' do
    let(:update_attributes) { { address: 'https://new-webhook.com/endpoint', triggers: ['FILE.DELETED'] } }
    let(:updated_webhook) { BoxrMash.new(id: webhook_id, **update_attributes) }

    before do
      allow(client).to receive(:put).and_return([updated_webhook, mock_response])
    end

    it 'updates webhook by ID string' do
      result = client.update_webhook(webhook_id, update_attributes)

      expect(client).to have_received(:put).with("#{Boxr::Client::WEBHOOKS_URI}/#{webhook_id}",
                                                 update_attributes)
      expect(result).to eq(updated_webhook)
    end

    it 'updates webhook by webhook object' do
      webhook_obj = BoxrMash.new(id: webhook_id)
      result = client.update_webhook(webhook_obj, update_attributes)

      expect(client).to have_received(:put).with("#{Boxr::Client::WEBHOOKS_URI}/#{webhook_id}",
                                                 update_attributes)
      expect(result).to eq(updated_webhook)
    end

    it 'updates webhook with empty attributes' do
      result = client.update_webhook(webhook_id, {})

      expect(client).to have_received(:put).with("#{Boxr::Client::WEBHOOKS_URI}/#{webhook_id}", {})
      expect(result).to eq(updated_webhook)
    end

    it 'updates webhook with address only' do
      address_only = { address: 'https://new-address.com' }
      result = client.update_webhook(webhook_id, address_only)

      expect(client).to have_received(:put).with("#{Boxr::Client::WEBHOOKS_URI}/#{webhook_id}",
                                                 address_only)
      expect(result).to eq(updated_webhook)
    end

    it 'updates webhook with triggers only' do
      triggers_only = { triggers: ['FILE.MOVED'] }
      result = client.update_webhook(webhook_id, triggers_only)

      expect(client).to have_received(:put).with("#{Boxr::Client::WEBHOOKS_URI}/#{webhook_id}",
                                                 triggers_only)
      expect(result).to eq(updated_webhook)
    end
  end

  describe '#delete_webhook' do
    let(:delete_result) { {} }

    before do
      allow(client).to receive(:delete).and_return([delete_result, mock_response])
    end

    it 'deletes webhook by ID string' do
      result = client.delete_webhook(webhook_id)

      expect(client).to have_received(:delete).with("#{Boxr::Client::WEBHOOKS_URI}/#{webhook_id}")
      expect(result).to eq(delete_result)
    end

    it 'deletes webhook by webhook object' do
      webhook_obj = BoxrMash.new(id: webhook_id)
      result = client.delete_webhook(webhook_obj)

      expect(client).to have_received(:delete).with("#{Boxr::Client::WEBHOOKS_URI}/#{webhook_id}")
      expect(result).to eq(delete_result)
    end

    it 'handles webhook object with string ID' do
      webhook_obj = BoxrMash.new(id: webhook_id.to_s)
      result = client.delete_webhook(webhook_obj)

      expect(client).to have_received(:delete).with("#{Boxr::Client::WEBHOOKS_URI}/#{webhook_id}")
      expect(result).to eq(delete_result)
    end

    it 'returns empty hash on successful deletion' do
      result = client.delete_webhook(webhook_id)
      expect(result).to eq({})
    end
  end

  describe 'error handling' do
    before do
      allow(client).to receive(:post).and_raise(Boxr::BoxrError.new(status: 400,
                                                                    body: '{"error":"invalid_request"}'))
    end

    it 'raises BoxrError on create webhook failure' do
      expect do
        client.create_webhook(target_id, target_type, triggers, address)
      end.to raise_error(Boxr::BoxrError)
    end
  end

  describe 'private methods' do
    describe '#ensure_id' do
      it 'returns ID from string' do
        result = client.send(:ensure_id, webhook_id)
        expect(result).to eq(webhook_id)
      end

      it 'returns ID from webhook object' do
        webhook_obj = BoxrMash.new(id: webhook_id)
        result = client.send(:ensure_id, webhook_obj)
        expect(result).to eq(webhook_id)
      end

      it 'handles webhook object with string ID' do
        webhook_obj = BoxrMash.new(id: webhook_id.to_s)
        result = client.send(:ensure_id, webhook_obj)
        expect(result).to eq(webhook_id)
      end
    end
  end
end

require 'spec_helper'

describe Boxr::Client do
  let(:client) { described_class.new }
  let(:shared_link) { 'https://app.box.com/s/abc123def456' }
  let(:shared_link_password) { 'password123' }
  let(:mock_response) { instance_double(HTTP::Message, status: 200, header: {}) }
  let(:mock_file) { Hashie::Mash.new(id: '12345', name: 'shared_file.txt', type: 'file') }
  let(:mock_folder) { Hashie::Mash.new(id: '67890', name: 'shared_folder', type: 'folder') }

  describe '#shared_item' do
    before do
      allow(client).to receive(:get).and_return([mock_file, mock_response])
    end

    it 'retrieves shared item with shared link only' do
      result = client.shared_item(shared_link)
      expect(result).to eq(mock_file)
    end

    it 'calls get with correct URI and box_api_header' do
      client.shared_item(shared_link)
      expect(client).to have_received(:get).with(
        Boxr::Client::SHARED_ITEMS_URI,
        box_api_header: "shared_link=#{shared_link}"
      )
    end

    it 'retrieves shared item with shared link and password' do
      result = client.shared_item(shared_link, shared_link_password: shared_link_password)
      expect(result).to eq(mock_file)
    end

    it 'calls get with correct URI and box_api_header including password' do
      client.shared_item(shared_link, shared_link_password: shared_link_password)
      expect(client).to have_received(:get).with(
        Boxr::Client::SHARED_ITEMS_URI,
        box_api_header: "shared_link=#{shared_link}&shared_link_password=#{shared_link_password}"
      )
    end

    it 'handles shared folder' do
      allow(client).to receive(:get).and_return([mock_folder, mock_response])
      result = client.shared_item(shared_link)
      expect(result).to eq(mock_folder)
    end

    it 'handles nil password parameter' do
      client.shared_item(shared_link, shared_link_password: nil)
      expect(client).to have_received(:get).with(
        Boxr::Client::SHARED_ITEMS_URI,
        box_api_header: "shared_link=#{shared_link}"
      )
    end

    it 'handles empty string password parameter' do
      client.shared_item(shared_link, shared_link_password: '')
      expect(client).to have_received(:get).with(
        Boxr::Client::SHARED_ITEMS_URI,
        box_api_header: "shared_link=#{shared_link}&shared_link_password="
      )
    end

    context 'when API returns error' do
      let(:error_response) { instance_double(HTTP::Message, status: 404, header: {}) }

      before do
        allow(client).to receive(:get).and_raise(Boxr::BoxrError.new(status: 404, body: 'Not found'))
      end

      it 'raises BoxrError for invalid shared link' do
        expect do
          client.shared_item('invalid_link')
        end.to raise_error(Boxr::BoxrError, /Not found/)
      end

      it 'raises BoxrError for incorrect password' do
        expect do
          client.shared_item(shared_link, shared_link_password: 'wrong_password')
        end.to raise_error(Boxr::BoxrError, /Not found/)
      end
    end

    context 'with special characters in shared link' do
      let(:special_link) { 'https://app.box.com/s/abc123def456?param=value&other=test' }

      it 'handles shared link with query parameters' do
        client.shared_item(special_link)
        expect(client).to have_received(:get).with(
          Boxr::Client::SHARED_ITEMS_URI,
          box_api_header: "shared_link=#{special_link}"
        )
      end
    end

    context 'with special characters in password' do
      let(:special_password) { 'pass&word=with&special=chars' }

      it 'handles password with special characters' do
        client.shared_item(shared_link, shared_link_password: special_password)
        expect(client).to have_received(:get).with(
          Boxr::Client::SHARED_ITEMS_URI,
          box_api_header: "shared_link=#{shared_link}&shared_link_password=#{special_password}"
        )
      end
    end
  end
end

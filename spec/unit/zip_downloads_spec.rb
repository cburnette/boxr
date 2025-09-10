require 'spec_helper'

describe Boxr::Client do
  let(:client) { described_class.new }
  let(:test_file) { Hashie::Mash.new(id: '67890', name: 'test.txt') }
  let(:test_folder) { Hashie::Mash.new(id: '12345', name: 'test_folder') }
  let(:mock_zip_download) do
    BoxrMash.new(
      download_url: 'https://example.com/download.zip',
      status_url: 'https://example.com/status',
      expires_at: Time.now + 3600
    )
  end

  describe '#create_zip_download' do
    before do
      allow(client).to receive(:post).and_return([mock_zip_download,
                                                  instance_double(HTTP::Message, status: 200)])
    end

    it 'creates zip download with file targets' do
      targets = [{ type: 'file', id: test_file.id }]
      result = client.create_zip_download(targets)
      expect(result).to eq(mock_zip_download)
    end

    it 'creates zip download with folder targets' do
      targets = [{ type: 'folder', id: test_folder.id }]
      result = client.create_zip_download(targets)
      expect(result).to eq(mock_zip_download)
    end

    it 'creates zip download with mixed targets' do
      targets = [{ type: 'file', id: test_file.id },
                 { type: 'folder', id: test_folder.id }]
      result = client.create_zip_download(targets)
      expect(result).to eq(mock_zip_download)
    end

    it 'creates zip download with custom file name' do
      targets = [{ type: 'file', id: test_file.id }]
      result = client.create_zip_download(targets, download_file_name: 'custom.zip')
      expect(result).to eq(mock_zip_download)
    end

    it 'creates zip download without file name' do
      targets = [{ type: 'file', id: test_file.id }]
      result = client.create_zip_download(targets)
      expect(result).to eq(mock_zip_download)
    end

    it 'calls post with correct parameters' do
      targets = [{ type: 'file', id: test_file.id }]
      client.create_zip_download(targets, download_file_name: 'test.zip')

      expect(client).to have_received(:post).with(
        Boxr::Client::ZIP_DOWNLOADS_URI,
        hash_including(
          download_file_name: 'test.zip',
          items: targets
        ),
        success_codes: [200, 202]
      )
    end

    it 'handles 202 status response' do
      allow(client).to receive(:post).and_return([mock_zip_download,
                                                  instance_double(HTTP::Message, status: 202)])
      targets = [{ type: 'file', id: test_file.id }]
      result = client.create_zip_download(targets)
      expect(result).to eq(mock_zip_download)
    end

    it 'handles empty targets array' do
      targets = []
      result = client.create_zip_download(targets)
      expect(result).to eq(mock_zip_download)
    end

    it 'handles targets with additional properties' do
      targets = [
        { type: 'file', id: test_file.id, name: 'custom_name.txt' }
      ]
      result = client.create_zip_download(targets)
      expect(result).to eq(mock_zip_download)
    end
  end
end

require 'spec_helper'

describe Boxr::Client do
  let(:client) { described_class.new }
  let(:test_file) { Hashie::Mash.new(id: '12345', name: 'test.txt') }
  let(:test_folder) { Hashie::Mash.new(id: '67890', name: 'test_folder') }
  let(:mock_response) { instance_double(HTTP::Message, status: 200, header: {}) }
  let(:mock_watermark_info) do
    BoxrMash.new(
      watermark: Hashie::Mash.new(imprint: 'default')
    )
  end

  describe '#get_watermark_on_file' do
    before do
      allow(client).to receive(:get).and_return(mock_watermark_info)
    end

    it 'retrieves watermark on file' do
      result = client.get_watermark_on_file(test_file)
      expect(result).to eq(mock_watermark_info)
    end

    it 'calls get with correct URI' do
      client.get_watermark_on_file(test_file)
      expect(client).to have_received(:get).with("#{Boxr::Client::FILES_URI}/#{test_file.id}/watermark")
    end
  end

  describe '#apply_watermark_on_file' do
    before do
      allow(client).to receive(:put).and_return(mock_watermark_info)
    end

    it 'applies watermark on file' do
      result = client.apply_watermark_on_file(test_file)
      expect(result).to eq(mock_watermark_info)
    end

    it 'calls put with correct URI and attributes' do
      client.apply_watermark_on_file(test_file)
      expect(client).to have_received(:put).with(
        "#{Boxr::Client::FILES_URI}/#{test_file.id}/watermark",
        { watermark: { imprint: 'default' } },
        content_type: 'application/json'
      )
    end
  end

  describe '#remove_watermark_on_file' do
    before do
      allow(client).to receive(:delete).and_return({})
    end

    it 'removes watermark from file' do
      result = client.remove_watermark_on_file(test_file)
      expect(result).to eq({})
    end

    it 'calls delete with correct URI' do
      client.remove_watermark_on_file(test_file)
      expect(client).to have_received(:delete).with("#{Boxr::Client::FILES_URI}/#{test_file.id}/watermark")
    end
  end

  describe '#get_watermark_on_folder' do
    before do
      allow(client).to receive(:get).and_return(mock_watermark_info)
    end

    it 'retrieves watermark on folder' do
      result = client.get_watermark_on_folder(test_folder)
      expect(result).to eq(mock_watermark_info)
    end

    it 'calls get with correct URI' do
      client.get_watermark_on_folder(test_folder)
      expect(client).to have_received(:get).with("#{Boxr::Client::FOLDERS_URI}/#{test_folder.id}/watermark")
    end
  end

  describe '#apply_watermark_on_folder' do
    before do
      allow(client).to receive(:put).and_return(mock_watermark_info)
    end

    it 'applies watermark on folder' do
      result = client.apply_watermark_on_folder(test_folder)
      expect(result).to eq(mock_watermark_info)
    end

    it 'calls put with correct URI and attributes' do
      client.apply_watermark_on_folder(test_folder)
      expect(client).to have_received(:put).with(
        "#{Boxr::Client::FOLDERS_URI}/#{test_folder.id}/watermark",
        { watermark: { imprint: 'default' } },
        content_type: 'application/json'
      )
    end
  end

  describe '#remove_watermark_on_folder' do
    before do
      allow(client).to receive(:delete).and_return({})
    end

    it 'removes watermark from folder' do
      result = client.remove_watermark_on_folder(test_folder)
      expect(result).to eq({})
    end

    it 'calls delete with correct URI' do
      client.remove_watermark_on_folder(test_folder)
      expect(client).to have_received(:delete).with("#{Boxr::Client::FOLDERS_URI}/#{test_folder.id}/watermark")
    end
  end
end

require 'spec_helper'

describe Boxr::Client do
  let(:client) { described_class.new }
  let(:test_web_link) { Hashie::Mash.new(id: '12345', name: 'test link', url: 'https://example.com') }
  let(:test_parent) { Hashie::Mash.new(id: '67890') }
  let(:mock_response) { instance_double(HTTP::Message, status: 200, header: {}) }
  let(:mock_web_link_info) do
    BoxrMash.new(
      id: '12345',
      name: 'test link',
      url: 'https://example.com',
      description: 'test description',
      item_status: 'active'
    )
  end

  describe '#create_web_link' do
    before do
      allow(client).to receive(:post).and_return(mock_web_link_info)
    end

    it 'creates web link with url and parent' do
      result = client.create_web_link('https://example.com', test_parent)
      expect(result).to eq(mock_web_link_info)
    end

    it 'creates web link with name' do
      result = client.create_web_link('https://example.com', test_parent, name: 'My Link')
      expect(result).to eq(mock_web_link_info)
    end

    it 'creates web link with description' do
      result = client.create_web_link('https://example.com', test_parent,
                                      description: 'Link description')
      expect(result).to eq(mock_web_link_info)
    end

    it 'creates web link with both name and description' do
      result = client.create_web_link('https://example.com', test_parent,
                                      name: 'My Link', description: 'Link description')
      expect(result).to eq(mock_web_link_info)
    end

    it 'accepts parent as string ID' do
      result = client.create_web_link('https://example.com', '67890')
      expect(result).to eq(mock_web_link_info)
    end

    it 'raises error for invalid URL' do
      expect do
        client.create_web_link('invalid-url', test_parent)
      end.to raise_error(Boxr::BoxrError, /Invalid url/)
    end
  end

  describe '#get_web_link' do
    before do
      allow(client).to receive(:get).and_return(mock_web_link_info)
    end

    it 'retrieves web link by object' do
      result = client.get_web_link(test_web_link)
      expect(result).to eq(mock_web_link_info)
    end

    it 'retrieves web link by ID' do
      result = client.get_web_link('12345')
      expect(result).to eq(mock_web_link_info)
    end
  end

  describe '#update_web_link' do
    before do
      allow(client).to receive(:put).and_return(mock_web_link_info)
    end

    it 'updates web link with new name' do
      result = client.update_web_link(test_web_link, name: 'Updated Name')
      expect(result).to eq(mock_web_link_info)
    end

    it 'updates web link with new description' do
      result = client.update_web_link(test_web_link, description: 'Updated description')
      expect(result).to eq(mock_web_link_info)
    end

    it 'updates web link with new URL' do
      result = client.update_web_link(test_web_link, url: 'https://newurl.com')
      expect(result).to eq(mock_web_link_info)
    end

    it 'updates web link with new parent' do
      result = client.update_web_link(test_web_link, parent: 'new_parent_id')
      expect(result).to eq(mock_web_link_info)
    end

    it 'updates web link with multiple attributes' do
      result = client.update_web_link(test_web_link,
                                      name: 'Updated Name',
                                      description: 'Updated description',
                                      url: 'https://newurl.com')
      expect(result).to eq(mock_web_link_info)
    end

    it 'accepts web link as string ID' do
      result = client.update_web_link('12345', name: 'Updated Name')
      expect(result).to eq(mock_web_link_info)
    end
  end

  describe '#delete_web_link' do
    before do
      allow(client).to receive(:delete).and_return({})
    end

    it 'deletes web link by object' do
      result = client.delete_web_link(test_web_link)
      expect(result).to eq({})
    end

    it 'deletes web link by ID' do
      result = client.delete_web_link('12345')
      expect(result).to eq({})
    end
  end

  describe '#trashed_web_link' do
    let(:trashed_web_link) do
      BoxrMash.new(
        id: '12345',
        name: 'test link',
        url: 'https://example.com',
        item_status: 'trashed'
      )
    end

    before do
      allow(client).to receive(:get).and_return(trashed_web_link)
    end

    it 'retrieves trashed web link by object' do
      result = client.trashed_web_link(test_web_link)
      expect(result).to eq(trashed_web_link)
    end

    it 'retrieves trashed web link by ID' do
      result = client.trashed_web_link('12345')
      expect(result).to eq(trashed_web_link)
    end

    it 'retrieves trashed web link with fields' do
      result = client.trashed_web_link(test_web_link, fields: %i[name url])
      expect(result).to eq(trashed_web_link)
    end
  end

  describe '#get_trashed_web_link (alias)' do
    let(:trashed_web_link) do
      BoxrMash.new(
        id: '12345',
        name: 'test link',
        url: 'https://example.com',
        item_status: 'trashed'
      )
    end

    before do
      allow(client).to receive(:get).and_return(trashed_web_link)
    end

    it 'calls trashed_web_link' do
      result = client.get_trashed_web_link(test_web_link)
      expect(result).to eq(trashed_web_link)
    end
  end

  describe '#delete_trashed_web_link' do
    before do
      allow(client).to receive(:delete).and_return({})
    end

    it 'permanently deletes trashed web link by object' do
      result = client.delete_trashed_web_link(test_web_link)
      expect(result).to eq({})
    end

    it 'permanently deletes trashed web link by ID' do
      result = client.delete_trashed_web_link('12345')
      expect(result).to eq({})
    end
  end

  describe '#restore_trashed_web_link' do
    let(:restored_web_link) do
      BoxrMash.new(
        id: '12345',
        name: 'test link',
        url: 'https://example.com',
        item_status: 'active'
      )
    end

    before do
      allow(client).to receive(:post).and_return(restored_web_link)
    end

    it 'restores trashed web link by object' do
      result = client.restore_trashed_web_link(test_web_link)
      expect(result).to eq(restored_web_link)
    end

    it 'restores trashed web link by ID' do
      result = client.restore_trashed_web_link('12345')
      expect(result).to eq(restored_web_link)
    end

    it 'restores trashed web link with new name' do
      result = client.restore_trashed_web_link(test_web_link, name: 'Restored Link')
      expect(result).to eq(restored_web_link)
    end

    it 'restores trashed web link to new parent' do
      result = client.restore_trashed_web_link(test_web_link, parent: 'new_parent_id')
      expect(result).to eq(restored_web_link)
    end

    it 'restores trashed web link with both name and parent' do
      result = client.restore_trashed_web_link(test_web_link,
                                               name: 'Restored Link',
                                               parent: 'new_parent_id')
      expect(result).to eq(restored_web_link)
    end
  end

  describe 'private methods' do
    describe '#verify_url' do
      it 'accepts valid https URL' do
        result = client.send(:verify_url, 'https://example.com')
        expect(result).to eq('https://example.com')
      end

      it 'accepts valid http URL' do
        result = client.send(:verify_url, 'http://example.com')
        expect(result).to eq('http://example.com')
      end

      it 'raises error for invalid URL' do
        expect do
          client.send(:verify_url, 'invalid-url')
        end.to raise_error(Boxr::BoxrError, /Invalid url/)
      end

      it 'raises error for URL without protocol' do
        expect do
          client.send(:verify_url, 'example.com')
        end.to raise_error(Boxr::BoxrError, /Invalid url/)
      end
    end
  end
end

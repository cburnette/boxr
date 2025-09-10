require 'spec_helper'

describe Boxr::Client do
  let(:client) { described_class.new }
  let(:test_folder) { Hashie::Mash.new(id: '12345') }
  let(:test_file) { Hashie::Mash.new(id: '67890') }
  let(:test_group) { Hashie::Mash.new(id: 'group123') }
  let(:test_collaboration) { Hashie::Mash.new(id: 'collab123', role: 'editor') }
  let(:mock_response) { instance_double(HTTP::Message, status: 200, header: {}) }
  let(:mock_collaborations_response) do
    BoxrMash.new(
      entries: [test_collaboration, test_collaboration]
    )
  end

  describe '#folder_collaborations' do
    before do
      allow(client).to receive(:get_all_with_pagination).and_return(mock_collaborations_response)
    end

    it 'retrieves folder collaborations' do
      result = client.folder_collaborations(test_folder)
      expect(result).to eq(mock_collaborations_response)
    end

    it 'retrieves folder collaborations with fields' do
      client.folder_collaborations(test_folder, fields: %i[role status])
      expect(client).to have_received(:get_all_with_pagination).with(
        anything, hash_including(query: anything)
      )
    end

    it 'retrieves folder collaborations with pagination' do
      client.folder_collaborations(test_folder, offset: 10, limit: 25)
      expect(client).to have_received(:get_all_with_pagination).with(
        anything, hash_including(offset: 10, limit: 25)
      )
    end
  end

  describe '#file_collaborations' do
    before do
      allow(client).to receive(:get).and_return([mock_collaborations_response, mock_response])
    end

    it 'retrieves file collaborations' do
      result = client.file_collaborations(test_file)
      expect(result).to eq([test_collaboration, test_collaboration])
    end

    it 'retrieves file collaborations with fields' do
      client.file_collaborations(test_file, fields: %i[role status])
      expect(client).to have_received(:get).with(anything, hash_including(query: anything))
    end

    it 'retrieves file collaborations with limit' do
      client.file_collaborations(test_file, limit: 50)
      expect(client).to have_received(:get).with(anything,
                                                 hash_including(query: hash_including(limit: 50)))
    end

    it 'retrieves file collaborations with marker' do
      client.file_collaborations(test_file, marker: 'marker123')
      expect(client).to have_received(:get).with(anything,
                                                 hash_including(query: hash_including(marker: 'marker123')))
    end
  end

  describe '#group_collaborations' do
    before do
      allow(client).to receive(:get_all_with_pagination).and_return(mock_collaborations_response)
    end

    it 'retrieves group collaborations' do
      result = client.group_collaborations(test_group)
      expect(result).to eq(mock_collaborations_response)
    end

    it 'retrieves group collaborations with pagination' do
      client.group_collaborations(test_group, offset: 5, limit: 20)
      expect(client).to have_received(:get_all_with_pagination).with(
        anything, hash_including(offset: 5, limit: 20)
      )
    end
  end

  describe '#add_collaboration' do
    let(:accessible_by) { { type: 'user', id: 'user123' } }
    let(:role) { :editor }

    before do
      allow(client).to receive(:post).and_return(test_collaboration)
    end

    it 'adds collaboration to folder' do
      result = client.add_collaboration(test_folder, accessible_by, role)
      expect(result).to eq(test_collaboration)
    end

    it 'adds collaboration to file' do
      result = client.add_collaboration(test_file, accessible_by, role, type: :file)
      expect(result).to eq(test_collaboration)
    end

    it 'adds collaboration with fields' do
      client.add_collaboration(test_folder, accessible_by, role, fields: %i[role status])
      expect(client).to have_received(:post).with(anything, anything,
                                                  hash_including(query: anything))
    end

    it 'adds collaboration with notify parameter' do
      client.add_collaboration(test_folder, accessible_by, role, notify: true)
      expect(client).to have_received(:post).with(anything, anything,
                                                  hash_including(query: hash_including(notify: true)))
    end

    it 'validates role before adding' do
      expect do
        client.add_collaboration(test_folder, accessible_by,
                                 :invalid_role)
      end.to raise_error(Boxr::BoxrError)
    end
  end

  describe '#edit_collaboration' do
    before do
      allow(client).to receive(:put).and_return(test_collaboration)
    end

    it 'edits collaboration role' do
      result = client.edit_collaboration(test_collaboration, role: :viewer)
      expect(result).to eq(test_collaboration)
    end

    it 'edits collaboration status' do
      result = client.edit_collaboration(test_collaboration, status: :accepted)
      expect(result).to eq(test_collaboration)
    end

    it 'edits collaboration role and status' do
      result = client.edit_collaboration(test_collaboration, role: :co_owner, status: :accepted)
      expect(result).to eq(test_collaboration)
    end

    it 'validates role before editing' do
      expect do
        client.edit_collaboration(test_collaboration,
                                  role: :invalid_role)
      end.to raise_error(Boxr::BoxrError)
    end
  end

  describe '#remove_collaboration' do
    before do
      allow(client).to receive(:delete).and_return({})
    end

    it 'removes collaboration' do
      result = client.remove_collaboration(test_collaboration)
      expect(result).to eq({})
    end
  end

  describe '#collaboration' do
    before do
      allow(client).to receive(:get).and_return(test_collaboration)
    end

    it 'retrieves collaboration by ID' do
      result = client.collaboration('collab123')
      expect(result).to eq(test_collaboration)
    end

    it 'retrieves collaboration with fields' do
      client.collaboration('collab123', fields: %i[role status])
      expect(client).to have_received(:get).with(anything, hash_including(query: anything))
    end

    it 'retrieves collaboration with status filter' do
      client.collaboration('collab123', status: :accepted)
      expect(client).to have_received(:get).with(anything,
                                                 hash_including(query: hash_including(status: :accepted)))
    end
  end

  describe '#pending_collaborations' do
    before do
      allow(client).to receive(:get).and_return([mock_collaborations_response, mock_response])
    end

    it 'retrieves pending collaborations' do
      result = client.pending_collaborations
      expect(result).to eq([test_collaboration, test_collaboration])
    end

    it 'retrieves pending collaborations with fields' do
      client.pending_collaborations(fields: %i[role status])
      expect(client).to have_received(:get).with(anything, hash_including(query: anything))
    end
  end

  describe 'private methods' do
    describe '#validate_role' do
      it 'validates valid roles' do
        expect(client.send(:validate_role, :editor)).to eq('editor')
        expect(client.send(:validate_role, :viewer)).to eq('viewer')
        expect(client.send(:validate_role, :previewer)).to eq('previewer')
        expect(client.send(:validate_role, :uploader)).to eq('uploader')
        expect(client.send(:validate_role, :previewer_uploader)).to eq('previewer uploader')
        expect(client.send(:validate_role, :viewer_uploader)).to eq('viewer uploader')
        expect(client.send(:validate_role, :co_owner)).to eq('co-owner')
      end

      it 'converts symbols to strings' do
        expect(client.send(:validate_role, 'editor')).to eq('editor')
      end

      it 'raises error for invalid roles' do
        expect do
          client.send(:validate_role,
                      :invalid_role)
        end.to raise_error(Boxr::BoxrError, /Invalid collaboration role/)
      end
    end
  end
end

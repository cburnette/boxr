require 'spec_helper'

describe Boxr::Client do
  let(:client) { described_class.new }
  let(:test_folder) { Hashie::Mash.new(id: '12345', name: 'folder') }
  let(:test_file) { Hashie::Mash.new(id: '67890', name: 'test_file.txt') }
  let(:mock_response) { instance_double(HTTP::Message, status: 200, header: {}) }
  let(:mock_folder_info) do
    BoxrMash.new(id: '12345', name: 'test_folder', entries: [test_folder, test_file])
  end
  let(:mock_folder_items) { BoxrMash.new(folders: [test_folder], files: [test_file]) }

  describe '#folder_from_path' do
    it 'finds folder with absolute path' do
      allow(client).to receive(:folder_items)
        .with(Boxr::ROOT, fields: %i[id name]).and_return(mock_folder_items)
      result = client.folder_from_path('/folder')
      expect(result).to eq(test_folder)
    end

    it 'finds folder with relative path' do
      allow(client).to receive(:folder_items)
        .with(Boxr::ROOT, fields: %i[id name]).and_return(mock_folder_items)
      result = client.folder_from_path('folder')
      expect(result).to eq(test_folder)
    end

    it 'handles case-insensitive folder matching' do
      allow(test_folder).to receive(:name).and_return('TEST_FOLDER')
      allow(client).to receive(:folder_items)
        .with(Boxr::ROOT, fields: %i[id name]).and_return(mock_folder_items)
      result = client.folder_from_path('/test_folder')
      expect(result).to eq(test_folder)
    end

    it 'raises error when folder not found' do
      allow(client).to receive(:folder_items)
        .and_return(instance_double(BoxrCollection, folders: []))
      expect do
        client.folder_from_path('/nonexistent')
      end.to raise_error(Boxr::BoxrError, /Folder not found/)
    end

    it 'traverses nested path correctly' do
      parent_folder = Hashie::Mash.new(id: 'parent123', name: 'parent')
      child_folder = Hashie::Mash.new(id: 'child123', name: 'child')

      allow(client).to receive(:folder_items).with(Boxr::ROOT, fields: %i[id name]).and_return(
        instance_double(BoxrCollection, folders: [parent_folder])
      )
      allow(client).to receive(:folder_items).with(parent_folder, fields: %i[id name]).and_return(
        instance_double(BoxrCollection, folders: [child_folder])
      )

      expect(client.folder_from_path('/parent/child')).to eq(child_folder)
    end
  end

  describe '#folder_from_id' do
    before do
      allow(client).to receive(:get).and_return(mock_folder_info)
    end

    it 'retrieves folder by ID' do
      result = client.folder_from_id('12345')
      expect(result).to eq(mock_folder_info)
    end

    it 'accepts fields parameter' do
      client.folder_from_id('12345', fields: %i[name size])
      expect(client).to have_received(:get).with(
        "#{Boxr::Client::FOLDERS_URI}/12345",
        hash_including(query: { fields: 'name,size' })
      )
    end

    it 'accepts folder as object' do
      result = client.folder_from_id(test_folder)
      expect(result).to eq(mock_folder_info)
    end
  end

  describe '#folder (alias)' do
    before do
      allow(client).to receive(:get).and_return(mock_folder_info)
    end

    it 'calls folder_from_id' do
      result = client.folder('12345')
      expect(result).to eq(mock_folder_info)
    end
  end

  describe '#folder_items' do
    before do
      allow(client).to receive_messages(
        get_all_with_pagination: mock_folder_items,
        get: [mock_folder_items, mock_response]
      )
    end

    it 'retrieves folder items with pagination' do
      result = client.folder_items(test_folder)
      expect(result).to eq(mock_folder_items)
    end

    it 'retrieves folder items with fields' do
      client.folder_items(test_folder, fields: %i[name size])
      expect(client).to have_received(:get_all_with_pagination).with(
        anything, hash_including(query: { fields: 'name,size' })
      )
    end

    it 'retrieves folder items with specific offset and limit' do
      allow(client).to receive(:get)
        .and_return([{ 'entries' => [test_folder, test_file] }, mock_response])
      result = client.folder_items(test_folder, offset: 10, limit: 25)
      expect(result).to eq([test_folder, test_file])
    end

    it 'accepts folder as string ID' do
      result = client.folder_items('12345')
      expect(result).to eq(mock_folder_items)
    end
  end

  describe '#root_folder_items' do
    before do
      allow(client).to receive(:folder_items).and_return(mock_folder_items)
    end

    it 'retrieves root folder items' do
      result = client.root_folder_items
      expect(result).to eq(mock_folder_items)
    end

    it 'passes parameters to folder_items' do
      client.root_folder_items(fields: %i[name size], offset: 5, limit: 10)
      expect(client).to have_received(:folder_items).with(
        Boxr::ROOT, fields: %i[name size], offset: 5, limit: 10
      )
    end
  end

  describe '#create_folder' do
    before do
      allow(client).to receive(:post).and_return(mock_folder_info)
    end

    it 'creates folder with name and parent' do
      result = client.create_folder('new_folder', test_folder)
      expect(result).to eq(mock_folder_info)
    end

    it 'accepts parent as string ID' do
      result = client.create_folder('new_folder', '12345')
      expect(result).to eq(mock_folder_info)
    end
  end

  describe '#update_folder' do
    before do
      allow(client).to receive(:put).and_return(mock_folder_info)
    end

    it 'updates folder with name' do
      result = client.update_folder(test_folder, name: 'updated_name')
      expect(result).to eq(mock_folder_info)
    end

    it 'updates folder with description' do
      result = client.update_folder(test_folder, description: 'new description')
      expect(result).to eq(mock_folder_info)
    end

    it 'updates folder with parent' do
      result = client.update_folder(test_folder, parent: 'parent_id')
      expect(result).to eq(mock_folder_info)
    end

    it 'updates folder with shared_link' do
      result = client.update_folder(test_folder, shared_link: { access: 'open' })
      expect(result).to eq(mock_folder_info)
    end

    it 'updates folder with folder_upload_email_access' do
      result = client.update_folder(test_folder, folder_upload_email_access: 'open')
      expect(result).to eq(mock_folder_info)
    end

    it 'updates folder with owned_by' do
      result = client.update_folder(test_folder, owned_by: 'user123')
      expect(result).to eq(mock_folder_info)
    end

    it 'updates folder with sync_state' do
      result = client.update_folder(test_folder, sync_state: 'synced')
      expect(result).to eq(mock_folder_info)
    end

    it 'updates folder with tags' do
      result = client.update_folder(test_folder, tags: %w[tag1 tag2])
      expect(result).to eq(mock_folder_info)
    end

    it 'updates folder with can_non_owners_invite' do
      result = client.update_folder(test_folder, can_non_owners_invite: true)
      expect(result).to eq(mock_folder_info)
    end

    it 'updates folder with if_match' do
      result = client.update_folder(test_folder, name: 'updated_name', if_match: 'etag')
      expect(result).to eq(mock_folder_info)
    end

    it 'accepts folder as string ID' do
      result = client.update_folder('12345', name: 'updated_name')
      expect(result).to eq(mock_folder_info)
    end
  end

  describe '#move_folder' do
    before do
      allow(client).to receive(:update_folder).and_return(mock_folder_info)
    end

    it 'moves folder to new parent' do
      result = client.move_folder(test_folder, 'new_parent_id')
      expect(result).to eq(mock_folder_info)
    end

    it 'moves folder with new name' do
      result = client.move_folder(test_folder, 'new_parent_id', name: 'moved_folder')
      expect(result).to eq(mock_folder_info)
    end

    it 'moves folder with if_match' do
      result = client.move_folder(test_folder, 'new_parent_id', if_match: 'etag')
      expect(result).to eq(mock_folder_info)
    end

    it 'accepts folder as string ID' do
      result = client.move_folder('12345', 'new_parent_id')
      expect(result).to eq(mock_folder_info)
    end
  end

  describe '#delete_folder' do
    before do
      allow(client).to receive(:delete).and_return({})
    end

    it 'deletes folder' do
      result = client.delete_folder(test_folder)
      expect(result).to eq({})
    end

    it 'deletes folder recursively' do
      result = client.delete_folder(test_folder, recursive: true)
      expect(result).to eq({})
    end

    it 'deletes folder with if_match' do
      result = client.delete_folder(test_folder, if_match: 'etag')
      expect(result).to eq({})
    end

    it 'accepts folder as string ID' do
      result = client.delete_folder('12345')
      expect(result).to eq({})
    end
  end

  describe '#copy_folder' do
    before do
      allow(client).to receive(:post).and_return(mock_folder_info)
    end

    it 'copies folder to destination' do
      result = client.copy_folder(test_folder, 'dest_folder_id')
      expect(result).to eq(mock_folder_info)
    end

    it 'copies folder with new name' do
      result = client.copy_folder(test_folder, 'dest_folder_id', name: 'copied_folder')
      expect(result).to eq(mock_folder_info)
    end

    it 'accepts folders as string IDs' do
      result = client.copy_folder('12345', '67890')
      expect(result).to eq(mock_folder_info)
    end

    it 'accepts folders as objects' do
      dest_folder = Hashie::Mash.new(id: '67890')
      result = client.copy_folder(test_folder, dest_folder)
      expect(result).to eq(mock_folder_info)
    end
  end

  describe '#create_shared_link_for_folder' do
    before do
      allow(client).to receive(:create_shared_link).and_return(mock_folder_info)
    end

    it 'creates shared link with access level' do
      result = client.create_shared_link_for_folder(test_folder, access: :open)
      expect(result).to eq(mock_folder_info)
    end

    it 'creates shared link with unshared_at' do
      unshared_at = Time.now + 3600
      result = client.create_shared_link_for_folder(test_folder, unshared_at: unshared_at)
      expect(result).to eq(mock_folder_info)
    end

    it 'creates shared link with permissions' do
      result = client.create_shared_link_for_folder(test_folder, can_download: true,
                                                                 can_preview: false)
      expect(result).to eq(mock_folder_info)
    end

    it 'creates shared link with password' do
      result = client.create_shared_link_for_folder(test_folder, password: 'password123')
      expect(result).to eq(mock_folder_info)
    end

    it 'accepts folder as string ID' do
      result = client.create_shared_link_for_folder('12345', access: :open)
      expect(result).to eq(mock_folder_info)
    end
  end

  describe '#disable_shared_link_for_folder' do
    before do
      allow(client).to receive(:disable_shared_link).and_return(mock_folder_info)
    end

    it 'disables shared link' do
      result = client.disable_shared_link_for_folder(test_folder)
      expect(result).to eq(mock_folder_info)
    end

    it 'accepts folder as string ID' do
      result = client.disable_shared_link_for_folder('12345')
      expect(result).to eq(mock_folder_info)
    end
  end

  describe '#trash' do
    before do
      allow(client).to receive_messages(
        get_all_with_pagination: mock_folder_items,
        get: [mock_folder_items, mock_response]
      )
    end

    it 'retrieves trash items with pagination' do
      result = client.trash
      expect(result).to eq(mock_folder_items)
    end

    it 'retrieves trash items with fields' do
      client.trash(fields: %i[name size])
      expect(client).to have_received(:get_all_with_pagination).with(
        "#{Boxr::Client::FOLDERS_URI}/trash/items", hash_including(query: { fields: 'name,size' })
      )
    end

    it 'retrieves trash items with specific offset and limit' do
      allow(client).to receive(:get).and_return([{ 'entries' => [test_folder, test_file] },
                                                 mock_response])
      result = client.trash(offset: 10, limit: 25)
      expect(result).to eq([test_folder, test_file])
    end
  end

  describe '#trashed_folder' do
    before do
      allow(client).to receive(:get).and_return(mock_folder_info)
    end

    it 'retrieves trashed folder info' do
      result = client.trashed_folder(test_folder)
      expect(result).to eq(mock_folder_info)
    end

    it 'retrieves trashed folder with fields' do
      client.trashed_folder(test_folder, fields: %i[name size])
      expect(client).to have_received(:get).with(anything, hash_including(query: anything))
    end

    it 'accepts folder as string ID' do
      result = client.trashed_folder('12345')
      expect(result).to eq(mock_folder_info)
    end
  end

  describe '#delete_trashed_folder' do
    before do
      allow(client).to receive(:delete).and_return({})
    end

    it 'permanently deletes trashed folder' do
      result = client.delete_trashed_folder(test_folder)
      expect(result).to eq({})
    end

    it 'accepts folder as string ID' do
      result = client.delete_trashed_folder('12345')
      expect(result).to eq({})
    end
  end

  describe '#restore_trashed_folder' do
    before do
      allow(client).to receive(:restore_trashed_item).and_return(mock_folder_info)
    end

    it 'restores trashed folder' do
      result = client.restore_trashed_folder(test_folder)
      expect(result).to eq(mock_folder_info)
    end

    it 'restores trashed folder with new name' do
      result = client.restore_trashed_folder(test_folder, name: 'restored_folder')
      expect(result).to eq(mock_folder_info)
    end

    it 'restores trashed folder to new parent' do
      result = client.restore_trashed_folder(test_folder, parent: 'parent_id')
      expect(result).to eq(mock_folder_info)
    end

    it 'accepts folder as string ID' do
      result = client.restore_trashed_folder('12345')
      expect(result).to eq(mock_folder_info)
    end
  end
end

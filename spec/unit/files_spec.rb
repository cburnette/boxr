# frozen_string_literal: true

require 'spec_helper'

describe Boxr::Client do
  let(:client) { described_class.new }
  let(:test_folder) { Hashie::Mash.new(id: '12345') }
  let(:test_file) { Hashie::Mash.new(id: '67890', name: 'test.txt') }
  let(:mock_response) { instance_double(HTTP::Message, status: 200, header: {}) }
  let(:mock_file_info) do
    BoxrMash.new(
      expiring_embed_link: Hashie::Mash.new(url: 'https://example.com/embed'),
      entries: [test_file]
    )
  end

  let(:file_path) { '/tmp/test.txt' }
  let(:file_io) { instance_double(File, read: 'content', rewind: nil, size: 1024) }

  def setup_file_io_stubs
    allow(File).to receive(:open).with(file_path).and_yield(file_io)
    allow(File).to receive(:basename).with(file_path).and_return('test.txt')
  end

  describe '#file_from_path' do
    before do
      allow(client).to receive_messages(
        folder_from_path: test_folder,
        folder_items: instance_double(
          BoxrCollection, files: [test_file]
        )
      )
    end

    it 'finds file with absolute path' do
      result = client.file_from_path('/folder/test.txt')
      expect(result).to eq(test_file)
    end

    it 'finds file with relative path' do
      result = client.file_from_path('folder/test.txt')
      expect(result).to eq(test_file)
    end

    it 'raises error when file not found' do
      allow(client).to receive(:folder_items).and_return(instance_double(BoxrCollection, files: []))

      expect do
        client.file_from_path('/folder/nonexistent.txt')
      end.to raise_error(Boxr::BoxrError, /File not found/)
    end

    it 'handles case-insensitive file matching' do
      allow(test_file).to receive(:name).and_return('TEST.TXT')
      result = client.file_from_path('/folder/test.txt')
      expect(result).to eq(test_file)
    end
  end

  describe '#file_from_id' do
    before do
      allow(client).to receive(:get).and_return(mock_file_info)
    end

    it 'retrieves file by ID' do
      result = client.file_from_id('12345')
      expect(result).to eq(mock_file_info)
    end

    it 'accepts fields parameter' do
      client.file_from_id('12345', fields: %i[name size])
      expect(client).to have_received(:get).with(anything, hash_including(query: anything))
    end
  end

  describe '#file (alias)' do
    before do
      allow(client).to receive(:get).and_return(mock_file_info)
    end

    it 'calls file_from_id' do
      result = client.file('12345')
      expect(result).to eq(mock_file_info)
    end
  end

  describe '#embed_url' do
    before do
      allow(client).to receive(:get).and_return(mock_file_info)
    end

    it 'generates embed URL with default parameters' do
      result = client.embed_url(test_file)
      expect(result).to include('showDownload=false').and include('showAnnotations=false')
    end

    it 'generates embed URL with custom parameters' do
      result = client.embed_url(test_file, show_download: true, show_annotations: true)
      expect(result).to include('showDownload=true').and include('showAnnotations=true')
    end
  end

  describe '#embed_link (alias)' do
    before do
      allow(client).to receive(:get).and_return(mock_file_info)
    end

    it 'calls embed_url' do
      result = client.embed_link(test_file)
      expect(result).to include('showDownload=false')
    end
  end

  describe '#preview_url (alias)' do
    before do
      allow(client).to receive(:get).and_return(mock_file_info)
    end

    it 'calls embed_url' do
      result = client.preview_url(test_file)
      expect(result).to include('showDownload=false')
    end
  end

  describe '#preview_link (alias)' do
    before do
      allow(client).to receive(:get).and_return(mock_file_info)
    end

    it 'calls embed_url' do
      result = client.preview_link(test_file)
      expect(result).to include('showDownload=false')
    end
  end

  describe '#update_file' do
    before do
      allow(client).to receive(:put).and_return(test_file)
    end

    it 'updates file with name' do
      result = client.update_file(test_file, name: 'new_name.txt')
      expect(result).to eq(test_file)
    end

    it 'updates file with description' do
      result = client.update_file(test_file, description: 'new description')
      expect(result).to eq(test_file)
    end

    it 'updates file with parent' do
      result = client.update_file(test_file, parent: 'parent_id')
      expect(result).to eq(test_file)
    end

    it 'updates file with shared_link' do
      result = client.update_file(test_file, shared_link: { access: 'open' })
      expect(result).to eq(test_file)
    end

    it 'updates file with tags' do
      result = client.update_file(test_file, tags: %w[tag1 tag2])
      expect(result).to eq(test_file)
    end

    it 'updates file with lock' do
      result = client.update_file(test_file, lock: { type: 'lock' })
      expect(result).to eq(test_file)
    end

    it 'updates file with if_match' do
      result = client.update_file(test_file, name: 'new_name.txt', if_match: 'etag')
      expect(result).to eq(test_file)
    end
  end

  describe '#lock_file' do
    before do
      allow(client).to receive(:put).and_return(test_file)
    end

    it 'locks file with basic lock' do
      result = client.lock_file(test_file)
      expect(result).to eq(test_file)
    end

    it 'locks file with expiration' do
      expires_at = Time.now + 3600
      result = client.lock_file(test_file, expires_at: expires_at)
      expect(result).to eq(test_file)
    end

    it 'locks file with download prevention' do
      result = client.lock_file(test_file, is_download_prevented: true)
      expect(result).to eq(test_file)
    end

    it 'locks file with if_match' do
      result = client.lock_file(test_file, if_match: 'etag')
      expect(result).to eq(test_file)
    end
  end

  describe '#unlock_file' do
    before do
      allow(client).to receive(:put).and_return(test_file)
    end

    it 'unlocks file' do
      result = client.unlock_file(test_file)
      expect(result).to eq(test_file)
    end

    it 'unlocks file with if_match' do
      result = client.unlock_file(test_file, if_match: 'etag')
      expect(result).to eq(test_file)
    end
  end

  describe '#move_file' do
    before do
      allow(client).to receive(:put).and_return(test_file)
    end

    it 'moves file to new parent' do
      result = client.move_file(test_file, 'new_parent_id')
      expect(result).to eq(test_file)
    end

    it 'moves file with new name' do
      result = client.move_file(test_file, 'new_parent_id', name: 'new_name.txt')
      expect(result).to eq(test_file)
    end

    it 'moves file with if_match' do
      result = client.move_file(test_file, 'new_parent_id', if_match: 'etag')
      expect(result).to eq(test_file)
    end
  end

  describe '#download_file' do
    let(:redirect_url) { 'https://download.url' }
    let(:redirect_response) do
      instance_double(HTTP::Message, status: 302, header: { 'Location' => [redirect_url] })
    end
    let(:file_content) { 'file content' }
    let(:file_content_response) { instance_double(HTTP::Message, status: 200, body: file_content) }

    before do
      allow(client).to receive(:get).and_return(
        [nil, redirect_response], [file_content, file_content_response]
      )
    end

    it 'downloads file content following redirect' do
      result = client.download_file(test_file)
      expect(result).to eq(file_content)
    end

    it 'downloads file with version' do
      result = client.download_file(test_file, version: 'v1')
      expect(result).to eq(file_content)
    end

    it 'returns download URL when follow_redirect is false' do
      allow(client).to receive(:get).and_return([nil, redirect_response])
      result = client.download_file(test_file, follow_redirect: false)
      expect(result).to eq(redirect_url)
    end

    context 'when 202 status with retry' do
      let(:retry_response) do
        instance_double(HTTP::Message, status: 202, header: { 'Retry-After' => ['1'] })
      end

      before do
        allow(client).to receive(:get).and_return([nil, retry_response], [nil, redirect_response],
                                                  [file_content, file_content_response])
        allow(client).to receive(:sleep) # avoid sleeping in the test
      end

      it 'handles 202 status with retry' do
        expect(client.download_file(test_file)).to eq(file_content)
      end
    end
  end

  describe '#download_url' do
    let(:redirect_url) { 'https://download.url' }
    let(:redirect_response) do
      instance_double(HTTP::Message, status: 302, header: { 'Location' => [redirect_url] })
    end
    let(:file_content) { 'file content' }
    let(:file_content_response) { instance_double(HTTP::Message, status: 200, body: file_content) }

    before do
      allow(client).to receive(:get).and_return([nil, redirect_response],
                                                [file_content, file_content_response])
    end

    it 'returns download URL without following redirect' do
      expect(client.download_url(test_file)).to eq(redirect_url)
    end
  end

  describe '#upload_file' do
    before do
      setup_file_io_stubs
      allow(client).to receive_messages(post: mock_file_info, options: {})
    end

    it 'uploads file from path' do
      result = client.upload_file(file_path, test_folder)
      expect(result).to eq(test_file)
    end

    it 'uploads file with custom name' do
      result = client.upload_file(file_path, test_folder, name: 'custom.txt')
      expect(result).to eq(test_file)
    end

    it 'uploads file with content timestamps' do
      created_at = Time.now
      modified_at = Time.now
      result = client.upload_file(file_path, test_folder, content_created_at: created_at,
                                                          content_modified_at: modified_at)
      expect(result).to eq(test_file)
    end

    it 'uploads file with preflight check disabled' do
      result = client.upload_file(file_path, test_folder, preflight_check: false)
      expect(result).to eq(test_file)
    end

    it 'uploads file with content md5 disabled' do
      result = client.upload_file(file_path, test_folder, send_content_md5: false)
      expect(result).to eq(test_file)
    end
  end

  describe '#upload_file_from_io' do
    before do
      allow(client).to receive_messages(options: {}, post: mock_file_info)
    end

    it 'uploads file from IO' do
      result = client.upload_file_from_io(file_io, test_folder, name: 'test.txt')
      expect(result).to eq(test_file)
    end

    it 'uploads file with content timestamps' do
      result = client.upload_file_from_io(
        file_io, test_folder,
        name: 'test.txt', content_created_at: Time.now, content_modified_at: Time.now
      )
      expect(result).to eq(test_file)
    end

    it 'uploads file with preflight check disabled' do
      result = client.upload_file_from_io(file_io, test_folder, name: 'test.txt',
                                                                preflight_check: false)
      expect(result).to eq(test_file)
    end

    it 'uploads file with content md5 disabled' do
      result = client.upload_file_from_io(file_io, test_folder, name: 'test.txt',
                                                                send_content_md5: false)
      expect(result).to eq(test_file)
    end
  end

  describe '#upload_new_version_of_file' do
    before do
      setup_file_io_stubs
      allow(client).to receive_messages(options: {}, post: mock_file_info)
    end

    it 'uploads new version from path' do
      result = client.upload_new_version_of_file(file_path, test_file)
      expect(result).to eq(test_file)
    end

    it 'uploads new version with custom name' do
      result = client.upload_new_version_of_file(file_path, test_file, name: 'custom.txt')
      expect(result).to eq(test_file)
    end

    it 'uploads new version with content modified timestamp' do
      modified_at = Time.now
      result = client.upload_new_version_of_file(file_path, test_file,
                                                 content_modified_at: modified_at)
      expect(result).to eq(test_file)
    end

    it 'uploads new version with if_match' do
      result = client.upload_new_version_of_file(file_path, test_file, if_match: 'etag')
      expect(result).to eq(test_file)
    end
  end

  describe '#upload_new_version_of_file_from_io' do
    before do
      allow(client).to receive_messages(options: {}, post: mock_file_info)
    end

    it 'uploads new version from IO' do
      result = client.upload_new_version_of_file_from_io(file_io, test_file)
      expect(result).to eq(test_file)
    end

    it 'uploads new version with custom name' do
      result = client.upload_new_version_of_file_from_io(file_io, test_file, name: 'custom.txt')
      expect(result).to eq(test_file)
    end

    it 'uploads new version with content modified timestamp' do
      modified_at = Time.now
      result = client.upload_new_version_of_file_from_io(file_io, test_file,
                                                         content_modified_at: modified_at)
      expect(result).to eq(test_file)
    end

    it 'uploads new version with if_match' do
      result = client.upload_new_version_of_file_from_io(file_io, test_file, if_match: 'etag')
      expect(result).to eq(test_file)
    end
  end

  describe '#versions_of_file' do
    let(:versions_response) { instance_double(BoxrMash, entries: [test_file, test_file]) }

    before do
      allow(client).to receive(:get).and_return(versions_response)
    end

    it 'retrieves file versions' do
      result = client.versions_of_file(test_file)
      expect(result).to eq([test_file, test_file])
    end
  end

  describe '#promote_old_version_of_file' do
    before do
      allow(client).to receive(:post).and_return(mock_file_info)
    end

    it 'promotes old version to current' do
      result = client.promote_old_version_of_file(test_file, 'version_id')
      expect(result).to eq(mock_file_info)
    end
  end

  describe '#delete_file' do
    before do
      allow(client).to receive(:delete).and_return({})
    end

    it 'deletes file' do
      result = client.delete_file(test_file)
      expect(result).to eq({})
    end

    it 'deletes file with if_match' do
      result = client.delete_file(test_file, if_match: 'etag')
      expect(result).to eq({})
    end
  end

  describe '#delete_old_version_of_file' do
    before do
      allow(client).to receive(:delete).and_return({})
    end

    it 'deletes old version' do
      result = client.delete_old_version_of_file(test_file, 'version_id')
      expect(result).to eq({})
    end

    it 'deletes old version with if_match' do
      result = client.delete_old_version_of_file(test_file, 'version_id', if_match: 'etag')
      expect(result).to eq({})
    end
  end

  describe '#copy_file' do
    before do
      allow(client).to receive(:post).and_return(mock_file_info)
    end

    it 'copies file to new parent' do
      result = client.copy_file(test_file, 'parent_id')
      expect(result).to eq(mock_file_info)
    end

    it 'copies file with new name' do
      result = client.copy_file(test_file, 'parent_id', name: 'copy.txt')
      expect(result).to eq(mock_file_info)
    end
  end

  describe '#thumbnail' do
    let(:thumbnail_data) { 'thumbnail binary data' }

    before do
      allow(client).to receive(:get).and_return([thumbnail_data, mock_response])
    end

    it 'generates thumbnail with default parameters' do
      result = client.thumbnail(test_file)
      expect(result).to eq(thumbnail_data)
    end

    it 'generates thumbnail with size parameters' do
      result = client.thumbnail(
        test_file, min_height: 100, min_width: 100, max_height: 200, max_width: 200
      )
      expect(result).to eq(thumbnail_data)
    end

    context 'when redirect response' do
      let(:redirect_response) do
        instance_double(
          HTTP::Message, status: 302, header: { 'Location' => ['https://thumbnail.url'] }
        )
      end

      it 'handles redirect response' do
        allow(client).to receive(:get).and_return([nil, redirect_response],
                                                  [thumbnail_data, mock_response])
        expect(client.thumbnail(test_file)).to eq(thumbnail_data)
      end
    end

    context 'when 202 (retry) status with redirect' do
      let(:retry_response) do
        instance_double(HTTP::Message, status: 202,
                                       header: { 'Location' => ['https://thumbnail.url'] })
      end

      before do
        allow(client).to receive(:get).and_return([nil, retry_response],
                                                  [thumbnail_data, mock_response])
      end

      it 'handles 202 status with redirect' do
        expect(client.thumbnail(test_file)).to eq(thumbnail_data)
      end
    end
  end

  describe '#create_shared_link_for_file' do
    before do
      allow(client).to receive(:put).and_return(test_file)
    end

    it 'creates shared link with access level' do
      result = client.create_shared_link_for_file(test_file, access: :open)
      expect(result).to eq(test_file)
    end

    it 'creates shared link with unshared_at' do
      unshared_at = Time.now + 3600
      result = client.create_shared_link_for_file(test_file, unshared_at: unshared_at)
      expect(result).to eq(test_file)
    end

    it 'creates shared link with permissions' do
      result = client.create_shared_link_for_file(test_file, can_download: true, can_preview: false)
      expect(result).to eq(test_file)
    end

    it 'creates shared link with password' do
      result = client.create_shared_link_for_file(test_file, password: 'password123')
      expect(result).to eq(test_file)
    end
  end

  describe '#disable_shared_link_for_file' do
    before do
      allow(client).to receive(:put).and_return(test_file)
    end

    it 'disables shared link' do
      result = client.disable_shared_link_for_file(test_file)
      expect(result).to eq(test_file)
    end
  end

  describe '#trashed_file' do
    before do
      allow(client).to receive(:get).and_return(mock_file_info)
    end

    it 'retrieves trashed file info' do
      result = client.trashed_file(test_file)
      expect(result).to eq(mock_file_info)
    end

    it 'retrieves trashed file with fields' do
      result = client.trashed_file(test_file, fields: %i[name size])
      expect(result).to eq(mock_file_info)
    end
  end

  describe '#delete_trashed_file' do
    before do
      allow(client).to receive(:delete).and_return({})
    end

    it 'permanently deletes trashed file' do
      result = client.delete_trashed_file(test_file)
      expect(result).to eq({})
    end
  end

  describe '#restore_trashed_file' do
    before do
      allow(client).to receive(:post).and_return(mock_file_info)
    end

    it 'restores trashed file' do
      result = client.restore_trashed_file(test_file)
      expect(result).to eq(mock_file_info)
    end

    it 'restores trashed file with new name' do
      result = client.restore_trashed_file(test_file, name: 'restored.txt')
      expect(result).to eq(mock_file_info)
    end

    it 'restores trashed file to new parent' do
      result = client.restore_trashed_file(test_file, parent: 'parent_id')
      expect(result).to eq(mock_file_info)
    end
  end

  describe 'private methods' do
    before do
      setup_file_io_stubs
      allow(client).to receive(:options).and_return({})
    end

    describe '#preflight_check' do
      it 'performs preflight check for upload' do
        client.send(:preflight_check, file_io, 'test.txt', 'parent_id')
        expect(client).to have_received(:options)
      end
    end

    describe '#preflight_check_new_version_of_file' do
      it 'performs preflight check for new version' do
        client.send(:preflight_check_new_version_of_file, file_io, 'file_id')
        expect(client).to have_received(:options)
      end
    end
  end
end

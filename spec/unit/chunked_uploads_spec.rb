# frozen_string_literal: true

require 'spec_helper'

describe Boxr::Client do
  let(:client) { described_class.new }
  let(:test_folder) { Hashie::Mash.new(id: '12345') }
  let(:test_file) { Hashie::Mash.new(id: '67890', name: 'test.txt') }
  let(:mock_response) { instance_double(HTTP::Message, status: 200, header: {}) }
  let(:mock_session_info) do
    BoxrMash.new(id: 'session_123', part_size: 8_388_608, total_parts: 2, num_parts_processed: 0)
  end
  let(:mock_file_info) do
    BoxrMash.new(id: 'file_456', name: 'test.txt', size: 16_777_216, entries: [test_file])
  end
  let(:mock_commit_info) { BoxrMash.new(entries: [test_file]) }
  let(:mock_commit_info_with_entries) { BoxrMash.new(entries: [test_file]) }
  let(:mock_commit_response) { instance_double(HTTP::Message, status: 200) }
  let(:mock_parts_response) { BoxrMash.new(entries: []) }
  let(:file_path) { '/tmp/test.txt' }
  let(:file_io) { instance_double(File, read: 'content', rewind: nil, size: 16_777_216, pos: 0) }

  def setup_file_io_stubs
    allow(File).to receive(:open).with(file_path).and_yield(file_io)
    allow(File).to receive(:basename).and_call_original
    allow(File).to receive(:basename).with(file_path).and_return('test.txt')
  end

  describe '#chunked_upload_create_session_new_file' do
    before do
      setup_file_io_stubs
      allow(client).to receive(
        :chunked_upload_create_session_new_file_from_io
      ).and_return(mock_session_info)
    end

    it 'creates session for new file' do
      result = client.chunked_upload_create_session_new_file(file_path, test_folder)
      expect(result).to eq(mock_session_info)
    end

    it 'creates session with custom name' do
      result = client.chunked_upload_create_session_new_file(file_path, test_folder,
                                                             name: 'custom.txt')
      expect(result).to eq(mock_session_info)
    end

    it 'calls chunked_upload_create_session_new_file_from_io with correct parameters' do
      client.chunked_upload_create_session_new_file(file_path, test_folder, name: 'custom.txt')
      expect(client).to have_received(:chunked_upload_create_session_new_file_from_io).with(
        file_io, test_folder, 'custom.txt'
      )
    end
  end

  describe '#chunked_upload_create_session_new_file_from_io' do
    before do
      allow(client).to receive(:post).and_return([mock_session_info, mock_response])
    end

    it 'creates session from IO' do
      result = client.chunked_upload_create_session_new_file_from_io(file_io, test_folder,
                                                                     'test.txt')
      expect(result).to eq(mock_session_info)
    end

    it 'calls post with correct parameters' do
      client.chunked_upload_create_session_new_file_from_io(file_io, test_folder, 'test.txt')
      expect(client).to have_received(:post).with(
        "#{Boxr::Client::UPLOAD_URI}/files/upload_sessions",
        { folder_id: '12345', file_size: 16_777_216, file_name: 'test.txt' },
        content_type: 'application/json',
        success_codes: [200, 201, 202]
      )
    end
  end

  describe '#chunked_upload_create_session_new_version' do
    before do
      setup_file_io_stubs
      allow(client).to receive(:chunked_upload_create_session_new_version_from_io).and_return(mock_session_info)
    end

    it 'creates session for new version' do
      result = client.chunked_upload_create_session_new_version(file_path, test_file)
      expect(result).to eq(mock_session_info)
    end

    it 'creates session with custom name' do
      result = client.chunked_upload_create_session_new_version(file_path, test_file,
                                                                name: 'custom.txt')
      expect(result).to eq(mock_session_info)
    end

    it 'calls chunked_upload_create_session_new_version_from_io with correct parameters' do
      client.chunked_upload_create_session_new_version(file_path, test_file, name: 'custom.txt')
      expect(client).to have_received(:chunked_upload_create_session_new_version_from_io).with(
        file_io, test_file, 'custom.txt'
      )
    end
  end

  describe '#chunked_upload_create_session_new_version_from_io' do
    before do
      allow(client).to receive(:post).and_return([mock_session_info, mock_response])
    end

    it 'creates session from IO' do
      result = client.chunked_upload_create_session_new_version_from_io(file_io, test_file,
                                                                        'test.txt')
      expect(result).to eq(mock_session_info)
    end

    it 'calls post with correct parameters' do
      client.chunked_upload_create_session_new_version_from_io(file_io, test_file, 'test.txt')
      expect(client).to have_received(:post).with(
        "#{Boxr::Client::UPLOAD_URI}/files/67890/upload_sessions",
        { file_size: 16_777_216, file_name: 'test.txt' },
        content_type: 'application/json',
        success_codes: [200, 201, 202]
      )
    end
  end

  describe '#chunked_upload_get_session' do
    before do
      allow(client).to receive(:get).and_return([mock_session_info, mock_response])
    end

    it 'retrieves session by ID' do
      result = client.chunked_upload_get_session('session_123')
      expect(result).to eq(mock_session_info)
    end

    it 'calls get with correct URI' do
      client.chunked_upload_get_session('session_123')
      expect(client).to have_received(:get).with("#{Boxr::Client::UPLOAD_URI}/files/upload_sessions/session_123")
    end
  end

  describe '#chunked_upload_list_parts' do
    before do
      allow(client).to receive(:get).and_return([mock_parts_response, mock_response])
    end

    it 'lists parts without parameters' do
      result = client.chunked_upload_list_parts('session_123')
      expect(result).to eq([])
    end

    it 'lists parts with limit' do
      result = client.chunked_upload_list_parts('session_123', limit: 10)
      expect(result).to eq([])
    end

    it 'lists parts with offset' do
      result = client.chunked_upload_list_parts('session_123', offset: 5)
      expect(result).to eq([])
    end

    it 'lists parts with both limit and offset' do
      result = client.chunked_upload_list_parts('session_123', limit: 10, offset: 5)
      expect(result).to eq([])
    end

    it 'calls get with correct parameters' do
      client.chunked_upload_list_parts('session_123', limit: 10, offset: 5)
      expect(client).to have_received(:get).with(
        "#{Boxr::Client::UPLOAD_URI}/files/upload_sessions/session_123/parts",
        query: { limit: 10, offset: 5 }
      )
    end
  end

  describe '#chunked_upload_abort_session' do
    before do
      allow(client).to receive(:delete).and_return([{}, mock_response])
    end

    it 'aborts session' do
      result = client.chunked_upload_abort_session('session_123')
      expect(result).to eq({})
    end

    it 'calls delete with correct URI' do
      client.chunked_upload_abort_session('session_123')
      expect(client).to have_received(:delete).with("#{Boxr::Client::UPLOAD_URI}/files/upload_sessions/session_123")
    end
  end

  describe '#chunked_upload_part' do
    before do
      setup_file_io_stubs
      allow(client).to receive(:chunked_upload_part_from_io).and_return('part_info')
    end

    it 'uploads part from file path' do
      result = client.chunked_upload_part(file_path, 'session_123', 0..1023)
      expect(result).to eq('part_info')
    end

    it 'calls chunked_upload_part_from_io with correct parameters' do
      client.chunked_upload_part(file_path, 'session_123', 0..1023)
      expect(client).to have_received(:chunked_upload_part_from_io).with(file_io, 'session_123',
                                                                         0..1023)
    end
  end

  describe '#chunked_upload_part_from_io' do
    let(:content_range) { 0..1023 }
    let(:part_data) { 'part content' }
    let(:mock_part_response) { instance_double(HTTP::Message, status: 200) }
    let(:mock_part_info) { BoxrMash.new(part: 'part_info') }

    before do
      allow(file_io).to receive(:pos=).with(0)
      allow(file_io).to receive(:read).with(1024).and_return(part_data)
      allow(file_io).to receive(:rewind)
      allow(Digest::SHA1).to receive(:base64digest).with(part_data).and_return('hash')
      allow(client).to receive(:put).and_return([mock_part_info, mock_part_response])
    end

    it 'uploads part from IO' do
      result = client.chunked_upload_part_from_io(file_io, 'session_123', content_range)
      expect(result).to eq('part_info')
    end

    it 'calls put with correct parameters' do
      client.chunked_upload_part_from_io(file_io, 'session_123', content_range)
      expect(client).to have_received(:put).with(
        "#{Boxr::Client::UPLOAD_URI}/files/upload_sessions/session_123",
        part_data,
        process_body: false,
        digest: 'sha=hash',
        content_type: 'application/octet-stream',
        content_range: 'bytes 0-1023/16777216',
        success_codes: [200, 201, 202]
      )
    end
  end

  describe '#chunked_upload_commit' do
    before do
      setup_file_io_stubs
      allow(client).to receive(:chunked_upload_commit_from_io).and_return(mock_file_info)
    end

    it 'commits upload from file path' do
      result = client.chunked_upload_commit(file_path, 'session_123', [])
      expect(result).to eq(mock_file_info)
    end

    it 'commits with content timestamps' do
      result = client.chunked_upload_commit(file_path, 'session_123', [],
                                            content_created_at: Time.now,
                                            content_modified_at: Time.now)
      expect(result).to eq(mock_file_info)
    end

    it 'commits with if_match' do
      result = client.chunked_upload_commit(file_path, 'session_123', [], if_match: 'etag')
      expect(result).to eq(mock_file_info)
    end

    it 'calls chunked_upload_commit_from_io with correct parameters' do
      client.chunked_upload_commit(file_path, 'session_123', [])
      expect(client).to have_received(:chunked_upload_commit_from_io).with(
        file_io, 'session_123', [], content_created_at: nil, content_modified_at: nil, if_match: nil, if_non_match: nil
      )
    end
  end

  describe '#chunked_upload_commit_from_io' do
    let(:parts) { %w[part1 part2] }
    let(:created_at) { Time.now }
    let(:modified_at) { Time.now }

    before do
      allow(file_io).to receive(:pos=).with(0)
      allow(file_io).to receive(:read).with(8 * 1024**2).and_return('chunk1', 'chunk2', nil)
      allow(file_io).to receive(:rewind)
      allow(Digest::SHA1).to receive(:new).and_return(
        instance_double(Digest::SHA1, update: nil, base64digest: 'hash')
      )
      allow(client).to receive(:post).and_return([mock_commit_info, mock_commit_response])
      allow(mock_commit_info).to receive(:entries).and_return([test_file])
    end

    it 'commits upload from IO' do
      result = client.chunked_upload_commit_from_io(file_io, 'session_123', parts)
      expect(result).to eq(mock_commit_info)
    end

    it 'commits with content timestamps' do
      result = client.chunked_upload_commit_from_io(file_io, 'session_123', parts,
                                                    content_created_at: created_at,
                                                    content_modified_at: modified_at)
      expect(result).to eq(mock_commit_info)
    end

    it 'commits with if_match' do
      result = client.chunked_upload_commit_from_io(file_io, 'session_123', parts, if_match: 'etag')
      expect(result).to eq(mock_commit_info)
    end

    it 'calls post with correct parameters' do
      client.chunked_upload_commit_from_io(file_io, 'session_123', parts)
      expect(client).to have_received(:post).with(
        "#{Boxr::Client::UPLOAD_URI}/files/upload_sessions/session_123/commit",
        { parts: parts, attributes: {} },
        process_body: true,
        digest: 'sha=hash',
        content_type: 'application/json',
        if_match: nil,
        if_non_match: nil,
        success_codes: [200, 201, 202]
      )
    end
  end

  describe '#chunked_upload_file' do
    before do
      setup_file_io_stubs
      allow(client).to receive(:chunked_upload_file_from_io).and_return(mock_file_info)
    end

    it 'uploads file in chunks' do
      result = client.chunked_upload_file(file_path, test_folder)
      expect(result).to eq(mock_file_info)
    end

    it 'uploads file with custom name' do
      result = client.chunked_upload_file(file_path, test_folder, name: 'custom.txt')
      expect(result).to eq(mock_file_info)
    end

    it 'uploads file with content timestamps' do
      created_at = Time.now
      modified_at = Time.now
      result = client.chunked_upload_file(file_path, test_folder,
                                          content_created_at: created_at,
                                          content_modified_at: modified_at)
      expect(result).to eq(mock_file_info)
    end

    it 'uploads file with custom thread count' do
      result = client.chunked_upload_file(file_path, test_folder, n_threads: 4)
      expect(result).to eq(mock_file_info)
    end

    it 'calls chunked_upload_file_from_io with correct parameters' do
      client.chunked_upload_file(file_path, test_folder, name: 'custom.txt')
      expect(client).to have_received(:chunked_upload_file_from_io).with(
        file_io, test_folder, 'custom.txt', n_threads: 1, content_created_at: nil, content_modified_at: nil
      )
    end
  end

  describe '#chunked_upload_file_from_io' do
    before do
      allow(client).to receive_messages(
        chunked_upload_create_session_new_file_from_io: mock_session_info, chunked_upload_to_session_from_io: mock_file_info
      )
      allow(client).to receive(:chunked_upload_abort_session)
    end

    it 'uploads file from IO' do
      result = client.chunked_upload_file_from_io(file_io, test_folder, 'test.txt')
      expect(result).to eq(mock_file_info)
    end

    it 'uploads file with custom thread count' do
      result = client.chunked_upload_file_from_io(file_io, test_folder, 'test.txt', n_threads: 4)
      expect(result).to eq(mock_file_info)
    end

    it 'calls chunked_upload_create_session_new_file_from_io' do
      client.chunked_upload_file_from_io(file_io, test_folder, 'test.txt')
      expect(client).to have_received(:chunked_upload_create_session_new_file_from_io).with(
        file_io, test_folder, 'test.txt'
      )
    end

    it 'calls chunked_upload_to_session_from_io' do
      client.chunked_upload_file_from_io(file_io, test_folder, 'test.txt')
      expect(client).to have_received(:chunked_upload_to_session_from_io).with(
        file_io, mock_session_info, n_threads: 1, content_created_at: nil, content_modified_at: nil
      )
    end
  end

  describe '#chunked_upload_new_version_of_file' do
    before do
      setup_file_io_stubs
      allow(client).to receive(:chunked_upload_new_version_of_file_from_io).and_return(mock_file_info)
    end

    it 'uploads new version in chunks' do
      result = client.chunked_upload_new_version_of_file(file_path, test_file)
      expect(result).to eq(mock_file_info)
    end

    it 'uploads new version with custom name' do
      result = client.chunked_upload_new_version_of_file(file_path, test_file, name: 'custom.txt')
      expect(result).to eq(mock_file_info)
    end

    it 'uploads new version with content timestamps' do
      created_at = Time.now
      modified_at = Time.now
      result = client.chunked_upload_new_version_of_file(file_path, test_file,
                                                         content_created_at: created_at,
                                                         content_modified_at: modified_at)
      expect(result).to eq(mock_file_info)
    end

    it 'uploads new version with custom thread count' do
      result = client.chunked_upload_new_version_of_file(file_path, test_file, n_threads: 4)
      expect(result).to eq(mock_file_info)
    end

    it 'calls chunked_upload_new_version_of_file_from_io with correct parameters' do
      client.chunked_upload_new_version_of_file(file_path, test_file, name: 'custom.txt')
      expect(client).to have_received(:chunked_upload_new_version_of_file_from_io).with(
        file_io, test_file, 'custom.txt', n_threads: 1, content_created_at: nil, content_modified_at: nil
      )
    end
  end

  describe '#chunked_upload_new_version_of_file_from_io' do
    before do
      allow(client).to receive_messages(
        chunked_upload_create_session_new_version_from_io: mock_session_info, chunked_upload_to_session_from_io: mock_file_info
      )
      allow(client).to receive(:chunked_upload_abort_session)
    end

    it 'uploads new version from IO' do
      result = client.chunked_upload_new_version_of_file_from_io(file_io, test_file, 'test.txt')
      expect(result).to eq(mock_file_info)
    end

    it 'uploads new version with custom thread count' do
      result = client.chunked_upload_new_version_of_file_from_io(file_io, test_file, 'test.txt',
                                                                 n_threads: 4)
      expect(result).to eq(mock_file_info)
    end

    it 'calls chunked_upload_create_session_new_version_from_io' do
      client.chunked_upload_new_version_of_file_from_io(file_io, test_file, 'test.txt')
      expect(client).to have_received(:chunked_upload_create_session_new_version_from_io).with(
        file_io, test_file, 'test.txt'
      )
    end

    it 'calls chunked_upload_to_session_from_io' do
      client.chunked_upload_new_version_of_file_from_io(file_io, test_file, 'test.txt')
      expect(client).to have_received(:chunked_upload_to_session_from_io).with(
        file_io, mock_session_info, n_threads: 1, content_created_at: nil, content_modified_at: nil
      )
    end
  end

  describe 'private methods' do
    describe '#chunked_upload_to_session_from_io' do
      let(:content_ranges) { [0..8_388_607, 8_388_608..16_777_215] }
      let(:parts) { %w[part1 part2] }

      before do
        allow(client).to receive(:chunked_upload_commit_from_io).and_return(mock_commit_info)
      end

      it 'uploads file in single thread' do
        allow(client).to receive(:chunked_upload_part_from_io).and_return('part1', 'part2')
        result = client.send(:chunked_upload_to_session_from_io, file_io, mock_session_info)
        expect(result).to eq(test_file)
      end

      it 'calls chunked_upload_commit_from_io with correct parameters' do
        allow(client).to receive(:chunked_upload_part_from_io).and_return('part1', 'part2')
        client.send(:chunked_upload_to_session_from_io, file_io, mock_session_info)
        expect(client).to have_received(:chunked_upload_commit_from_io).with(
          file_io, 'session_123', parts, content_created_at: nil, content_modified_at: nil
        )
      end

      context 'when upload fails' do
        before do
          allow(client).to receive(:chunked_upload_part_from_io).and_return('part1', 'part2')
          allow(client).to receive(:chunked_upload_commit_from_io).and_raise(Boxr::BoxrError)
          allow(client).to receive(:chunked_upload_abort_session)
        end

        it 'aborts session on failure' do
          expect do
            client.send(:chunked_upload_to_session_from_io, file_io, mock_session_info)
          end.to raise_error(Boxr::BoxrError)
          expect(client).to have_received(:chunked_upload_abort_session).with('session_123')
        end
      end

      context 'with multiple threads' do
        before do
          allow(client).to receive(:gem_parallel_available?).and_return(true)
          stub_const('Parallel', double('Parallel'))
          allow(Parallel).to receive(:map).and_return(parts)
        end

        it 'uploads file in parallel when parallel gem is available' do
          result = client.send(:chunked_upload_to_session_from_io, file_io, mock_session_info,
                               n_threads: 2)
          expect(result).to eq(test_file)
        end

        it 'raises error when parallel gem is not available' do
          allow(client).to receive(:gem_parallel_available?).and_return(false)
          expect do
            client.send(:chunked_upload_to_session_from_io, file_io, mock_session_info,
                        n_threads: 2)
          end.to raise_error(Boxr::BoxrError, /parallel chunked uploads requires gem 'parallel'/)
        end
      end
    end

    describe '#gem_parallel_available?' do
      it 'returns false when parallel gem is not loaded' do
        allow(Gem).to receive(:loaded_specs).and_return({})
        result = client.send(:gem_parallel_available?)
        expect(result).to be false
      end

      it 'returns false when parallel gem version is incompatible' do
        allow(Gem).to receive(:loaded_specs).and_return({ 'parallel' => double(version: Gem::Version.new('0.9.0')) })
        result = client.send(:gem_parallel_available?)
        expect(result).to be false
      end
    end
  end
end

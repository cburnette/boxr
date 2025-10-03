# frozen_string_literal: true

module Boxr
  class Client
    def chunked_upload_create_session_new_file(path_to_file, parent, name: nil)
      filename = name || File.basename(path_to_file)

      File.open(path_to_file) do |file|
        chunked_upload_create_session_new_file_from_io(file, parent, filename)
      end
    end

    def chunked_upload_create_session_new_file_from_io(io, parent, name)
      parent_id = ensure_id(parent)

      uri = "#{UPLOAD_URI}/files/upload_sessions"
      body = { folder_id: parent_id, file_size: io.size, file_name: name }
      session_info, = post(uri, body, content_type: 'application/json',
                                      success_codes: [200, 201, 202])
      session_info
    end

    def chunked_upload_create_session_new_version(path_to_file, file, name: nil)
      filename = name || File.basename(path_to_file)

      File.open(path_to_file) do |io|
        chunked_upload_create_session_new_version_from_io(io, file, filename)
      end
    end

    def chunked_upload_create_session_new_version_from_io(io, file, name)
      file_id = ensure_id(file)
      uri = "#{UPLOAD_URI}/files/#{file_id}/upload_sessions"
      body = { file_size: io.size, file_name: name }
      session_info, = post(uri, body, content_type: 'application/json',
                                      success_codes: [200, 201, 202])
      session_info
    end

    def chunked_upload_get_session(session_id)
      uri = "#{UPLOAD_URI}/files/upload_sessions/#{session_id}"
      session_info, = get(uri)
      session_info
    end

    def chunked_upload_part(path_to_file, session_id, content_range)
      File.open(path_to_file) do |file|
        chunked_upload_part_from_io(file, session_id, content_range)
      end
    end

    def chunked_upload_part_from_io(io, session_id, content_range) # rubocop:disable Metrics
      io.pos = content_range.min
      part_size = content_range.max - content_range.min + 1
      body = io.read(part_size)
      io.rewind

      digest = "sha=#{Digest::SHA1.base64digest(body)}"
      range = "bytes #{content_range.min}-#{content_range.max}/#{io.size}"

      uri = "#{UPLOAD_URI}/files/upload_sessions/#{session_id}"
      part_info, = put(
        uri, body, process_body: false, digest: digest, content_type: 'application/octet-stream',
                   content_range: range, success_codes: [200, 201, 202]
      )
      part_info.part
    end

    def chunked_upload_list_parts(session_id, limit: nil, offset: nil)
      uri = "#{UPLOAD_URI}/files/upload_sessions/#{session_id}/parts"
      query = {}
      query[:limit] = limit unless limit.nil?
      query[:offset] = offset unless offset.nil?
      parts_info, = get(uri, query: query)
      parts_info.entries
    end

    def chunked_upload_commit(path_to_file, session_id, parts, content_created_at: nil, # rubocop:disable Metrics
                              content_modified_at: nil, if_match: nil, if_non_match: nil)
      File.open(path_to_file) do |file|
        chunked_upload_commit_from_io(
          file, session_id, parts,
          content_created_at: content_created_at, content_modified_at: content_modified_at,
          if_match: if_match, if_non_match: if_non_match
        )
      end
    end

    def chunked_upload_commit_from_io(io, session_id, parts, content_created_at: nil, # rubocop:disable Metrics
                                      content_modified_at: nil, if_match: nil, if_non_match: nil)
      io.pos = 0
      cca = content_created_at
      cma = content_modified_at
      digest = "sha=#{calculate_chunked_upload_digest(io).base64digest}"

      attributes = {}
      attributes[:content_created_at] = cca.to_datetime.rfc3339 if cca
      attributes[:content_modified_at] = cma.to_datetime.rfc3339 if cma

      uri = "#{UPLOAD_URI}/files/upload_sessions/#{session_id}/commit"
      body = { parts: parts, attributes: attributes }

      loop do
        commit_info, response = post(
          uri, body,
          process_body: true, digest: digest, content_type: 'application/json',
          if_match: if_match, if_non_match: if_non_match, success_codes: [200, 201, 202]
        )
        return commit_info if response.status != 202

        sleep response.header['Retry-After'][0].to_i
      end
    end

    def chunked_upload_abort_session(session_id)
      uri = "#{UPLOAD_URI}/files/upload_sessions/#{session_id}"
      abort_info, = delete(uri)
      abort_info
    rescue BoxrError # Ignore errors from aborting session
      nil
    end

    def chunked_upload_file(path_to_file, parent, name: nil, n_threads: 1, # rubocop:disable Metrics
                            content_created_at: nil, content_modified_at: nil)
      filename = name || File.basename(path_to_file)

      File.open(path_to_file) do |file|
        chunked_upload_file_from_io(
          file, parent, filename,
          n_threads: n_threads, content_created_at: content_created_at,
          content_modified_at: content_modified_at
        )
      end
    end

    def chunked_upload_file_from_io(io, parent, name, n_threads: 1, # rubocop:disable Metrics
                                    content_created_at: nil, content_modified_at: nil)
      session = chunked_upload_create_session_new_file_from_io(io, parent, name)
      chunked_upload_to_session_from_io(
        io, session,
        n_threads: n_threads, content_created_at: content_created_at,
        content_modified_at: content_modified_at
      )
    end

    def chunked_upload_new_version_of_file(path_to_file, file, name: nil, n_threads: 1, # rubocop:disable Metrics
                                           content_created_at: nil, content_modified_at: nil)
      filename = name || File.basename(path_to_file)

      File.open(path_to_file) do |io|
        chunked_upload_new_version_of_file_from_io(
          io, file, filename,
          n_threads: n_threads, content_created_at: content_created_at,
          content_modified_at: content_modified_at
        )
      end
    end

    def chunked_upload_new_version_of_file_from_io( # rubocop:disable Metrics
      io, file, name, n_threads: 1, content_created_at: nil, content_modified_at: nil
    )
      session = chunked_upload_create_session_new_version_from_io(io, file, name)
      chunked_upload_to_session_from_io(
        io, session,
        n_threads: n_threads, content_created_at: content_created_at,
        content_modified_at: content_modified_at
      )
    end

    private

    PARALLEL_GEM_REQUIREMENT = Gem::Requirement.create('~> 1.0').freeze

    def chunked_upload_to_session_from_io(io, session, n_threads: 1, # rubocop:disable Metrics
                                          content_created_at: nil, content_modified_at: nil)
      content_ranges = []
      start_offset = 0
      part_size = session.part_size
      file_size = io.size
      commit_info = nil

      while start_offset < file_size
        end_offset = [start_offset + part_size, file_size].min - 1
        content_ranges << (start_offset..end_offset)
        start_offset += part_size
      end

      parts =
        if n_threads > 1
          threaded_chunked_upload_part_from_io(io, session.id, content_ranges, n_threads)
        else
          # Single thread
          content_ranges.map do |content_range|
            chunked_upload_part_from_io(io, session.id, content_range)
          end
        end

      commit_info = chunked_upload_commit_from_io(
        io, session.id, parts,
        content_created_at: content_created_at, content_modified_at: content_modified_at
      )
      commit_info.entries[0]
    ensure
      chunked_upload_abort_session(session.id) if commit_info.nil? && session
    end

    def threaded_chunked_upload_part_from_io(io, session_id, content_ranges, n_threads)
      unless gem_parallel_available?
        msg = "parallel chunked uploads requires gem 'parallel'"
        raise BoxrError.new(boxr_message: msg)
      end

      Parallel.map(content_ranges, in_threads: n_threads) do |content_range|
        File.open(io.path) do |io_dup|
          chunked_upload_part_from_io(io_dup, session_id, content_range)
        end
      end
    end

    def calculate_chunked_upload_digest(io)
      digest = Digest::SHA1.new
      while (buf = io.read(8 * 1024**2)) && buf.size.positive?
        digest.update(buf)
      end
      io.rewind
      digest
    end

    def gem_parallel_available?
      gem_spec = Gem.loaded_specs['parallel']
      return false if gem_spec.nil?

      PARALLEL_GEM_REQUIREMENT.satisfied_by?(gem_spec.version) && defined?(Parallel)
    end
  end
end

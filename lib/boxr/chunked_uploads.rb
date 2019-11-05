module Boxr
  class Client

    def chunked_upload_create_session_new_file(path_to_file, parent, name: nil)
      filename = name ? name : File.basename(path_to_file)

      File.open(path_to_file) do |file|
        chunked_upload_create_session_new_file_from_io(file, parent, filename)
      end
    end

    def chunked_upload_create_session_new_file_from_io(io, parent, name)
      parent_id = ensure_id(parent)

      uri = "#{UPLOAD_URI}/files/upload_sessions"
      body = {folder_id: parent_id, file_size: io.size, file_name: name}
      session_info, response = post(uri, body, content_type: "application/json")

      session_info
    end

    def chunked_upload_create_session_new_version(path_to_file, file, name: nil)
      filename = name ? name : File.basename(path_to_file)

      File.open(path_to_file) do |io|
        chunked_upload_create_session_new_version_from_io(io, file, filename)
      end
    end

    def chunked_upload_create_session_new_version_from_io(io, file, name)
      file_id = ensure_id(file)
      uri = "#{UPLOAD_URI}/files/#{file_id}/upload_sessions"
      body = {file_size: io.size, file_name: name}
      session_info, response = post(uri, body, content_type: "application/json")

      session_info
    end

    def chunked_upload_get_session(session_id)
      uri = "#{UPLOAD_URI}/files/upload_sessions/#{session_id}"
      session_info, response = get(uri)

      session_info
    end

    def chunked_upload_part(path_to_file, session_id, content_range)
      File.open(path_to_file) do |file|
        chunked_upload_part_from_io(file, session_id, content_range)
      end
    end

    def chunked_upload_part_from_io(io, session_id, content_range)
      io.pos = content_range.min
      part_size = content_range.max - content_range.min + 1
      data = io.read(part_size)
      io.rewind

      digest = "sha=#{Digest::SHA1.base64digest(data)}"
      range = "bytes #{content_range.min}-#{content_range.max}/#{io.size}"

      uri = "#{UPLOAD_URI}/files/upload_sessions/#{session_id}"
      body = data
      part_info, response = put(uri, body, process_body: false, digest: digest, content_type: "application/octet-stream", content_range: range)

      part_info.part
    end

    def chunked_upload_list_parts(session_id, limit: nil, offset: nil)
      uri = "#{UPLOAD_URI}/files/upload_sessions/#{session_id}/parts"
      query = {}
      query[:limit] = limit unless limit.nil?
      query[:offset] = offset unless offset.nil?
      parts_info, response = get(uri, query: query)

      parts_info.entries
    end

    def chunked_upload_commit(path_to_file, session_id, parts, content_created_at: nil, content_modified_at: nil, if_match: nil, if_non_match: nil)
      File.open(path_to_file) do |file|
        chunked_upload_commit_from_io(file, session_id, parts, content_created_at: content_created_at, content_modified_at: content_modified_at, if_match: if_match, if_non_match: if_non_match)
      end
    end

    def chunked_upload_commit_from_io(io, session_id, parts, content_created_at: nil, content_modified_at: nil, if_match: nil, if_non_match: nil)
      io.pos = 0
      digest = Digest::SHA1.new
      while (buf = io.read(8 * 1024**2)) && buf.size > 0
        digest.update(buf)
      end
      io.rewind
      digest = "sha=#{digest.base64digest}"

      attributes = {}
      attributes[:content_created_at] = content_created_at.to_datetime.rfc3339 unless content_created_at.nil?
      attributes[:content_modified_at] = content_modified_at.to_datetime.rfc3339 unless content_modified_at.nil?

      uri = "#{UPLOAD_URI}/files/upload_sessions/#{session_id}/commit"
      body = {
        parts: parts,
        attributes: attributes
      }
      commit_info, response = post(uri, body, process_body: true, digest: digest, content_type: "application/json", if_match: if_match, if_non_match: if_non_match)

      commit_info
    end

    def chunked_upload_abort_session(session_id)
      uri = "#{UPLOAD_URI}/files/upload_sessions/#{session_id}"
      abort_info, response = delete(uri)

      abort_info
    end

    def chunked_upload_file(path_to_file, parent, name: nil, n_threads: 1, content_created_at: nil, content_modified_at: nil)
      filename = name ? name : File.basename(path_to_file)

      File.open(path_to_file) do |file|
        chunked_upload_file_from_io(file, parent, filename, n_threads: n_threads, content_created_at: content_created_at, content_modified_at: content_modified_at)
      end
    end

    def chunked_upload_file_from_io(io, parent, name, n_threads: 1, content_created_at: nil, content_modified_at: nil)
      session = nil
      file_info = nil

      session = chunked_upload_create_session_new_file_from_io(io, parent, name)

      file_info = chunked_upload_to_session_from_io(io, session, n_threads: n_threads, content_created_at: nil, content_modified_at: nil)
      file_info
    ensure
      chunked_upload_abort_session(session.id) if file_info.nil? && !session.nil?
    end

    def chunked_upload_new_version_of_file(path_to_file, file, name: nil, n_threads: 1, content_created_at: nil, content_modified_at: nil)
      filename = name ? name : File.basename(path_to_file)

      File.open(path_to_file) do |io|
        chunked_upload_new_version_of_file_from_io(io, file, filename, n_threads: n_threads, content_created_at: content_created_at, content_modified_at: content_modified_at)
      end
    end

    def chunked_upload_new_version_of_file_from_io(io, file, name, n_threads: 1, content_created_at: nil, content_modified_at: nil)
      session = nil
      file_info = nil

      session = chunked_upload_create_session_new_version_from_io(io, file, name)

      file_info = chunked_upload_to_session_from_io(io, session, n_threads: n_threads, content_created_at: nil, content_modified_at: nil)
      file_info
    ensure
      chunked_upload_abort_session(session.id) if file_info.nil? && !session.nil?
    end

    private

    PARALLEL_GEM_REQUIREMENT = Gem::Requirement.create('~> 1.0').freeze

    def chunked_upload_to_session_from_io(io, session, n_threads: 1, content_created_at: nil, content_modified_at: nil)
      content_ranges = []
      offset = 0
      loop do
        limit = [offset + session.part_size, io.size].min - 1
        content_ranges << (offset..limit)
        break if limit == io.size - 1

        offset = limit + 1
      end

      parts =
        if n_threads > 1
          raise BoxrError.new(boxr_message: "parallel chunked uploads requires gem parallel (#{PARALLEL_GEM_REQUIREMENT}) to be loaded") unless gem_parallel_available?

          Parallel.map(content_ranges, in_threads: n_threads) do |content_range|
            File.open(io.path) do |io_dup|
              chunked_upload_part_from_io(io_dup, session.id, content_range)
            end
          end
        else
          content_ranges.map do |content_range|
            chunked_upload_part_from_io(io, session.id, content_range)
          end
        end

      commit_info = chunked_upload_commit_from_io(io, session.id, parts,
                                                  content_created_at: content_created_at, content_modified_at: content_modified_at)
      commit_info.entries[0]
    end

    def gem_parallel_available?
      gem_spec  = Gem.loaded_specs['parallel']
      return false if gem_spec.nil?

      PARALLEL_GEM_REQUIREMENT.satisfied_by?(gem_spec.version) && defined?(Parallel)
    end

  end
end

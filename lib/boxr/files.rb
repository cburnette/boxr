module Boxr
	class Client

		def file_id(path)
			if(path.start_with?('/'))
				path = path.slice(1..-1)
			end

			path_items = path.split('/')
			file_name = path_items.slice!(-1)

			folder_id = folder_id(path_items.join('/'))

			files = folder_items(folder_id, fields: [:id, :name])

			begin
				files.select{|f| f.name == file_name}.first.id
			rescue
				raise BoxrException.new(boxr_message: "File not found: '#{file_name}'")
			end
		end

		def file(file_id, fields: [])
			uri = "#{FILES_URI}/#{file_id}"
			query = build_fields_query(fields, FOLDER_AND_FILE_FIELDS_QUERY)
			file, response = get uri, query: query
			file
		end

		def update_file(file_id, name: nil, description: nil, parent_id: nil, shared_link: nil, tags: nil, if_match: nil)
			uri = "#{FILES_URI}/#{file_id}"

			attributes = {}
			attributes[:name] = name unless name.nil?
			attributes[:description] = description unless description.nil?
			attributes[:parent_id] = {id: parent_id} unless parent_id.nil?
			attributes[:shared_link] = shared_link unless shared_link.nil?
			attributes[:tags] = tags unless tags.nil? 

			updated_file, response = put uri, attributes, if_match: if_match
			updated_file
		end

		def download_file(file_id, version: nil, follow_redirect: true)
			begin
				uri = "#{FILES_URI}/#{file_id}/content"
				query = {}
				query[:version] = version unless version.nil?
				body_json, response = get uri, query: query, success_codes: [302,202]

				if(response.status==302)
					location = response.header['Location'][0]

					if(follow_redirect)
						file, response = get location, process_response: false
					else
						return location #simply return the url
					end
				elsif(response.status==202)
					retry_after_seconds = response.header['Retry-After'][0]
					sleep retry_after_seconds.to_i
				end
			end until file

			file
		end

		def download_url(file_id, version: nil)
			download_file(file_id, version: version, follow_redirect: false)
		end

		def upload_file(path_to_file, parent_id, content_created_at: nil, content_modified_at: nil, 
										preflight_check: true, send_content_md5: true)

			preflight_check(path_to_file, parent_id) if preflight_check

			file_info = nil
			response = nil

			File.open(path_to_file) do |file|
				content_md5 = send_content_md5 ? Digest::SHA1.file(file).hexdigest : nil
				attributes = {filename: file, parent_id: parent_id}
				attributes[:content_created_at] = content_created_at.to_datetime.rfc3339 unless content_created_at.nil?
				attributes[:content_modified_at] = content_modified_at.to_datetime.rfc3339 unless content_modified_at.nil?
				file_info, response = post FILES_UPLOAD_URI, attributes, process_body: false, content_md5: content_md5
			end

			file_info["entries"][0]
		end

		def delete_file(file_id, if_match: nil)
			uri = "#{FILES_URI}/#{file_id}"
			result, response = delete uri, if_match: if_match
			result
		end

		def upload_new_version_of_file(path_to_file, file_id, content_modified_at: nil, send_content_md5: true, 
																		preflight_check: true, if_match: nil)

			preflight_check_new_version_of_file(path_to_file, file_id) if preflight_check

			uri = "#{UPLOAD_URI}/files/#{file_id}/content"
			file_info = nil
			response = nil

			File.open(path_to_file) do |file|
				content_md5 = send_content_md5 ? Digest::SHA1.file(file).hexdigest : nil
				attributes = {filename: file}
				attributes[:content_modified_at] = content_modified_at.to_datetime.rfc3339 unless content_modified_at.nil?
				file_info, response = post uri, attributes, process_body: false, content_md5: content_md5, if_match: if_match
			end

			file_info["entries"][0]
		end

		def versions_of_file(file_id)
			uri = "#{FILES_URI}/#{file_id}/versions"
			versions, response = get uri
			versions["entries"]
		end

		def promote_old_version_of_file(file_id, file_version_id)
			uri = "#{FILES_URI}/#{file_id}/versions/current"
			attributes = {:type => 'file_version', :id => file_version_id}
			new_version, res = post uri, attributes
			new_version
		end

		def delete_old_version_of_file(file_id, file_version_id, if_match: nil)
			uri = "#{FILES_URI}/#{file_id}/versions/#{file_version_id}"
			result, response = delete uri, if_match: if_match
			result
		end

		def copy_file(file_id, parent_id, name: nil)
			uri = "#{FILES_URI}/#{file_id}/copy"
			attributes = {:parent => {:id => parent_id}}
			attributes[:name] = name unless name.nil?
			new_file, res = post uri, attributes
			new_file
		end

		def thumbnail(file_id, min_height: nil, min_width: nil, max_height: nil, max_width: nil)
			uri = "#{FILES_URI}/#{file_id}/thumbnail.png"
			query = {}
			query[:min_height] = min_height unless min_height.nil?
			query[:min_width] = min_width unless min_width.nil?
			query[:max_height] = max_height unless max_height.nil?
			query[:max_width] = max_width unless max_width.nil?
			body, response = get uri, query: query, success_codes: [302,202,200], process_response: false

			if(response.status==202 || response.status==302)
				location = response.header['Location'][0]
				thumbnail, response = get location, process_response: false
			else #200
				thumbnail = body
			end

			thumbnail
		end

		def create_shared_link_for_file(file_id, access: nil, unshared_at: nil, can_download: nil, can_preview: nil)
			uri = "#{FILES_URI}/#{file_id}"
			create_shared_link(uri, file_id, access, unshared_at, can_download, can_preview)
		end

		def disable_shared_link_for_file(file_id)
			uri = "#{FILES_URI}/#{file_id}"
			disable_shared_link(uri, file_id)
		end

		def trashed_file(file_id, fields: [])
			uri = "#{FILES_URI}/#{file_id}/trash"
			query = build_fields_query(fields, FOLDER_AND_FILE_FIELDS_QUERY)

			trashed_file, response = get uri, query: query
			trashed_file
		end

		def delete_trashed_file(file_id)
			uri = "#{FILES_URI}/#{file_id}/trash"

			result, response = delete uri
			result
		end

		def restore_trashed_file(file_id, name: nil, parent_id: nil)
			uri = "#{FILES_URI}/#{file_id}"
			restore_trashed_item(uri, name, parent_id)
		end


		private

		def preflight_check(path_to_file, parent_id)
			size = File.size(path_to_file)
			
			#TODO: need to make sure that figuring out the filename from the path_to_file works for people using Winblows
			filename = File.basename(path_to_file)
			attributes = {"name" => filename, "parent" => {"id" => "#{parent_id}"}, "size" => size}
			body_json, res = options "#{FILES_URI}/content", attributes
		end

		def preflight_check_new_version_of_file(path_to_file, file_id)
			size = File.size(path_to_file)
			attributes = {"size" => size}
			body_json, res = options "#{FILES_URI}/#{file_id}/content", attributes
		end

	end
end
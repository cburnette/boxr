module Boxr

	class BoxrException < Exception

		attr_reader :response_body, :type, :status, :code, :help_uri, :box_message, :request_id

		def initialize(status,body,header)
			@status = status
			@response_body = body
			@header = header

			body_json = Oj.load(body)
			if body_json
				@type = body_json["type"]
				@box_status = body_json["status"]
				@code = body_json["code"]
				@help_uri = body_json["help_uri"]
				@box_message = body_json["message"]
				@request_id = body_json["request_id"]
			end
		end

		def message
			auth_header = @header['WWW-Authenticate']
			if(auth_header && auth_header != [])
				"#{@status}: #{auth_header}"
			elsif(@box_message)
				"#{@status}: #{@box_message}"
			else
				"#{@status}: #{@response_body}"
			end
		end

		def to_s
			message
		end
	end

end
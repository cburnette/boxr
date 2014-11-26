module Boxr

	class BoxException < Exception

		attr_reader :response_body, :type, :status, :code, :help_uri, :message, :request_id

		def initialize(status,body)
			@status = status
			@response_body = body

			body_json = Oj.load(body)
			if body_json
				@type = body_json["type"]
				@box_status = body_json["status"]
				@code = body_json["code"]
				@help_uri = body_json["help_uri"]
				@message = body_json["message"]
				@request_id = body_json["request_id"]
			else
				@message = status
			end
		end

		def to_s
			p @message
		end
	end

end
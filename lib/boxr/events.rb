module Boxr
	class Client

		def user_events(stream_position: 0, stream_type: :all, limit: 100)
			query = {stream_position: stream_position, stream_type: stream_type, limit: limit}
			
			events, response = get(EVENTS_URI, query: query)
			Hashie::Mash.new({events: events["entries"], chunk_size: events["chunk_size"], next_stream_position: events["next_stream_position"]})
		end

		def enterprise_events(stream_position: 0, limit: 100, event_type: nil, created_after: nil, created_before: nil)
			query = {stream_position: stream_position, stream_type: :admin_logs, limit: limit}
			query['event_type'] = event_type unless event_type.nil?
			query['created_after'] = created_after.to_datetime.rfc3339 unless created_after.nil?
			query['created_before'] = created_before.to_datetime.rfc3339 unless created_before.nil?

			events, response = get(EVENTS_URI, query: query)
			Hashie::Mash.new({events: events["entries"], chunk_size: events["chunk_size"], next_stream_position: events["next_stream_position"]})
		end

	end
end
module Boxr
	class Client

		def user_events(stream_position: 0, stream_type: :all, limit: 100)
			query = {stream_position: stream_position, stream_type: stream_type, limit: limit}
			events, response = get(EVENTS_URI, query: query)
			Hashie::Mash.new({entries: events["entries"], chunk_size: events["chunk_size"], next_stream_position: events["next_stream_position"]})
		end

	end
end
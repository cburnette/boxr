module Boxr
  class Client

    def user_events(stream_position: 0, stream_type: :all, limit: 100)
      query = {stream_position: stream_position, stream_type: stream_type, limit: limit}
      
      events, response = get(EVENTS_URI, query: query)
      Hashie::Mash.new({events: events["entries"], chunk_size: events["chunk_size"], next_stream_position: events["next_stream_position"]})
    end

    def enterprise_events(created_after: nil, created_before: nil, stream_position: 0, event_type: nil, limit: 100)
      events = []
      loop do
        event_response = get_enterprise_events(created_after, created_before, stream_position, event_type, limit)
        event_response.events.each{|event| events << event}
        stream_position = event_response.next_stream_position

        break if event_response.events.empty?
      end
      Hashie::Mash.new({events: events, next_stream_position: stream_position})
    end

    def enterprise_events_stream(initial_stream_position, event_type: nil, limit: 100, refresh_period: 5, &stream_listener)
      stream_position = initial_stream_position
      loop do
        response = enterprise_events(stream_position: stream_position, event_type: event_type, limit: limit)
        
        stream_listener.call(response)
        
        stream_position = response.next_stream_position
        sleep refresh_period
      end
    end


    private

    def get_enterprise_events(created_after, created_before, stream_position, event_type, limit)
      query = {stream_position: stream_position, stream_type: :admin_logs, limit: limit}
      query['event_type'] = event_type unless event_type.nil?
      query['created_after'] = created_after.to_datetime.rfc3339 unless created_after.nil?
      query['created_before'] = created_before.to_datetime.rfc3339 unless created_before.nil?

      events, response = get(EVENTS_URI, query: query)
      Hashie::Mash.new({events: events["entries"], chunk_size: events["chunk_size"], next_stream_position: events["next_stream_position"]})
    end

  end
end
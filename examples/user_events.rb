require 'dotenv'; Dotenv.load("../.env")
require 'boxr'
require 'awesome_print'
require 'lru_redux'

client = Boxr::Client.new(ENV['BOX_DEVELOPER_TOKEN'])
cache = LruRedux::Cache.new(1000)

stream_position = :now
loop do 
	puts "fetching events..."
	event_response = client.user_events(stream_position: stream_position)
	event_response.events.each do |event|
		key = "/box-event/id/#{event.event_id}"

		#we need to de-dupe the events because we will receive multiple events with the same event_id; this is to ensure that we get the event
		if (cache.fetch(event.event_id)==nil)
			cache[event.event_id] = true
			puts event.event_type
		end
	end
	stream_position = event_response.next_stream_position
	sleep 2
end
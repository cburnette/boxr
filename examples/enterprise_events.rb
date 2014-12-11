require 'dotenv'; Dotenv.load("../.env")
require 'boxr'
require 'awesome_print'

client = Boxr::Client.new(ENV['BOX_DEVELOPER_TOKEN'])

stream_position = 0
loop do 
	puts "fetching events..."
	event_response = client.enterprise_events(stream_position: stream_position)
	event_response.events.each do |event|
		puts event.event_type
	end
	stream_position = event_response.next_stream_position
	sleep 2
end
require 'dotenv'; Dotenv.load("../.env")
require 'boxr'
require 'awesome_print'

client = Boxr::Client.new(ENV['BOX_DEVELOPER_TOKEN'])

now = Time.now
start_date = now - (60*60*24*30) #three days ago
end_date = now - (60*60*24) #one day ago

stream_position = 0
puts "fetching enterprise events..."
loop do
	event_response = client.enterprise_events(stream_position: stream_position, created_after: start_date.utc, created_before: end_date.utc)
	event_response.events.each do |event|
		ap event
	end
	stream_position = event_response.next_stream_position

	break if event_response.events.empty?
end
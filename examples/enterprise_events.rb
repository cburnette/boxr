require 'dotenv'; Dotenv.load("../.env")
require 'boxr'
require 'awesome_print'

client = Boxr::Client.new(ENV['BOX_DEVELOPER_TOKEN'])

now = Time.now
start_date = now - (60*60*24*10) #one day ago
end_date = now

puts "fetching historic enterprise events..."
result = client.enterprise_events(created_after: start_date, created_before: end_date)

ap result.events.each{|event| ap event; puts;}
output={count: result.events.count, next_stream_position: result.next_stream_position}
ap output

puts "listening for new enterprise events..."
client.enterprise_events_stream(result.next_stream_position) do |result|
  result.events.each{|e| puts e.event_type}
  output={count: result.events.count, next_stream_position: result.next_stream_position}
  ap output
  puts "waiting..."
end
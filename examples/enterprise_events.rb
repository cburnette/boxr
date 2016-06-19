require 'dotenv'
Dotenv.load('../.env')
require 'boxr'
require 'awesome_print'

client = Boxr::Client.new(ENV['BOX_DEVELOPER_TOKEN'])

now = Time.now.utc
start_date = now - (60 * 60 * 24) # one day ago

puts 'fetching historic enterprise events...'
result = client.enterprise_events(created_after: start_date, created_before: now)

ap result.events.each { |event|
  ap event
  puts
}
output = { count: result.events.count, next_stream_position: result.next_stream_position }
ap output

# now that we have the latest stream position let's start monitoring in
# real-time

puts 'listening for new enterprise events...'
client.enterprise_events_stream(result.next_stream_position, refresh_period: 5) do |client_result|
  client_result.events.each do |e|
    ap e
  end
  output = { count: client_result.events.count, next_stream_position: client_result.next_stream_position }
  ap output
  puts 'waiting...'
end

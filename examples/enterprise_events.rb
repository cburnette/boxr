require 'dotenv'; Dotenv.load("../.env")
require 'boxr'
require 'awesome_print'

client = Boxr::Client.new(ENV['BOX_DEVELOPER_TOKEN'])

now = Time.now
start_date = now - (60*60*24) #one day ago
end_date = now

puts "fetching enterprise events..."
result = client.enterprise_events(created_after: start_date, created_before: end_date)

ap result.events.each{|event| ap event; puts;}
output={count: result.events.count, stream_position: result.stream_position}
ap output
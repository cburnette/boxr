require 'dotenv'; Dotenv.load("../.env")
require 'boxr'
require 'awesome_print'

client = Boxr::Client.new(ENV['BOX_DEVELOPER_TOKEN'])

now = Time.now
start_date = now - (60*60*24) #one day ago
end_date = now

puts "fetching enterprise events..."
events = client.enterprise_events(start_date.utc, end_date.utc)
events.each{|event| ap event; puts;}
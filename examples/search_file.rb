#https://community.box.com/t5/Developer-Forum/How-to-get-results-from-Boxr-Search-results/m-p/29640#M1581
require 'dotenv'; Dotenv.load("../.env")
require 'awesome_print'
require 'boxr'

client = Boxr::Client.new(ENV['BOX_DEVELOPER_TOKEN'])
results = client.search("test")

#Print out item id for each search result
results.each do |result|
  puts "File Id: #{result.id}"
end

#Print out item id by the element's index number in the results array
puts results[0].id

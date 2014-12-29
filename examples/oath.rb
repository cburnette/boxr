require 'dotenv'; Dotenv.load("../.env")
require 'boxr'

#make sure you have BOX_CLIENT_ID and BOX_CLIENT_SECRET set in your .env file

oauth_url = Boxr::oauth_url("your-anti-forgery-token", redirect_uri: 'https://localhost:1234')

puts "Step 1:  Copy this URL and paste in into a browser"
puts "------>  #{oauth_url}"

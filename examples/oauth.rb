require 'dotenv'; Dotenv.load("../.env")
require 'boxr'
require 'uri'

#make sure you have BOX_CLIENT_ID and BOX_CLIENT_SECRET set in your .env file
#make sure you have the redirect_uri for your application set to something like https://localhost:1234 in the developer portal

oauth_url = Boxr::oauth_url(URI.encode_www_form_component('your-anti-forgery-token'))

puts "Copy the URL below and paste into a browser. Go through the Oauth flow using the desired Box account. \
When you are finished your browser will redirect to a 404 error page.  Look at the URL in the address bar and copy the 'code' parameter value. \
You only have 30 seconds to complete the next step so be quick about it!"

puts
puts "URL:  #{oauth_url}"
puts

print "Enter the code: "
code = STDIN.gets.chomp

Boxr::get_tokens(code)
puts




# frozen_string_literal: true

require 'dotenv'; Dotenv.load('../.env')
require 'boxr'
require 'uri'
require 'awesome_print'

# make sure you have BOX_CLIENT_ID and BOX_CLIENT_SECRET set in your .env file
# make sure you have the redirect_uri for your application set to something like http://localhost:1234 in the developer portal

oauth_url = Boxr.oauth_url(URI.encode_www_form_component('your-anti-forgery-token'))

puts "Copy the URL below and paste into a browser. Go through the OAuth flow using the desired Box account. \
When you are finished your browser will redirect to a 404 error page. This is expected behavior. Look at the URL in the address \
bar and copy the 'code' parameter value. Paste it into the prompt below. You only have 30 seconds to complete this task so be quick about it! \
You will then see your access token and refresh token."

puts
puts "URL:  #{oauth_url}"
puts

print 'Enter the code: '
code = STDIN.gets.chomp.split('=').last

ap Boxr.get_tokens(code)

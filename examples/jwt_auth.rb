# frozen_string_literal: true

require 'dotenv'; Dotenv.load('../.env')
require 'boxr'
require 'awesome_print'
require 'openssl'

private_key = OpenSSL::PKey::RSA.new(File.read(ENV['JWT_PRIVATE_KEY_PATH']), ENV['JWT_PRIVATE_KEY_PASSWORD'])

# make sure ENV['BOX_ENTERPRISE_ID'], ENV['BOX_CLIENT_ID'] and ENV['BOX_CLIENT_SECRET'] are set
response = Boxr.get_enterprise_token(private_key: private_key)

ap response

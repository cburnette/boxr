require 'spec_helper'

describe Boxr do

	#follow the directions in .env.example to set up your BOX_DEVELOPER_TOKEN
	BOX_CLIENT = Boxr::Client.new(ENV['BOX_DEVELOPER_TOKEN'])
	
	#uncomment this line to see the HTTP request and response debug info in the rspec output
	#BOX_CLIENT.debug_device = STDOUT

	RSPEC_FOLDER_NAME = 'RSpec'

	it 'performs a smoke test of all Boxr functionality against a real Box account' do
		#first step: find any pre-existing 'RSpec' folder and delete it
		file_id = BOX_CLIENT.file_id("#{RSPEC_FOLDER_NAME}/blah1/blah2/assets.txt")
		puts file_id
		#new_folder = BOX_CLIENT.create_folder(RSPEC_FOLDER_NAME, Boxr::ROOT)
		#expect(new_folder).to be_a Hashie::Mash
	end
end
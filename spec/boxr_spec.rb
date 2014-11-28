require 'spec_helper'

describe Boxr do

	#follow the directions in .env.example to set up your BOX_DEVELOPER_TOKEN
	#keep in mind it is only valid for 60 minutes
	BOX_CLIENT = Boxr::Client.new(ENV['BOX_DEVELOPER_TOKEN'])
	
	#uncomment this line to see the HTTP request and response debug info in the rspec output
	#BOX_CLIENT.debug_device = STDOUT

	RSPEC_FOLDER_PATH = '/Boxr_RSpec'

	it 'performs a smoke test of all Boxr functionality against a real Box account' do
		#first step: find any pre-existing 'Boxr_RSpec' folder and delete it
		begin
			folder_id = BOX_CLIENT.folder_id(RSPEC_FOLDER_PATH)
			BOX_CLIENT.delete_folder(folder_id, recursive: true)
		rescue
		end

		#now create our test folder
		new_folder = BOX_CLIENT.create_folder(RSPEC_FOLDER_PATH, Boxr::ROOT)
		expect(new_folder).to be_a Hashie::Mash


	end
end
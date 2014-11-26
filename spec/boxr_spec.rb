require 'spec_helper'

describe Boxr do

	#follow the directions in .env.example to set up your BOX_DEVELOPER_TOKEN
	BOX_CLIENT = Boxr::Client.new(ENV['BOX_DEVELOPER_TOKEN'])
	
	#uncomment this line to see the HTTP request and response debug info
	#BOX_CLIENT.debug_device = STDOUT

	it 'lists folder items' do
		items = BOX_CLIENT.folder_items(Boxr::ROOT)
		expect(items).to be_a Array
	end
end
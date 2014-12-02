require 'spec_helper'

describe Boxr do

	#PLEASE NOTE 
	#This test is intentionally NOT a series of unit tests.  The goal is to smoke test the entire code base
	#against an actual Box account, making real calls to the Box API.  The Box API is subject to frequent
	#changes and it is not sufficient to mock responses as those responses will change over time.  Successfully
	#running this test suite shows that the code base works with the current Box API.  The main premise here
	#is that an exception will be thrown if anything unexpected happens.

	#REQUIRED BOX SETTINGS
	# 1. The developer token used must have admin or co-admin priviledges
	# 2. Enterprise settings must allow Admin and Co-admins to permanently delete content in Trash

	#follow the directions in .env.example to set up your BOX_DEVELOPER_TOKEN
	#keep in mind it is only valid for 60 minutes
	BOX_CLIENT = Boxr::Client.new(ENV['BOX_DEVELOPER_TOKEN'])
	
	#uncomment this line to see the HTTP request and response debug info in the rspec output
	#BOX_CLIENT.debug_device = STDOUT

	TEST_FOLDER_NAME = 'Boxr_Test'
	SUB_FOLDER_NAME = 'sub_folder_1'
	SUB_FOLDER_DESCRIPTION = 'This was created by the Boxr test suite'
	TEST_FILE_NAME = 'test file.txt'
	DOWNLOADED_TEST_FILE_NAME = 'downloaded test file.txt'

	it 'smoke tests the code base against a real Box account' do

	  puts "delete pre-existing test folder if found and create a new test folder"
		root_folders = BOX_CLIENT.folder_items(Boxr::ROOT).folders
		test_folder = root_folders.select{|f| f.name == TEST_FOLDER_NAME}.first
		if(test_folder)
			BOX_CLIENT.delete_folder(test_folder.id, recursive: true)
		end


		#############################################################################
		# 																																					#
		# Folder tests																															#
		# 																																					#
		#############################################################################

		puts "create a new, empty test folder"
		new_folder = BOX_CLIENT.create_folder(TEST_FOLDER_NAME, Boxr::ROOT)
		expect(new_folder).to be_a Hashie::Mash
		TEST_FOLDER_ID = new_folder.id

		puts 'look up test folder id'
		folder_id = BOX_CLIENT.folder_id(TEST_FOLDER_NAME)
		expect(TEST_FOLDER_ID).to eq(TEST_FOLDER_ID)

		puts 'create a new sub-folder'
		new_folder = BOX_CLIENT.create_folder(SUB_FOLDER_NAME, TEST_FOLDER_ID)
		expect(new_folder).to be_a Hashie::Mash
		SUB_FOLDER_ID = new_folder.id

		puts "update the sub-folder's description"
		updated_folder = BOX_CLIENT.update_folder_info(SUB_FOLDER_ID, description: SUB_FOLDER_DESCRIPTION)
		expect(updated_folder.description).to eq(SUB_FOLDER_DESCRIPTION)

		puts "copy the sub-folder"
		new_folder = BOX_CLIENT.copy_folder(SUB_FOLDER_ID,TEST_FOLDER_ID, name: 'copy of sub_folder_1')
		expect(new_folder).to be_a Hashie::Mash
		SUB_FOLDER_COPY_ID = new_folder.id

		puts "create shared link for folder"
		updated_folder = BOX_CLIENT.create_shared_link_for_folder(TEST_FOLDER_ID)
		expect(updated_folder.shared_link).to be_a Hashie::Mash

		puts "disable shared link for folder"
		updated_folder = BOX_CLIENT.disable_shared_link_for_folder(TEST_FOLDER_ID)
		expect(updated_folder.shared_link).to be_nil

		puts "delete folder"
		result = BOX_CLIENT.delete_folder(SUB_FOLDER_COPY_ID, recursive: true)
		expect(result).to be_a Hashie::Mash

		puts "inspect the trash"
		trash = BOX_CLIENT.trash()
		expect(trash).to be_a Array

		puts "inspect the trashed sub folder copy"
		trashed_folder = BOX_CLIENT.trashed_folder(SUB_FOLDER_COPY_ID)
		expect(trashed_folder).to be_a Hashie::Mash

		puts "restore the trashed sub folder copy"
		restored_folder = BOX_CLIENT.restore_trashed_folder(SUB_FOLDER_COPY_ID)
		expect(restored_folder).to be_a Hashie::Mash

		puts "trash and then permanently delete the sub folder copy"
		BOX_CLIENT.delete_folder(SUB_FOLDER_COPY_ID, recursive: true)
		result = BOX_CLIENT.delete_trashed_folder(SUB_FOLDER_COPY_ID)
		expect(result).to be_a Hashie::Mash

		#TODO: still need to test folder collaborations

		
		#############################################################################
		# 																																					#
		# File tests																																#
		# 																																					#
		#############################################################################

		puts "upload a file"
		new_file = BOX_CLIENT.upload_file("./spec/test_files/#{TEST_FILE_NAME}", TEST_FOLDER_ID)
		expect(new_file).to be_a Hashie::Mash
		test_file_id = new_file.id

		puts "look up new file id"
		file_id = BOX_CLIENT.file_id("/#{TEST_FOLDER_NAME}/#{TEST_FILE_NAME}")
		expect(file_id).to eq(test_file_id)

		puts "look up file info"
		file_info = BOX_CLIENT.file_info(test_file_id)
		expect(file_info.id).to eq(test_file_id)

		puts "update file info"
		new_description = 'this file is used to test Boxr'
		updated_file_info = BOX_CLIENT.update_file_info(test_file_id, description: new_description)
		expect(updated_file_info.description).to eq(new_description)

		puts "download file"
		file = BOX_CLIENT.download_file(test_file_id)
		f = open("./spec/test_files/#{DOWNLOADED_TEST_FILE_NAME}", 'w+')
		f.write(file)
		f.close
		expect(FileUtils.identical?("./spec/test_files/#{TEST_FILE_NAME}","./spec/test_files/#{DOWNLOADED_TEST_FILE_NAME}")).to eq(true)
		File.delete("./spec/test_files/#{DOWNLOADED_TEST_FILE_NAME}")

		puts "upload new version of file"
		new_version = BOX_CLIENT.upload_new_version_of_file("./spec/test_files/#{TEST_FILE_NAME}", test_file_id)
		expect(new_version).to be_a Hashie::Mash

		puts "inspect versions of file"
		versions = BOX_CLIENT.versions_of_file(test_file_id)
		expect(versions.count).to eq(1) #the reason this is 1 instead of 2 is that Box considers 'versions' to be a versions other than 'current'
		v1_id = versions.first.id

		puts "promote old version of file"
		newer_version = BOX_CLIENT.promote_old_version_of_file(test_file_id, v1_id)
		versions = BOX_CLIENT.versions_of_file(test_file_id)
		expect(versions.count).to eq(2)

		puts "delete old version of file"
		result = BOX_CLIENT.delete_old_version_of_file(test_file_id,v1_id)
		versions = BOX_CLIENT.versions_of_file(test_file_id)
		expect(versions.count).to eq(2) #this is still 2 because with Box you can restore a trashed old version

		puts "copy file"
		new_file_name = "copy of #{TEST_FILE_NAME}"
		new_file = BOX_CLIENT.copy_file(test_file_id, TEST_FOLDER_ID, name: new_file_name)
		expect(new_file).to be_a(Hashie::Mash)
		expect(new_file.name).to eq(new_file_name)

		puts "get file thumbnail"
		thumb = BOX_CLIENT.thumbnail(test_file_id)
		expect(thumb).not_to be_nil

	end
end
require 'spec_helper'

describe Boxr::Client do

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

	TEST_FOLDER_NAME = 'Boxr Test'
	SUB_FOLDER_NAME = 'sub_folder_1'
	SUB_FOLDER_DESCRIPTION = 'This was created by the Boxr test suite'
	TEST_FILE_NAME = 'test file.txt'
	DOWNLOADED_TEST_FILE_NAME = 'downloaded test file.txt'
	COMMENT_MESSAGE = 'this is a comment'
	REPLY_MESSAGE = 'this is a comment reply'
	CHANGED_COMMENT_MESSAGE = 'this comment has been changed'

	before(:each) do
	  #delete pre-existing test folder if found and create a new test folder"
	  sleep 2 #unfortunately we need to pause to make sure the Box servers return folders just created
		root_folders = BOX_CLIENT.folder_items(Boxr::ROOT).folders
		test_folder = root_folders.select{|f| f.name == TEST_FOLDER_NAME}.first
		if(test_folder)
			BOX_CLIENT.delete_folder(test_folder.id, recursive: true)
		end

		new_folder = BOX_CLIENT.create_folder(TEST_FOLDER_NAME, Boxr::ROOT)
		@test_folder_id = new_folder.id
	end

	it 'invokes folder operations' do

		puts "get folder id using path"
		folder_id = BOX_CLIENT.folder_id(TEST_FOLDER_NAME)
		expect(folder_id).to eq(@test_folder_id)

		puts "get folder info"
		folder = BOX_CLIENT.folder(@test_folder_id)
		expect(folder.id).to eq(@test_folder_id)

		puts "create new folder"
		new_folder = BOX_CLIENT.create_folder(SUB_FOLDER_NAME, @test_folder_id)
		expect(new_folder).to be_a Hashie::Mash
		SUB_FOLDER_ID = new_folder.id

		puts "update folder"
		updated_folder = BOX_CLIENT.update_folder(SUB_FOLDER_ID, description: SUB_FOLDER_DESCRIPTION)
		expect(updated_folder.description).to eq(SUB_FOLDER_DESCRIPTION)

		puts "copy folder"
		new_folder = BOX_CLIENT.copy_folder(SUB_FOLDER_ID,@test_folder_id, name: 'copy of sub_folder_1')
		expect(new_folder).to be_a Hashie::Mash
		SUB_FOLDER_COPY_ID = new_folder.id

		puts "create shared link for folder"
		updated_folder = BOX_CLIENT.create_shared_link_for_folder(@test_folder_id, access: :open)
		expect(updated_folder.shared_link.access).to eq("open")

		puts "disable shared link for folder"
		updated_folder = BOX_CLIENT.disable_shared_link_for_folder(@test_folder_id)
		expect(updated_folder.shared_link).to be_nil

		puts "delete folder"
		result = BOX_CLIENT.delete_folder(SUB_FOLDER_COPY_ID, recursive: true)
		expect(result).to eq ({})

		puts "inspect the trash"
		trash = BOX_CLIENT.trash()
		expect(trash).to be_a Array

		puts "inspect trashed folder"
		trashed_folder = BOX_CLIENT.trashed_folder(SUB_FOLDER_COPY_ID)
		expect(trashed_folder.item_status).to eq("trashed")

		puts "restore trashed folder"
		restored_folder = BOX_CLIENT.restore_trashed_folder(SUB_FOLDER_COPY_ID)
		expect(restored_folder.item_status).to eq("active")

		puts "trash and permanently delete folder"
		BOX_CLIENT.delete_folder(SUB_FOLDER_COPY_ID, recursive: true)
		result = BOX_CLIENT.delete_trashed_folder(SUB_FOLDER_COPY_ID)
		expect(result).to eq({})

	end

	it "invokes file operations" do

		puts "upload a file"
		new_file = BOX_CLIENT.upload_file("./spec/test_files/#{TEST_FILE_NAME}", @test_folder_id)
		expect(new_file.name).to eq(TEST_FILE_NAME)
		test_file_id = new_file.id

		puts "get file id using path"
		file_id = BOX_CLIENT.file_id("/#{TEST_FOLDER_NAME}/#{TEST_FILE_NAME}")
		expect(file_id).to eq(test_file_id)

		puts "get file download url"
		download_url = BOX_CLIENT.download_url(test_file_id)
		expect(download_url).to start_with("https://")

		puts "get file info"
		file_info = BOX_CLIENT.file(test_file_id)
		expect(file_info.id).to eq(test_file_id)

		puts "update file"
		new_description = 'this file is used to test Boxr'
		updated_file_info = BOX_CLIENT.update_file(test_file_id, description: new_description)
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
		expect(new_version.id).to eq(test_file_id)

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

		puts "get file thumbnail"
		thumb = BOX_CLIENT.thumbnail(test_file_id)
		expect(thumb).not_to be_nil

		puts "create shared link for file"
		updated_file = BOX_CLIENT.create_shared_link_for_file(test_file_id, access: :open)
		expect(updated_file.shared_link.access).to eq("open")

		puts "disable shared link for file"
		updated_file = BOX_CLIENT.disable_shared_link_for_file(test_file_id)
		expect(updated_file.shared_link).to be_nil

		puts "copy file"
		new_file_name = "copy of #{TEST_FILE_NAME}"
		new_file = BOX_CLIENT.copy_file(test_file_id, @test_folder_id, name: new_file_name)
		expect(new_file.name).to eq(new_file_name)
		NEW_FILE_ID = new_file.id

		puts "delete file"
		result = BOX_CLIENT.delete_file(NEW_FILE_ID)
		expect(result).to eq({})

		puts "get trashed file info"
		trashed_file = BOX_CLIENT.trashed_file(NEW_FILE_ID)
		expect(trashed_file.item_status).to eq("trashed")

		puts "restore trashed file"
		restored_file = BOX_CLIENT.restore_trashed_file(NEW_FILE_ID)
		expect(restored_file.item_status).to eq("active")

		puts "trash and permanently delete file"
		BOX_CLIENT.delete_file(NEW_FILE_ID)
		result = BOX_CLIENT.delete_trashed_file(NEW_FILE_ID)
		expect(result).to eq({})
	end

	it "invokes comment operations" do 
		new_file = BOX_CLIENT.upload_file("./spec/test_files/#{TEST_FILE_NAME}", @test_folder_id)
		TEST_FILE_ID = new_file.id

		puts "add comment to file"
		comment = BOX_CLIENT.add_comment_to_file(TEST_FILE_ID, message: COMMENT_MESSAGE)
		expect(comment.message).to eq(COMMENT_MESSAGE)
		COMMENT_ID = comment.id

		puts "reply to comment"
		reply = BOX_CLIENT.reply_to_comment(COMMENT_ID, message: REPLY_MESSAGE)
		expect(reply.message).to eq(REPLY_MESSAGE)

		puts "get file comments"
		comments = BOX_CLIENT.file_comments(TEST_FILE_ID)
		expect(comments.count).to eq(2)

		puts "update a comment"
		comment = BOX_CLIENT.change_comment(COMMENT_ID, CHANGED_COMMENT_MESSAGE)
		expect(comment.message).to eq(CHANGED_COMMENT_MESSAGE)

		puts "get comment info"
		comment = BOX_CLIENT.comment(COMMENT_ID)
		expect(comment.id).to eq(COMMENT_ID)

		puts "delete comment"
		result = BOX_CLIENT.delete_comment(COMMENT_ID)
		expect(result).to eq({})
	end
end
require 'spec_helper'

describe Boxr::Client do
  #PLEASE NOTE
  #These tests are intentionally NOT a series of unit tests.  The goal is to smoke test the entire code base
  #against an actual Box account, making real calls to the Box API.  The Box API is subject to frequent
  #changes and it is not sufficient to mock responses as those responses will change over time.  Successfully
  #running this test suite shows that the code base works with the current Box API.  The main premise here
  #is that an exception will be thrown if anything unexpected happens.

  #REQUIRED BOX SETTINGS
  # 1. The developer token used must have admin or co-admin priviledges
  # 2. Enterprise settings must allow Admin and Co-admins to permanently delete content in Trash

  #follow the directions in .env.example to set up your BOX_DEVELOPER_TOKEN
  #keep in mind it is only valid for 60 minutes
  BOX_CLIENT = Boxr::Client.new # using ENV['BOX_DEVELOPER_TOKEN']

  #uncomment this line to see the HTTP request and response debug info in the rspec output
  # Boxr::turn_on_debugging

  BOX_SERVER_SLEEP = 5
  TEST_FOLDER_NAME = 'Boxr Test'
  SUB_FOLDER_NAME = 'sub_folder_1'
  SUB_FOLDER_DESCRIPTION = 'This was created by the Boxr test suite'
  TEST_FILE_NAME = 'test file.txt'
  TEST_FILE_NAME_CUSTOM = 'test file custom.txt'
  DOWNLOADED_TEST_FILE_NAME = 'downloaded test file.txt'
  COMMENT_MESSAGE = 'this is a comment'
  REPLY_MESSAGE = 'this is a comment reply'
  CHANGED_COMMENT_MESSAGE = 'this comment has been changed'
  TEST_USER_LOGIN = "test-boxr-user@#{('a'..'z').to_a.shuffle[0,10].join}.com" # needs to be unique across anyone running this test
  TEST_USER_NAME = "Test Boxr User"
  TEST_GROUP_NAME= "Test Boxr Group"
  TEST_TASK_MESSAGE = "Please review"
  TEST_WEB_URL = 'https://www.box.com'
  TEST_WEB_URL2 = 'https://www.google.com'
end

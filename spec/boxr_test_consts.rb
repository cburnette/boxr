# frozen_string_literal: true

module BoxrTestConsts
  # follow the directions in .env.example to set up your BOX_DEVELOPER_TOKEN
  # keep in mind it is only valid for 60 minutes
  BOX_CLIENT = Boxr::Client.new # using ENV['BOX_DEVELOPER_TOKEN']

  # uncomment this line to see the HTTP request and response debug info in the rspec output
  # Boxr::turn_on_debugging

  BOX_SERVER_SLEEP = 5
  TEST_FOLDER_NAME = 'Boxr Test'
  SUB_FOLDER_NAME = 'sub_folder_1'
  SUB_FOLDER_DESCRIPTION = 'This was created by the Boxr test suite'
  TEST_FILE_NAME = 'test file.txt'
  TEST_LARGE_FILE_NAME = 'large test file.txt'
  TEST_FILE_NAME_CUSTOM = 'test file custom.txt'
  TEST_FILE_NAME_IO = 'test file io.txt'
  DOWNLOADED_TEST_FILE_NAME = 'downloaded test file.txt'
  COMMENT_MESSAGE = 'this is a comment'
  REPLY_MESSAGE = 'this is a comment reply'
  CHANGED_COMMENT_MESSAGE = 'this comment has been changed'

  # NOTE: needs to be unique across anyone running this test
  TEST_USER_LOGIN = "test-boxr-user@#{('a'..'z').to_a.sample(10).join}.com"
  TEST_USER_NAME = 'Test Boxr User'
  TEST_GROUP_NAME = 'Test Boxr Group'
  TEST_TASK_MESSAGE = 'Please review'
  TEST_WEB_URL = 'https://www.box.com'
  TEST_WEB_URL2 = 'https://www.google.com'
end

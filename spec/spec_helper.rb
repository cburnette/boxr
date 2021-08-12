# frozen_string_literal: true

# PLEASE NOTE
# These tests are intentionally NOT a series of unit tests.  The goal is to smoke test the entire code base
# against an actual Box account, making real calls to the Box API.  The Box API is subject to frequent
# changes and it is not sufficient to mock responses as those responses will change over time.  Successfully
# running this test suite shows that the code base works with the current Box API.  The main premise here
# is that an exception will be thrown if anything unexpected happens.
#
# REQUIRED BOX SETTINGS
# 1. The developer token used must have admin or co-admin priviledges
# 1.5 In the admin settings, advanced features must be enabled (perform as user and create user access tokens)
# 2. Enterprise settings must allow Admin and Co-admins to permanently delete content in Trash
# 3. In Box Admin settings, you must authorize the app.
#   - Admin Console > Enterprise Settings > Apps > Custom Applications > Authorize New App.
#   Insert you client ID (API key)
#   - You may need to re-authorize the app if you're running into issues with user tokens


require 'dotenv'
Dotenv.load

require 'simplecov'
SimpleCov.start { add_filter "_spec" }

require 'boxr'
require 'awesome_print'
require 'pry'
require_relative 'boxr_test_consts'

RSpec.configure do |config|
  include BoxrTestConsts

  config.example_status_persistence_file_path = 'spec/failed_specs.log'

  config.before(:each) do |example|
    if example.metadata[:skip_reset]
      puts "Skipping reset"
      next
    end

    puts "-----> Resetting Box Environment"
    sleep BOX_SERVER_SLEEP
    root_folders = BOX_CLIENT.root_folder_items.folders
    test_folder = root_folders.find{|f| f.name == TEST_FOLDER_NAME}
    if(test_folder)
      BOX_CLIENT.delete_folder(test_folder, recursive: true)
    end
    new_folder = BOX_CLIENT.create_folder(TEST_FOLDER_NAME, Boxr::ROOT)
    @test_folder = new_folder

    all_users = BOX_CLIENT.all_users
    test_users = all_users.select{|u| u.name == TEST_USER_NAME}
    test_users.each do |u|
      BOX_CLIENT.delete_user(u, force: true)
    end
    sleep BOX_SERVER_SLEEP
    test_user = BOX_CLIENT.create_user(TEST_USER_NAME, login: TEST_USER_LOGIN)
    @test_user = test_user

    all_groups = BOX_CLIENT.groups
    test_group = all_groups.find{|g| g.name == TEST_GROUP_NAME}
    if(test_group)
      BOX_CLIENT.delete_group(test_group)
    end
  end

  config.filter_run_when_matching :focus
end

# frozen_string_literal: true

require 'dotenv'; Dotenv.load
require 'simplecov'; SimpleCov.start { add_filter "_spec" }
require 'boxr'
require 'awesome_print'

RSpec.configure do |config|
  config.before(:each) do
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
end

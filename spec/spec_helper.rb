require 'dotenv'
Dotenv.load

# For unit tests only
require 'awesome_print'
require 'simplecov'
SimpleCov.start { add_filter '_spec' }

require 'webmock/rspec'

require 'boxr'
require 'boxr_spec'

# Needed for webmock to work
Boxr::BOX_CLIENT = HTTPClient.new

RSpec.configure do |config|
  config.define_derived_metadata(file_path: %r{/spec/unit/}) do |metadata|
    metadata[:unit] = true
  end

  config.before do
    if self.class.metadata[:unit]
      WebMock.disable_net_connect!(allow_localhost: true)
      WebMock.enable!
    else
      WebMock.enable_net_connect!
      WebMock.reset!
      WebMock.disable!
    end
  end

  config.before do |example|
    next if example.metadata[:skip_reset]
    next if example.metadata[:unit]

    puts '-----> Resetting Box Environment'
    sleep BOX_SERVER_SLEEP
    root_folders = BOX_CLIENT.root_folder_items.folders
    test_folder = root_folders.find { |f| f.name == TEST_FOLDER_NAME }
    BOX_CLIENT.delete_folder(test_folder, recursive: true) if test_folder
    new_folder = BOX_CLIENT.create_folder(TEST_FOLDER_NAME, Boxr::ROOT)
    @test_folder = new_folder

    all_users = BOX_CLIENT.all_users
    test_users = all_users.select { |u| u.name == TEST_USER_NAME }
    test_users.each do |u|
      BOX_CLIENT.delete_user(u, force: true)
    end
    sleep BOX_SERVER_SLEEP
    test_user = BOX_CLIENT.create_user(TEST_USER_NAME, login: TEST_USER_LOGIN)
    @test_user = test_user

    all_groups = BOX_CLIENT.groups
    test_group = all_groups.find { |g| g.name == TEST_GROUP_NAME }
    BOX_CLIENT.delete_group(test_group) if test_group
  end

  config.filter_run_when_matching :focus
end

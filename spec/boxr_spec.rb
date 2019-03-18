# frozen_string_literal: true

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

  # uncomment this line to see the HTTP request and response debug info in the rspec output
  # Boxr::turn_on_debugging

  BOX_SERVER_SLEEP = 5
  TEST_FOLDER_NAME = 'Boxr Test'
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

  before(:each) do
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
    test_user = BOX_CLIENT.create_user(TEST_USER_NAME, login: TEST_USER_LOGIN, is_platform_access_only: true)
    @test_user = test_user

    all_groups = BOX_CLIENT.groups
    test_group = all_groups.find { |g| g.name == TEST_GROUP_NAME }

    BOX_CLIENT.delete_group(test_group) if test_group
  end

  # use this command to just execute this scenario
  # rake spec SPEC_OPTS="-e \"invokes folder operations"\"
  it 'invokes folder operations' do
    puts 'get folder using path'
    folder = BOX_CLIENT.folder_from_path(TEST_FOLDER_NAME)
    expect(folder.id).to eq(@test_folder.id)

    puts 'get folder info'
    folder = BOX_CLIENT.folder(@test_folder)
    expect(folder.id).to eq(@test_folder.id)

    puts 'create new folder'
    new_folder = BOX_CLIENT.create_folder(SUB_FOLDER_NAME, @test_folder)
    expect(new_folder).to be_a BoxrMash
    SUB_FOLDER = new_folder

    puts 'update folder'
    updated_folder = BOX_CLIENT.update_folder(SUB_FOLDER, description: SUB_FOLDER_DESCRIPTION)
    expect(updated_folder.description).to eq(SUB_FOLDER_DESCRIPTION)

    puts 'copy folder'
    new_folder = BOX_CLIENT.copy_folder(SUB_FOLDER, @test_folder, name: "copy of #{SUB_FOLDER_NAME}")
    expect(new_folder).to be_a BoxrMash
    SUB_FOLDER_COPY = new_folder

    puts 'create shared link for folder'
    updated_folder = BOX_CLIENT.create_shared_link_for_folder(@test_folder, access: :open)
    expect(updated_folder.shared_link.access).to eq('open')

    puts 'create password-protected shared link for folder'
    updated_folder = BOX_CLIENT.create_shared_link_for_folder(@test_folder, password: 'password')
    expect(updated_folder.shared_link.is_password_enabled).to eq(true)
    shared_link = updated_folder.shared_link.url

    puts 'inspect shared link'
    shared_item = BOX_CLIENT.shared_item(shared_link)
    expect(shared_item.id).to eq(@test_folder.id)

    puts 'disable shared link for folder'
    updated_folder = BOX_CLIENT.disable_shared_link_for_folder(@test_folder)
    expect(updated_folder.shared_link).to be_nil

    puts 'move folder'
    folder_to_move = BOX_CLIENT.create_folder('Folder to move', @test_folder)
    folder_to_move_into = BOX_CLIENT.create_folder('Folder to move into', @test_folder)
    folder_to_move = BOX_CLIENT.move_folder(folder_to_move, folder_to_move_into)
    expect(folder_to_move.parent.id).to eq(folder_to_move_into.id)

    puts 'delete folder'
    result = BOX_CLIENT.delete_folder(SUB_FOLDER_COPY, recursive: true)
    expect(result).to eq ({})

    puts 'inspect the trash'
    trash = BOX_CLIENT.trash()
    expect(trash).to be_a Array

    puts 'inspect trashed folder'
    trashed_folder = BOX_CLIENT.trashed_folder(SUB_FOLDER_COPY)
    expect(trashed_folder.item_status).to eq('trashed')

    puts 'restore trashed folder'
    restored_folder = BOX_CLIENT.restore_trashed_folder(SUB_FOLDER_COPY)
    expect(restored_folder.item_status).to eq('active')

    puts 'trash and permanently delete folder'
    BOX_CLIENT.delete_folder(SUB_FOLDER_COPY, recursive: true)
    result = BOX_CLIENT.delete_trashed_folder(SUB_FOLDER_COPY)
    expect(result).to eq({})
  end

  # rake spec SPEC_OPTS="-e \"invokes file operations"\"
  it 'invokes file operations' do
    puts 'upload a file'
    new_file = BOX_CLIENT.upload_file("./spec/test_files/#{TEST_FILE_NAME}", @test_folder)
    expect(new_file.name).to eq(TEST_FILE_NAME)
    test_file = new_file

    puts 'upload a file with custom name'
    new_file = BOX_CLIENT.upload_file("./spec/test_files/#{TEST_FILE_NAME}", @test_folder, name: TEST_FILE_NAME_CUSTOM)
    expect(new_file.name).to eq(TEST_FILE_NAME_CUSTOM)

    puts 'get file using path'
    file = BOX_CLIENT.file_from_path("/#{TEST_FOLDER_NAME}/#{TEST_FILE_NAME}")
    expect(file.id).to eq(test_file.id)

    puts 'get file download url'
    download_url = BOX_CLIENT.download_url(test_file)
    expect(download_url).to start_with('https://')

    puts 'get file info'
    file_info = BOX_CLIENT.file(test_file)
    expect(file_info.id).to eq(test_file.id)

    puts 'get file preview link'
    preview_url = BOX_CLIENT.preview_url(test_file)
    expect(preview_url).to start_with('https://')

    puts 'update file'
    new_description = 'this file is used to test Boxr'
    tags = ['tag one', 'tag two']
    updated_file_info = BOX_CLIENT.update_file(test_file, description: new_description, tags: tags)
    expect(updated_file_info.description).to eq(new_description)
    tag_file_info = BOX_CLIENT.file(updated_file_info, fields: [:tags])
    expect(tag_file_info.tags.length).to eq(2)

    puts 'lock file'
    expires_at_utc = Time.now.utc + (60 * 60 * 24) # one day from now
    locked_file = BOX_CLIENT.lock_file(test_file, expires_at: expires_at_utc, is_download_prevented: true)
    locked_file = BOX_CLIENT.file(locked_file, fields: [:lock])
    expect(locked_file.lock.type).to eq('lock')
    expect(locked_file.lock.expires_at).to_not be_nil
    expect(locked_file.lock.is_download_prevented).to eq(true)

    puts 'unlock file'
    unlocked_file = BOX_CLIENT.unlock_file(locked_file)
    unlocked_file = BOX_CLIENT.file(unlocked_file, fields: [:lock])
    expect(unlocked_file.lock).to be_nil

    puts 'download file'
    file = BOX_CLIENT.download_file(test_file)
    f = File.open("./spec/test_files/#{DOWNLOADED_TEST_FILE_NAME}", 'w+')
    f.write(file)
    f.close
    expect(FileUtils.identical?("./spec/test_files/#{TEST_FILE_NAME}", "./spec/test_files/#{DOWNLOADED_TEST_FILE_NAME}")).to eq(true)
    File.delete("./spec/test_files/#{DOWNLOADED_TEST_FILE_NAME}")

    puts 'upload new version of file'
    new_version = BOX_CLIENT.upload_new_version_of_file("./spec/test_files/#{TEST_FILE_NAME}", test_file)
    expect(new_version.id).to eq(test_file.id)

    puts 'inspect versions of file'
    versions = BOX_CLIENT.versions_of_file(test_file)
    expect(versions.count).to eq(1) # the reason this is 1 instead of 2 is that Box considers 'versions' to be a versions other than 'current'
    v1 = versions.first

    puts 'promote old version of file'
    newer_version = BOX_CLIENT.promote_old_version_of_file(test_file, v1)
    versions = BOX_CLIENT.versions_of_file(test_file)
    expect(versions.count).to eq(2)

    puts 'delete old version of file'
    result = BOX_CLIENT.delete_old_version_of_file(test_file, v1)
    versions = BOX_CLIENT.versions_of_file(test_file)
    expect(versions.count).to eq(2) # this is still 2 because with Box you can restore a trashed old version

    puts 'get file thumbnail'
    thumb = BOX_CLIENT.thumbnail(test_file)
    expect(thumb).not_to be_nil

    puts 'create shared link for file'
    updated_file = BOX_CLIENT.create_shared_link_for_file(test_file, access: :open)
    expect(updated_file.shared_link.access).to eq('open')

    puts 'create password-protected shared link for file'
    updated_file = BOX_CLIENT.create_shared_link_for_file(test_file, password: 'password')
    expect(updated_file.shared_link.is_password_enabled).to eq(true)

    puts 'disable shared link for file'
    updated_file = BOX_CLIENT.disable_shared_link_for_file(test_file)
    expect(updated_file.shared_link).to be_nil

    puts 'copy file'
    new_file_name = "copy of #{TEST_FILE_NAME}"
    new_file = BOX_CLIENT.copy_file(test_file, @test_folder, name: new_file_name)
    expect(new_file.name).to eq(new_file_name)
    NEW_FILE = new_file

    puts 'move file'
    new_folder = BOX_CLIENT.create_folder(SUB_FOLDER_NAME, @test_folder)
    test_file = BOX_CLIENT.move_file(test_file, new_folder.id)
    expect(test_file.parent.id).to eq(new_folder.id)

    puts 'delete file'
    result = BOX_CLIENT.delete_file(NEW_FILE)
    expect(result).to eq({})

    puts 'get trashed file info'
    trashed_file = BOX_CLIENT.trashed_file(NEW_FILE)
    expect(trashed_file.item_status).to eq('trashed')

    puts 'restore trashed file'
    restored_file = BOX_CLIENT.restore_trashed_file(NEW_FILE)
    expect(restored_file.item_status).to eq('active')

    puts 'trash and permanently delete file'
    BOX_CLIENT.delete_file(NEW_FILE)
    result = BOX_CLIENT.delete_trashed_file(NEW_FILE)
    expect(result).to eq({})
  end

  it 'invokes web links operations' do
    puts 'create web link'
    web_link = BOX_CLIENT.create_web_link(TEST_WEB_URL, '0', name: 'my new link', description: 'link description...')
    expect(web_link.url).to eq(TEST_WEB_URL)

    puts 'get web link'
    web_link_new = BOX_CLIENT.get_web_link(web_link)
    expect(web_link_new.id).to eq(web_link.id)

    puts 'update web link'
    updated_web_link = BOX_CLIENT.update_web_link(web_link, name: 'new name', description: 'new description', url: TEST_WEB_URL2)
    expect(updated_web_link.url).to eq(TEST_WEB_URL2)

    puts 'delete web link'
    result = BOX_CLIENT.delete_web_link(web_link)
    expect(result).to eq({})
  end

  # rake spec SPEC_OPTS="-e \"invokes watermarking operations"\"
  xit 'invokes watermarking operations' do
    test_file = BOX_CLIENT.upload_file("./spec/test_files/#{TEST_FILE_NAME}", @test_folder)
    folder = BOX_CLIENT.folder(@test_folder)

    puts 'apply watermark on file'
    watermark = BOX_CLIENT.apply_watermark_on_file(test_file)
    expect(watermark.watermark).to_not be_nil

    puts 'get watermark on file'
    watermark = BOX_CLIENT.get_watermark_on_file(test_file)
    expect(watermark.watermark).to_not be_nil

    puts 'remove watermark on file'
    result = BOX_CLIENT.remove_watermark_on_file(test_file)
    expect(result).to eq({})

    puts 'apply watermark on folder'
    watermark = BOX_CLIENT.apply_watermark_on_folder(folder)
    expect(watermark.watermark).to_not be_nil

    puts 'get watermark on folder'
    watermark = BOX_CLIENT.get_watermark_on_folder(folder)
    expect(watermark.watermark).to_not be_nil

    puts 'remove watermark on folder'
    result = BOX_CLIENT.remove_watermark_on_folder(folder)
    expect(result).to eq({})
  end

  it 'invokes user operations' do
    puts 'inspect current user'
    user = BOX_CLIENT.current_user
    expect(user.status).to eq('active')
    user = BOX_CLIENT.me(fields: [:role])
    expect(user.role).to_not be_nil

    puts 'inspect a user'
    user = BOX_CLIENT.user(@test_user)
    expect(user.id).to eq(@test_user.id)

    puts 'delete user'
    result = BOX_CLIENT.delete_user(@test_user, force: true)
    expect(result).to eq({})
  end

  it 'invokes group operations' do
    puts 'create group'
    group = BOX_CLIENT.create_group(TEST_GROUP_NAME)
    expect(group.name).to eq(TEST_GROUP_NAME)

    puts 'inspect groups'
    groups = BOX_CLIENT.groups
    test_group = groups.find { |g| g.name == TEST_GROUP_NAME }
    expect(test_group).to_not be_nil

    puts 'update group'
    new_name = 'Test Boxr Group Renamed'
    group = BOX_CLIENT.update_group(test_group, new_name)
    expect(group.name).to eq(new_name)
    group = BOX_CLIENT.rename_group(test_group, TEST_GROUP_NAME)
    expect(group.name).to eq(TEST_GROUP_NAME)

    puts 'add user to group'
    group_membership = BOX_CLIENT.add_user_to_group(@test_user, test_group)
    expect(group_membership.user.id).to eq(@test_user.id)
    expect(group_membership.group.id).to eq(test_group.id)
    membership = group_membership

    puts 'inspect group membership'
    group_membership = BOX_CLIENT.group_membership(membership)
    expect(group_membership.id).to eq(membership.id)

    puts 'inspect group memberships'
    group_memberships = BOX_CLIENT.group_memberships(test_group)
    expect(group_memberships.count).to eq(1)
    expect(group_memberships.first.id).to eq(membership.id)

    puts 'inspect group memberships for a user'
    group_memberships = BOX_CLIENT.group_memberships_for_user(@test_user)
    expect(group_memberships.count).to eq(1)
    expect(group_memberships.first.id).to eq(membership.id)

    puts 'inspect group memberships for me'
    # this is whatever user your developer token is tied to
    group_memberships = BOX_CLIENT.group_memberships_for_me
    expect(group_memberships).to be_a(Array)

    puts 'update group membership'
    group_membership = BOX_CLIENT.update_group_membership(membership, :admin)
    expect(group_membership.role).to eq('admin')

    puts 'delete group membership'
    result = BOX_CLIENT.delete_group_membership(membership)
    expect(result).to eq({})
    group_memberships = BOX_CLIENT.group_memberships_for_user(@test_user)
    expect(group_memberships.count).to eq(0)

    puts 'inspect group collaborations'
    group_collaboration = BOX_CLIENT.add_collaboration(@test_folder, { id: test_group.id, type: :group }, :editor)
    expect(group_collaboration.accessible_by.id).to eq(test_group.id)

    puts 'delete group'
    response = BOX_CLIENT.delete_group(test_group)
    expect(response).to eq({})
  end

  it 'invokes comment operations' do
    new_file = BOX_CLIENT.upload_file("./spec/test_files/#{TEST_FILE_NAME}", @test_folder)
    test_file = new_file

    puts 'add comment to file'
    comment = BOX_CLIENT.add_comment_to_file(test_file, message: COMMENT_MESSAGE)
    expect(comment.message).to eq(COMMENT_MESSAGE)
    COMMENT = comment

    puts 'reply to comment'
    reply = BOX_CLIENT.reply_to_comment(COMMENT, message: REPLY_MESSAGE)
    expect(reply.message).to eq(REPLY_MESSAGE)

    puts 'get file comments'
    comments = BOX_CLIENT.file_comments(test_file)
    expect(comments.count).to eq(2)

    puts 'update a comment'
    comment = BOX_CLIENT.change_comment(COMMENT, CHANGED_COMMENT_MESSAGE)
    expect(comment.message).to eq(CHANGED_COMMENT_MESSAGE)

    puts 'get comment info'
    comment = BOX_CLIENT.comment(COMMENT)
    expect(comment.id).to eq(COMMENT.id)

    puts 'delete comment'
    result = BOX_CLIENT.delete_comment(COMMENT)
    expect(result).to eq({})
  end

  it 'invokes collaborations operations' do
    puts 'add collaboration'
    collaboration = BOX_CLIENT.add_collaboration(@test_folder, { id: @test_user.id, type: :user }, :viewer_uploader)
    expect(collaboration.accessible_by.id).to eq(@test_user.id)
    COLLABORATION = collaboration

    puts 'inspect collaboration'
    collaboration = BOX_CLIENT.collaboration(COLLABORATION)
    expect(collaboration.id).to eq(COLLABORATION.id)

    puts 'edit collaboration'
    collaboration = BOX_CLIENT.edit_collaboration(COLLABORATION, role: 'viewer uploader')
    expect(collaboration.role).to eq('viewer uploader')

    puts 'inspect folder collaborations'
    collaborations = BOX_CLIENT.folder_collaborations(@test_folder)
    expect(collaborations.count).to eq(1)
    expect(collaborations[0].id).to eq(COLLABORATION.id)

    puts 'remove collaboration'
    result = BOX_CLIENT.remove_collaboration(COLLABORATION)
    expect(result).to eq({})
    collaborations = BOX_CLIENT.folder_collaborations(@test_folder)
    expect(collaborations.count).to eq(0)

    puts 'inspect pending collaborations'
    pending_collaborations = BOX_CLIENT.pending_collaborations
    expect(pending_collaborations).to eq([])

    puts 'add invalid collaboration'
    expect { BOX_CLIENT.add_collaboration(@test_folder, { id: @test_user.id, type: :user }, :invalid_role) }.to raise_error
  end

  it 'invokes task operations' do
    test_file = BOX_CLIENT.upload_file("./spec/test_files/#{TEST_FILE_NAME}", @test_folder)
    BOX_CLIENT.add_collaboration(@test_folder, { id: @test_user.id, type: :user }, :editor)

    puts 'create task'
    new_task = BOX_CLIENT.create_task(test_file, message: TEST_TASK_MESSAGE)
    expect(new_task.message).to eq(TEST_TASK_MESSAGE)
    TEST_TASK = new_task

    puts 'inspect file tasks'
    tasks = BOX_CLIENT.file_tasks(test_file)
    expect(tasks.first.id).to eq(TEST_TASK.id)

    puts 'inspect task'
    task = BOX_CLIENT.task(TEST_TASK)
    expect(task.id).to eq(TEST_TASK.id)

    puts 'update task'
    NEW_TASK_MESSAGE = 'new task message'
    updated_task = BOX_CLIENT.update_task(TEST_TASK, message: NEW_TASK_MESSAGE)
    expect(updated_task.message).to eq(NEW_TASK_MESSAGE)

    puts 'create task assignment'
    task_assignment = BOX_CLIENT.create_task_assignment(TEST_TASK, assign_to: @test_user.id)
    expect(task_assignment.assigned_to.id).to eq(@test_user.id)
    TASK_ASSIGNMENT = task_assignment

    puts 'inspect task assignment'
    task_assignment = BOX_CLIENT.task_assignment(TASK_ASSIGNMENT)
    expect(task_assignment.id).to eq(TASK_ASSIGNMENT.id)

    puts 'inspect task assignments'
    task_assignments = BOX_CLIENT.task_assignments(TEST_TASK)
    expect(task_assignments.count).to eq(1)
    expect(task_assignments[0].id).to eq(TASK_ASSIGNMENT.id)

    # TODO: can't do this test yet because the test user needs to confirm their email address before you can do this
    puts 'update task assignment'
    expect do
      box_client_as_test_user = Boxr::Client.new(ENV['BOX_DEVELOPER_TOKEN'], as_user_id: @test_user.id)
      new_message = 'Updated task message'
      task_assignment = box_client_as_test_user.update_task_assignment(TEST_TASK, resolution_state: :completed)
      expect(task_assignment.resolution_state).to eq('completed')
    end.to raise_error

    puts 'delete task assignment'
    result = BOX_CLIENT.delete_task_assignment(TASK_ASSIGNMENT)
    expect(result).to eq({})

    puts 'delete task'
    result = BOX_CLIENT.delete_task(TEST_TASK)
    expect(result).to eq({})
  end

  it 'invokes file metadata operations' do
    test_file = BOX_CLIENT.upload_file("./spec/test_files/#{TEST_FILE_NAME}", @test_folder)

    puts 'create metadata'
    meta = { 'a' => 'hello', 'b' => 'world' }
    metadata = BOX_CLIENT.create_metadata(test_file, meta)
    expect(metadata.a).to eq('hello')

    puts 'update metadata'
    metadata = BOX_CLIENT.update_metadata(test_file, op: :replace, path: '/b', value: 'there')
    expect(metadata.b).to eq('there')
    metadata = BOX_CLIENT.update_metadata(test_file, [{ op: :replace, path: '/b', value: 'friend' }])
    expect(metadata.b).to eq('friend')

    puts 'get metadata'
    metadata = BOX_CLIENT.metadata(test_file)
    expect(metadata.a).to eq('hello')

    puts 'delete metadata'
    result = BOX_CLIENT.delete_metadata(test_file)
    expect(result).to eq({})
  end

  it 'requests downscope tokens' do
    app_user_id = @test_user.id
    jwt_token = Boxr.get_user_token(app_user_id).access_token
    scopes = %w[item_upload item_preview base_explorer]
    downscope_token = Boxr.downscope_token(jwt_token, scopes: scopes)
    expect(downscope_token.access_token).to_not be_nil
    expect(downscope_token.restricted_to).to be_kind_of(Array)

    app_user_client = Boxr::Client.new(jwt_token)
    app_user_folder = app_user_client.create_folder(TEST_FOLDER_NAME, Boxr::ROOT)

    ui_element_downscope_token = Boxr.downscope_token_for_box_ui_element(jwt_token, app_user_folder.id)
  end

  # NOTE: this test will fail unless you create a metadata template called 'test' with two attributes: 'a' of type text, and 'b' of type text
  xit 'invokes folder metadata operations' do
    new_folder = BOX_CLIENT.create_folder(SUB_FOLDER_NAME, @test_folder)

    puts 'create folder metadata'
    meta = { 'a' => 'hello', 'b' => 'world' }
    metadata = BOX_CLIENT.create_folder_metadata(new_folder, meta, 'enterprise', 'test')
    expect(metadata.a).to eq('hello')

    puts 'update folder metadata'
    metadata = BOX_CLIENT.update_folder_metadata(new_folder, { op: :replace, path: '/b', value: 'there' }, 'enterprise', 'test')
    expect(metadata.b).to eq('there')
    metadata = BOX_CLIENT.update_folder_metadata(new_folder, [{ op: :replace, path: '/b', value: 'friend' }], 'enterprise', 'test')
    expect(metadata.b).to eq('friend')

    puts 'get folder metadata'
    metadata = BOX_CLIENT.folder_metadata(new_folder, 'enterprise', 'test')
    expect(metadata.a).to eq('hello')

    puts 'delete folder metadata'
    result = BOX_CLIENT.delete_folder_metadata(new_folder, 'enterprise', 'test')
    expect(result).to eq({})
  end

  it 'invokes search operations' do
    # the issue with this test is that Box can take between 5-10 minutes to index any content uploaded; this is just a smoke test
    # so we are searching for something that should return zero results
    puts 'perform search'
    results = BOX_CLIENT.search('sdlfjuwnsljsdfuqpoiqweouyvnnadsfkjhiuweruywerbjvhvkjlnasoifyukhenlwdflnsdvoiuawfydfjh')
    expect(results).to eq([])
  end

  it 'invokes webhook operations' do
    puts 'create webhooks'
    resource_id = @test_folder.id
    type = 'folder'
    triggers = ['FOLDER.RENAMED']
    address =  'https://example.com'
    new_webhook = BOX_CLIENT.create_webhook(resource_id, type, triggers, address)
    new_webhook_id = new_webhook.id
    expect(new_webhook.created_at).to_not be_empty

    puts 'get webhooks'
    all_webhooks = BOX_CLIENT.webhooks
    expect(all_webhooks.entries.first.id).to eq(new_webhook_id)

    single_webhook = BOX_CLIENT.webhook(new_webhook_id)
    expect(single_webhook.id).to eq(new_webhook_id)

    puts 'update webhooks'
    new_address = 'https://foo.com'
    updated_webhook = BOX_CLIENT.update_webhook(new_webhook, address: new_address)
    expect(updated_webhook.address).to eq(new_address)

    puts 'delete webhooks'
    deleted_webhook = BOX_CLIENT.delete_webhook(updated_webhook)
    expect(deleted_webhook).to be_empty
  end

  it 'shows detailed errors' do
    expect do
      BOX_CLIENT.create_folder(nil, @test_folder)
    end.to raise_error(Boxr::BoxrError, "400: Bad Request, 'name' is required")
  end
end

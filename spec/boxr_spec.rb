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

  BOX_SERVER_SLEEP = 5
  TEST_FOLDER_NAME = 'Boxr Test'
  SUB_FOLDER_NAME = 'sub_folder_1'
  SUB_FOLDER_DESCRIPTION = 'This was created by the Boxr test suite'
  TEST_FILE_NAME = 'test file.txt'
  DOWNLOADED_TEST_FILE_NAME = 'downloaded test file.txt'
  COMMENT_MESSAGE = 'this is a comment'
  REPLY_MESSAGE = 'this is a comment reply'
  CHANGED_COMMENT_MESSAGE = 'this comment has been changed'
  TEST_USER_LOGIN = "test-boxr-user@example.com"
  TEST_USER_NAME = "Test Boxr User"
  TEST_GROUP_NAME= "Test Boxr Group"
  TEST_TASK_MESSAGE = "Please review"

  before(:each) do
    puts "-----> Resetting Box Environment"
    sleep BOX_SERVER_SLEEP
    root_folders = BOX_CLIENT.folder_items(Boxr::ROOT).folders
    test_folder = root_folders.find{|f| f.name == TEST_FOLDER_NAME}
    if(test_folder)
      BOX_CLIENT.delete_folder(test_folder.id, recursive: true)
    end
    new_folder = BOX_CLIENT.create_folder(TEST_FOLDER_NAME, Boxr::ROOT)
    @test_folder_id = new_folder.id

    all_users = BOX_CLIENT.all_users
    test_user = all_users.find{|u| u.login == TEST_USER_LOGIN}
    if(test_user)
      BOX_CLIENT.delete_user(test_user.id, force: true)
    end
    sleep BOX_SERVER_SLEEP
    test_user = BOX_CLIENT.create_user(TEST_USER_LOGIN, TEST_USER_NAME)
    @test_user_id = test_user.id

    all_groups = BOX_CLIENT.groups
    test_group = all_groups.find{|g| g.name == TEST_GROUP_NAME}
    if(test_group)
      BOX_CLIENT.delete_group(test_group.id)
    end
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
    shared_link = updated_folder.shared_link.url

    puts "inspect shared link"
    shared_item = BOX_CLIENT.shared_item(shared_link)
    expect(shared_item.id).to eq(@test_folder_id)

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

  it "invokes user operations" do 
    puts "inspect current user"
    user = BOX_CLIENT.current_user
    expect(user.status).to eq('active')
    user = BOX_CLIENT.me(fields: [:role])
    expect(user.role).to_not be_nil

    puts "inspect a user"
    user = BOX_CLIENT.user(@test_user_id)
    expect(user.id).to eq(@test_user_id)

    puts "inspect all users"
    all_users = BOX_CLIENT.all_users()
    test_user = all_users.find{|u| u.id == @test_user_id}
    expect(test_user).to_not be_nil

    puts "update user"
    new_name = "Chuck Nevitt"
    user = BOX_CLIENT.update_user(@test_user_id, name: new_name)
    expect(user.name).to eq(new_name)

    #create user is tested in the before method

    puts "delete user"
    result = BOX_CLIENT.delete_user(@test_user_id, force: true)
    expect(result).to eq({})
  end

  it "invokes group operations" do
    puts "create group"
    group = BOX_CLIENT.create_group(TEST_GROUP_NAME)
    expect(group.name).to eq(TEST_GROUP_NAME)
    test_group_id = group.id

    puts "inspect groups"
    groups = BOX_CLIENT.groups
    test_group = groups.find{|g| g.name == TEST_GROUP_NAME}
    expect(test_group).to_not be_nil

    puts "update group"
    new_name = "Test Boxr Group Renamed"
    group = BOX_CLIENT.update_group(test_group_id, new_name)
    expect(group.name).to eq(new_name)
    group = BOX_CLIENT.rename_group(test_group_id,TEST_GROUP_NAME)
    expect(group.name).to eq(TEST_GROUP_NAME)

    puts "add user to group"
    group_membership = BOX_CLIENT.add_user_to_group(@test_user_id, test_group_id)
    expect(group_membership.user.id).to eq(@test_user_id)
    expect(group_membership.group.id).to eq(test_group_id)
    membership_id = group_membership.id

    puts "inspect group membership"
    group_membership = BOX_CLIENT.group_membership(membership_id)
    expect(group_membership.id).to eq(membership_id)

    puts "inspect group memberships"
    group_memberships = BOX_CLIENT.group_memberships(test_group_id)
    expect(group_memberships.count).to eq(1)
    expect(group_memberships.first.id).to eq(membership_id)

    puts "inspect group memberships for a user"
    group_memberships = BOX_CLIENT.group_memberships_for_user(@test_user_id)
    expect(group_memberships.count).to eq(1)
    expect(group_memberships.first.id).to eq(membership_id)

    puts "inspect group memberships for me"
    #this is whatever user your developer token is tied to
    group_memberships = BOX_CLIENT.group_memberships_for_me
    expect(group_memberships).to be_a(Array)

    puts "update group membership"
    group_membership = BOX_CLIENT.update_group_membership(membership_id, :admin)
    expect(group_membership.role).to eq("admin")

    puts "delete group membership"
    result = BOX_CLIENT.delete_group_membership(membership_id)
    expect(result).to eq({})
    group_memberships = BOX_CLIENT.group_memberships_for_user(@test_user_id)
    expect(group_memberships.count).to eq(0)

    puts "inspect group collaborations"
    group_collaboration = BOX_CLIENT.add_collaboration(@test_folder_id, {id: test_group_id, type: :group}, :editor)
    expect(group_collaboration.accessible_by.id).to eq(test_group_id)

    puts "delete group"
    response = BOX_CLIENT.delete_group(test_group_id)
    expect(response).to eq({})
  end

  it "invokes comment operations" do 
    new_file = BOX_CLIENT.upload_file("./spec/test_files/#{TEST_FILE_NAME}", @test_folder_id)
    test_file_id = new_file.id

    puts "add comment to file"
    comment = BOX_CLIENT.add_comment_to_file(test_file_id, message: COMMENT_MESSAGE)
    expect(comment.message).to eq(COMMENT_MESSAGE)
    COMMENT_ID = comment.id

    puts "reply to comment"
    reply = BOX_CLIENT.reply_to_comment(COMMENT_ID, message: REPLY_MESSAGE)
    expect(reply.message).to eq(REPLY_MESSAGE)

    puts "get file comments"
    comments = BOX_CLIENT.file_comments(test_file_id)
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

  it "invokes collaborations operations" do
    puts "add collaboration"
    collaboration = BOX_CLIENT.add_collaboration(@test_folder_id, {id: @test_user_id, type: :user}, :editor)
    expect(collaboration.accessible_by.id).to eq(@test_user_id)
    collaboration_id = collaboration.id

    puts "inspect collaboration"
    collaboration = BOX_CLIENT.collaboration(collaboration_id)
    expect(collaboration.id).to eq(collaboration_id)

    puts "edit collaboration"
    collaboration = BOX_CLIENT.edit_collaboration(collaboration_id, role: "viewer uploader")
    expect(collaboration.role).to eq("viewer uploader")

    puts "inspect folder collaborations"
    collaborations = BOX_CLIENT.folder_collaborations(@test_folder_id)
    expect(collaborations.count).to eq(1)
    expect(collaborations[0].id).to eq(collaboration_id)

    puts "remove collaboration"
    result = BOX_CLIENT.remove_collaboration(collaboration_id)
    expect(result).to eq({})
    collaborations = BOX_CLIENT.folder_collaborations(@test_folder_id)
    expect(collaborations.count).to eq(0)

    puts "inspect pending collaborations"
    pending_collaborations = BOX_CLIENT.pending_collaborations
    expect(pending_collaborations).to eq([])
  end

  it "invokes task operations" do
    new_file = BOX_CLIENT.upload_file("./spec/test_files/#{TEST_FILE_NAME}", @test_folder_id)
    test_file_id = new_file.id
    collaboration = BOX_CLIENT.add_collaboration(@test_folder_id, {id: @test_user_id, type: :user}, :editor)

    puts "create task"
    new_task = BOX_CLIENT.create_task(test_file_id, message: TEST_TASK_MESSAGE)
    expect(new_task.message).to eq(TEST_TASK_MESSAGE)
    TEST_TASK_ID = new_task.id

    puts "inspect file tasks"
    tasks = BOX_CLIENT.file_tasks(test_file_id)
    expect(tasks.first.id).to eq(TEST_TASK_ID)

    puts "inspect task"
    task = BOX_CLIENT.task(TEST_TASK_ID)
    expect(task.id).to eq(TEST_TASK_ID)

    puts "update task"
    NEW_TASK_MESSAGE = "new task message"
    updated_task = BOX_CLIENT.update_task(TEST_TASK_ID, message: NEW_TASK_MESSAGE)
    expect(updated_task.message).to eq(NEW_TASK_MESSAGE)

    puts "create task assignment"
    task_assignment = BOX_CLIENT.create_task_assignment(TEST_TASK_ID, assign_to_id: @test_user_id)
    expect(task_assignment.assigned_to.id).to eq(@test_user_id)
    task_assignment_id = task_assignment.id

    puts "inspect task assignment"
    task_assignment = BOX_CLIENT.task_assignment(task_assignment_id)
    expect(task_assignment.id).to eq(task_assignment_id)

    puts "inspect task assignments"
    task_assignments = BOX_CLIENT.task_assignments(TEST_TASK_ID)
    expect(task_assignments.count).to eq(1)
    expect(task_assignments[0].id).to eq(task_assignment_id)

    #TODO: can't do this test yet because the test user needs to confirm their email address before you can do this
    puts "update task assignment"
    expect {
              box_client_as_test_user = Boxr::Client.new(ENV['BOX_DEVELOPER_TOKEN'], as_user_id: @test_user_id)
              new_message = "Updated task message"
              task_assignment = box_client_as_test_user.update_task_assignment(TEST_TASK_ID, resolution_state: :completed)
              expect(task_assignment.resolution_state).to eq('completed')
            }.to raise_error

    puts "delete task assignment"
    result = BOX_CLIENT.delete_task_assignment(task_assignment_id)
    expect(result).to eq({})

    puts "delete task"
    result = BOX_CLIENT.delete_task(TEST_TASK_ID)
    expect(result).to eq({})
  end

  it "invokes metadata operations" do
    new_file = BOX_CLIENT.upload_file("./spec/test_files/#{TEST_FILE_NAME}", @test_folder_id)
    test_file_id = new_file.id

    puts "create metadata"
    meta = {"a" => "hello", "b" => "world"}
    metadata = BOX_CLIENT.create_metadata(test_file_id, meta)
    expect(metadata.a).to eq("hello")

    puts "update metadata"
    metadata = BOX_CLIENT.update_metadata(test_file_id, [{op: :replace, path: "/b", value: "there"}])
    expect(metadata.b).to eq("there")

    puts "get metadata"
    metadata = BOX_CLIENT.metadata(test_file_id)
    expect(metadata.a).to eq("hello")

    puts "delete metadata"
    result = BOX_CLIENT.delete_metadata(test_file_id)
    expect(result).to eq({})
  end

  it "invokes search operations" do
    #the issue with this test is that Box can take between 5-10 minutes to index any content uploaded; this is just a smoke test
    #so we are searching for something that should return zero results
    puts "perform search"
    results = BOX_CLIENT.search("sdlfjuwnsljsdfuqpoiqweouyvnnadsfkjhiuweruywerbjvhvkjlnasoifyukhenlwdflnsdvoiuawfydfjh")
    expect(results).to eq([])
  end

  it "invokes a Boxr exception" do
    expect { BOX_CLIENT.folder(1)}.to raise_error
  end

end
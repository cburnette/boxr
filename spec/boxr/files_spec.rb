require 'spec_helper'

#rake spec SPEC_OPTS="-e \"invokes file operations"\"
describe "file operations" do
  it "invokes file operations" do
    puts "upload a file"
    new_file = BOX_CLIENT.upload_file("./spec/test_files/#{TEST_FILE_NAME}", @test_folder)
    expect(new_file.name).to eq(TEST_FILE_NAME)
    test_file = new_file

    puts "upload a file with custom name"
    new_file = BOX_CLIENT.upload_file("./spec/test_files/#{TEST_FILE_NAME}", @test_folder, name: TEST_FILE_NAME_CUSTOM)
    expect(new_file.name).to eq(TEST_FILE_NAME_CUSTOM)

    puts "get file using path"
    file = BOX_CLIENT.file_from_path("/#{TEST_FOLDER_NAME}/#{TEST_FILE_NAME}")
    expect(file.id).to eq(test_file.id)

    puts "get file download url"
    download_url = BOX_CLIENT.download_url(test_file)
    expect(download_url).to start_with("https://")

    puts "get file info"
    file_info = BOX_CLIENT.file(test_file)
    expect(file_info.id).to eq(test_file.id)

    puts "get file preview link"
    preview_url = BOX_CLIENT.preview_url(test_file)
    expect(preview_url).to start_with("https://")

    puts "update file"
    new_description = 'this file is used to test Boxr'
    tags = ['tag one','tag two']
    updated_file_info = BOX_CLIENT.update_file(test_file, description: new_description, tags: tags)
    expect(updated_file_info.description).to eq(new_description)
    tag_file_info = BOX_CLIENT.file(updated_file_info, fields: [:tags])
    expect(tag_file_info.tags.length).to eq(2)

    puts "lock file"
    expires_at_utc = Time.now.utc + (60*60*24) #one day from now
    locked_file = BOX_CLIENT.lock_file(test_file, expires_at: expires_at_utc, is_download_prevented: true)
    locked_file = BOX_CLIENT.file(locked_file, fields: [:lock])
    expect(locked_file.lock.type).to eq('lock')
    expect(locked_file.lock.expires_at).to_not be_nil
    expect(locked_file.lock.is_download_prevented).to eq(true)

    puts "unlock file"
    unlocked_file = BOX_CLIENT.unlock_file(locked_file)
    unlocked_file = BOX_CLIENT.file(unlocked_file, fields: [:lock])
    expect(unlocked_file.lock).to be_nil

    puts "download file"
    file = BOX_CLIENT.download_file(test_file)
    f = File.open("./spec/test_files/#{DOWNLOADED_TEST_FILE_NAME}", 'w+')
    f.write(file)
    f.close
    expect(FileUtils.identical?("./spec/test_files/#{TEST_FILE_NAME}","./spec/test_files/#{DOWNLOADED_TEST_FILE_NAME}")).to eq(true)
    File.delete("./spec/test_files/#{DOWNLOADED_TEST_FILE_NAME}")

    puts "upload new version of file"
    new_version = BOX_CLIENT.upload_new_version_of_file("./spec/test_files/#{TEST_FILE_NAME}", test_file)
    expect(new_version.id).to eq(test_file.id)

    puts "inspect versions of file"
    versions = BOX_CLIENT.versions_of_file(test_file)
    expect(versions.count).to eq(1) #the reason this is 1 instead of 2 is that Box considers 'versions' to be a versions other than 'current'
    v1 = versions.first

    puts "promote old version of file"
    newer_version = BOX_CLIENT.promote_old_version_of_file(test_file, v1)
    versions = BOX_CLIENT.versions_of_file(test_file)
    expect(versions.count).to eq(2)

    puts "delete old version of file"
    result = BOX_CLIENT.delete_old_version_of_file(test_file,v1)
    versions = BOX_CLIENT.versions_of_file(test_file)
    expect(versions.count).to eq(2) #this is still 2 because with Box you can restore a trashed old version

    puts "get file thumbnail"
    thumb = BOX_CLIENT.thumbnail(test_file)
    expect(thumb).not_to be_nil

    puts "create shared link for file"
    updated_file = BOX_CLIENT.create_shared_link_for_file(test_file, access: :open)
    expect(updated_file.shared_link.access).to eq("open")

    puts "create password-protected shared link for file"
    updated_file = BOX_CLIENT.create_shared_link_for_file(test_file, password: 'password')
    expect(updated_file.shared_link.is_password_enabled).to eq(true)

    puts "disable shared link for file"
    updated_file = BOX_CLIENT.disable_shared_link_for_file(test_file)
    expect(updated_file.shared_link).to be_nil

    puts "copy file"
    new_file_name = "copy of #{TEST_FILE_NAME}"
    new_file = BOX_CLIENT.copy_file(test_file, @test_folder, name: new_file_name)
    expect(new_file.name).to eq(new_file_name)
    NEW_FILE = new_file

    puts "move file"
    new_folder = BOX_CLIENT.create_folder(SUB_FOLDER_NAME, @test_folder)
    test_file = BOX_CLIENT.move_file(test_file, new_folder.id)
    expect(test_file.parent.id).to eq(new_folder.id)

    puts "delete file"
    result = BOX_CLIENT.delete_file(NEW_FILE)
    expect(result).to eq({})

    puts "get trashed file info"
    trashed_file = BOX_CLIENT.trashed_file(NEW_FILE)
    expect(trashed_file.item_status).to eq("trashed")

    puts "restore trashed file"
    restored_file = BOX_CLIENT.restore_trashed_file(NEW_FILE)
    expect(restored_file.item_status).to eq("active")

    puts "trash and permanently delete file"
    BOX_CLIENT.delete_file(NEW_FILE)
    result = BOX_CLIENT.delete_trashed_file(NEW_FILE)
    expect(result).to eq({})
  end
end

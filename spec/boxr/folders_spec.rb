require 'spec_helper'

# rake spec SPEC_OPTS="-e \"invokes folder operations"\"
describe "folder operations" do
  it 'invokes folder operations' do
    puts "get folder using path"
    folder = BOX_CLIENT.folder_from_path(TEST_FOLDER_NAME)
    expect(folder.id).to eq(@test_folder.id)

    puts "get folder info"
    folder = BOX_CLIENT.folder(@test_folder)
    expect(folder.id).to eq(@test_folder.id)

    puts "create new folder"
    new_folder = BOX_CLIENT.create_folder(SUB_FOLDER_NAME, @test_folder)
    expect(new_folder).to be_a BoxrMash
    SUB_FOLDER = new_folder

    puts "update folder"
    updated_folder = BOX_CLIENT.update_folder(SUB_FOLDER, description: SUB_FOLDER_DESCRIPTION)
    expect(updated_folder.description).to eq(SUB_FOLDER_DESCRIPTION)

    puts "copy folder"
    new_folder = BOX_CLIENT.copy_folder(SUB_FOLDER,@test_folder, name: "copy of #{SUB_FOLDER_NAME}")
    expect(new_folder).to be_a BoxrMash
    SUB_FOLDER_COPY = new_folder

    puts "create shared link for folder"
    updated_folder = BOX_CLIENT.create_shared_link_for_folder(@test_folder, access: :open)
    expect(updated_folder.shared_link.access).to eq("open")

    puts "create password-protected shared link for folder"
    updated_folder = BOX_CLIENT.create_shared_link_for_folder(@test_folder, password: 'password')
    expect(updated_folder.shared_link.is_password_enabled).to eq(true)
    shared_link = updated_folder.shared_link.url

    puts "inspect shared link"
    shared_item = BOX_CLIENT.shared_item(shared_link)
    expect(shared_item.id).to eq(@test_folder.id)

    puts "disable shared link for folder"
    updated_folder = BOX_CLIENT.disable_shared_link_for_folder(@test_folder)
    expect(updated_folder.shared_link).to be_nil

    puts "move folder"
    folder_to_move = BOX_CLIENT.create_folder("Folder to move", @test_folder)
    folder_to_move_into = BOX_CLIENT.create_folder("Folder to move into", @test_folder)
    folder_to_move = BOX_CLIENT.move_folder(folder_to_move, folder_to_move_into)
    expect(folder_to_move.parent.id).to eq(folder_to_move_into.id)

    puts "delete folder"
    result = BOX_CLIENT.delete_folder(SUB_FOLDER_COPY, recursive: true)
    expect(result).to eq ({})

    puts "inspect the trash"
    trash = BOX_CLIENT.trash()
    expect(trash).to be_a Array

    puts "inspect trashed folder"
    trashed_folder = BOX_CLIENT.trashed_folder(SUB_FOLDER_COPY)
    expect(trashed_folder.item_status).to eq("trashed")

    puts "restore trashed folder"
    restored_folder = BOX_CLIENT.restore_trashed_folder(SUB_FOLDER_COPY)
    expect(restored_folder.item_status).to eq("active")

    puts "trash and permanently delete folder"
    BOX_CLIENT.delete_folder(SUB_FOLDER_COPY, recursive: true)
    result = BOX_CLIENT.delete_trashed_folder(SUB_FOLDER_COPY)
    expect(result).to eq({})
  end
end

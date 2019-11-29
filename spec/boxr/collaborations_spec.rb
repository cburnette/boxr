#rake spec SPEC_OPTS="-e \"invokes collaborations operations"\"
describe 'collaborations operations' do
  it "invokes collaborations operations" do
    puts "test setup"
    new_file = BOX_CLIENT.upload_file("./spec/test_files/#{TEST_FILE_NAME}", @test_folder)
    test_group = BOX_CLIENT.create_group(TEST_GROUP_NAME)
    second_test_user = BOX_CLIENT.create_user("Second Test User", login: "second_test_user@#{('a'..'z').to_a.shuffle[0,10].join}.com", role: 'coadmin')

    puts "add collaboration"
    collaboration = BOX_CLIENT.add_collaboration(@test_folder, {id: @test_user.id, type: :user}, :viewer_uploader)
    file_collaboration = BOX_CLIENT.add_collaboration(new_file, {id: second_test_user.id, type: :user}, :viewer, type: :file)
    group_collaboration = BOX_CLIENT.add_collaboration(@test_folder, {id: test_group.id, type: :group}, :editor)
    expect(collaboration.accessible_by.id).to eq(@test_user.id)
    expect(file_collaboration.accessible_by.id).to eq(second_test_user.id)
    expect(group_collaboration.accessible_by.id).to eq(test_group.id)

    COLLABORATION = collaboration
    FILE_COLLABORATION = file_collaboration
    GROUP_COLLABORATION = group_collaboration

    puts "inspect collaboration"
    collaboration = BOX_CLIENT.collaboration(COLLABORATION)
    expect(collaboration.id).to eq(COLLABORATION.id)

    puts "edit collaboration"
    collaboration = BOX_CLIENT.edit_collaboration(COLLABORATION, role: "viewer uploader")
    expect(collaboration.role).to eq("viewer uploader")

    puts "inspect folder collaborations"
    collaborations = BOX_CLIENT.folder_collaborations(@test_folder)
    expect(collaborations.count).to eq(2)
    expect(collaborations[0].id).to eq(COLLABORATION.id)

    puts "inspect file collaborations"
    collaborations = BOX_CLIENT.file_collaborations(new_file)
    expect(collaborations.count).to eq(3)
    expect(collaborations[0].id).to eq(FILE_COLLABORATION.id)

    puts "inspect group collaborations"
    collaborations = BOX_CLIENT.group_collaborations(test_group)
    expect(collaborations.count).to eq(1)
    expect(collaborations[0].id).to eq(GROUP_COLLABORATION.id)

    puts "remove collaboration"
    result = BOX_CLIENT.remove_collaboration(COLLABORATION)
    expect(result).to eq({})
    collaborations = BOX_CLIENT.folder_collaborations(@test_folder)
    expect(collaborations.count).to eq(1)

    puts "inspect pending collaborations"
    pending_collaborations = BOX_CLIENT.pending_collaborations
    expect(pending_collaborations).to eq([])

    puts "add invalid collaboration"
    expect { BOX_CLIENT.add_collaboration(@test_folder, {id: @test_user.id, type: :user}, :invalid_role)}.to raise_error{Boxr::BoxrError}

    puts "test teardown"
    BOX_CLIENT.delete_file(new_file)
    BOX_CLIENT.delete_group(test_group)
    BOX_CLIENT.delete_user(second_test_user, force: true)
  end
end

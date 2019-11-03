#rake spec SPEC_OPTS="-e \"invokes chunked uploads operations"\"
describe "chunked uploads operations" do
  it "invokes chunked uploads operations" do
    puts "create chunked upload session"
    new_session = BOX_CLIENT.chunked_upload_create_session_new_file("./spec/test_files/#{TEST_LARGE_FILE_NAME}", @test_folder)
    expect(new_session.id).not_to be_nil

    puts "get chunked upload session using ID"
    session = BOX_CLIENT.chunked_upload_get_session(new_session.id)
    expect(session.id).to eq(new_session.id)

    puts "get list of chunked upload parts"
    parts = BOX_CLIENT.chunked_upload_list_parts(new_session.id)
    expect(parts).to eq([])

    puts "abort chunked upload session"
    abort_info = BOX_CLIENT.chunked_upload_abort_session(new_session.id)
    expect(abort_info).to eq({})

    puts "upload a large file in chunks"
    new_file = BOX_CLIENT.chunked_upload_file("./spec/test_files/#{TEST_LARGE_FILE_NAME}", @test_folder)
    expect(new_file.name).to eq(TEST_LARGE_FILE_NAME)
    test_file = new_file

    puts "upload new version of a large file in chunks"
    new_version = BOX_CLIENT.chunked_upload_new_version_of_file("./spec/test_files/#{TEST_LARGE_FILE_NAME}", test_file)
    expect(new_version.id).to eq(test_file.id)
  end
end

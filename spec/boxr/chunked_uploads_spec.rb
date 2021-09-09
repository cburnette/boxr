#rake spec SPEC_OPTS="-e \"invokes chunked uploads operations"\"

require "parallel"

describe "chunked uploads operations" do
  it "invokes chunked uploads session-related operations" do
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
  end

  shared_examples "chunked uploads data-upload" do |n_threads:|
    fit "uploads chunked uploads upload-related operations (threads: #{n_threads})" do
        puts "upload a large file in chunks"
        new_file = BOX_CLIENT.chunked_upload_file("./spec/test_files/#{TEST_LARGE_FILE_NAME}", @test_folder, n_threads: n_threads)
        expect(new_file.name).to eq(TEST_LARGE_FILE_NAME)
        test_file = new_file

        puts "upload new version of a large file in chunks"
        new_version = BOX_CLIENT.chunked_upload_new_version_of_file("./spec/test_files/#{TEST_LARGE_FILE_NAME}", test_file, n_threads: n_threads)
        expect(new_version.id).to eq(test_file.id)

        puts "upload a large file in chunks from IO stream"
        filename = "yet another large file.txt"
        io = StringIO.new
        io << "1" * 21 * 1024**2
        io.rewind
        new_file = BOX_CLIENT.chunked_upload_file_from_io(io, @test_folder, filename, n_threads: n_threads)
        expect(new_file.name).to eq(filename)
        test_file = new_file

        puts "upload new version of a large file in chunks from IO stream"
        io.rewind
        new_version = BOX_CLIENT.chunked_upload_new_version_of_file_from_io(io, test_file, filename, n_threads: n_threads)
        expect(new_version.id).to eq(test_file.id)
    end
  end

  it_behaves_like "chunked uploads data-upload", n_threads: 1
  it_behaves_like "chunked uploads data-upload", n_threads: 2
end

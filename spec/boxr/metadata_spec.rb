require 'spec_helper'

#rake spec SPEC_OPTS="-e \"invokes file metadata operations"\"
describe 'file metadata operations' do
  it "invokes file metadata operations" do
    test_file = BOX_CLIENT.upload_file("./spec/test_files/#{TEST_FILE_NAME}", @test_folder)

    puts "create metadata"
    meta = {"a" => "hello", "b" => "world"}
    metadata = BOX_CLIENT.create_metadata(test_file, meta)
    expect(metadata.a).to eq("hello")

    puts "update metadata"
    metadata = BOX_CLIENT.update_metadata(test_file, {op: :replace, path: "/b", value: "there"})
    expect(metadata.b).to eq("there")
    metadata = BOX_CLIENT.update_metadata(test_file, [{op: :replace, path: "/b", value: "friend"}])
    expect(metadata.b).to eq("friend")

    puts "get metadata"
    metadata = BOX_CLIENT.metadata(test_file)
    expect(metadata.a).to eq("hello")

    puts "delete metadata"
    result = BOX_CLIENT.delete_metadata(test_file)
    expect(result).to eq({})
  end

  #rake spec SPEC_OPTS="-e \"invokes folder metadata operations"\"
  #NOTE: this test will fail unless you create a metadata template called 'test' with two attributes: 'a' of type text, and 'b' of type text
  it "invokes folder metadata operations" do
    new_folder = BOX_CLIENT.create_folder(SUB_FOLDER_NAME, @test_folder)

    puts "create folder metadata"
    meta = {"a" => "hello", "b" => "world"}
    metadata = BOX_CLIENT.create_folder_metadata(new_folder, meta, "enterprise", "test")
    expect(metadata.a).to eq("hello")

    puts "update folder metadata"
    metadata = BOX_CLIENT.update_folder_metadata(new_folder, {op: :replace, path: "/b", value: "there"}, "enterprise", "test")
    expect(metadata.b).to eq("there")
    metadata = BOX_CLIENT.update_folder_metadata(new_folder, [{op: :replace, path: "/b", value: "friend"}], "enterprise", "test")
    expect(metadata.b).to eq("friend")

    puts "get folder metadata"
    metadata = BOX_CLIENT.folder_metadata(new_folder, "enterprise", "test")
    expect(metadata.a).to eq("hello")

    puts "delete folder metadata"
    result = BOX_CLIENT.delete_folder_metadata(new_folder, "enterprise", "test")
    expect(result).to eq({})
  end
end

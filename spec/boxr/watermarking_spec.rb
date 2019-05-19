require 'spec_helper'

#rake spec SPEC_OPTS="-e \"invokes watermarking operations"\"
describe 'watermarking operations' do
  it 'invokes watermarking operations' do
    test_file = BOX_CLIENT.upload_file("./spec/test_files/#{TEST_FILE_NAME}", @test_folder)
    folder = BOX_CLIENT.folder(@test_folder)

    puts "apply watermark on file"
    watermark = BOX_CLIENT.apply_watermark_on_file(test_file)
    expect(watermark.watermark).to_not be_nil

    puts "get watermark on file"
    watermark = BOX_CLIENT.get_watermark_on_file(test_file)
    expect(watermark.watermark).to_not be_nil

    puts "remove watermark on file"
    result = BOX_CLIENT.remove_watermark_on_file(test_file)
    expect(result).to eq({})

    puts "apply watermark on folder"
    watermark = BOX_CLIENT.apply_watermark_on_folder(folder)
    expect(watermark.watermark).to_not be_nil

    puts "get watermark on folder"
    watermark = BOX_CLIENT.get_watermark_on_folder(folder)
    expect(watermark.watermark).to_not be_nil

    puts "remove watermark on folder"
    result = BOX_CLIENT.remove_watermark_on_folder(folder)
    expect(result).to eq({})
  end
end

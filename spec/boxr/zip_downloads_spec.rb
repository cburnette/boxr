# frozen_string_literal: true

require 'zip'

# rake spec SPEC_OPTS="-e \"invokes zip downloads operations"\"
describe 'zip downloads operations' do
  it 'invokes zip downloads operations' do
    test_file_path = "./spec/test_files/#{TEST_FILE_NAME}"
    download_zip_path = "./spec/test_files/#{DOWNLOADED_ZIP_TEST_FILE_NAME}"
    unzip_path = "./spec/test_files/#{DOWNLOADED_TEST_FILE_NAME}"

    puts 'upload a file'
    new_file = BOX_CLIENT.upload_file(test_file_path, @test_folder)
    expect(new_file.name).to eq(TEST_FILE_NAME)

    puts 'create zip downloads'
    new_zip_download = BOX_CLIENT.create_zip_download(
      [{ id: new_file.id, type: 'file' }],
      download_file_name: 'test.zip'
    )
    expect(new_zip_download.download_url).to match(URI::regexp)
    expect(new_zip_download.status_url).to match(URI::regexp)

    # download and unzip
    URI.open(new_zip_download.download_url) do |zip_content|
      File.open(download_zip_path, 'w+') { |file| file.write(zip_content.read) }
    end
    Zip::File.open(download_zip_path) do |zip_file|
      zip_file.each { |entry| entry.extract(unzip_path) }
    end

    expect(FileUtils.identical?(test_file_path, unzip_path)).to eq(true)
  ensure
    File.delete(unzip_path)
    File.delete(download_zip_path)
  end
end

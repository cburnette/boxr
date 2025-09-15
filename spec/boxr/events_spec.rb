# rake spec SPEC_OPTS="-e \"invokes event operations"\"
require 'spec_helper'
describe 'event operations' do
  it 'invokes event operations', :skip_reset do
    unless ENV['BOX_DEVELOPER_TOKEN']
      skip 'BOX_DEVELOPER_TOKEN environment variable not set. Skipping integration test.'
    end
    puts 'create test folder for events'
    test_folder = BOX_CLIENT.create_folder("Events Test Folder #{Time.now.to_i}", Boxr::ROOT)

    puts 'upload test file to generate events'
    test_file = BOX_CLIENT.upload_file("./spec/test_files/#{TEST_FILE_NAME}", test_folder)

    puts 'get initial stream position'
    initial_events = BOX_CLIENT.user_events(0, limit: 10)
    expect(initial_events).not_to be_nil
    expect(initial_events.events).to be_an(Array)
    expect(initial_events.next_stream_position).not_to be_nil

    puts 'perform actions to generate events'
    BOX_CLIENT.update_file(test_file, description: 'Updated for events test')
    BOX_CLIENT.create_shared_link_for_file(test_file, access: :open)
    BOX_CLIENT.disable_shared_link_for_file(test_file)

    puts 'wait for events to be available'
    sleep BOX_SERVER_SLEEP

    puts 'get user events with stream position'
    events_response = BOX_CLIENT.user_events(initial_events.next_stream_position, limit: 50)
    expect(events_response).not_to be_nil
    expect(events_response.events).to be_an(Array)
    expect(events_response.next_stream_position).not_to be_nil
    expect(events_response.chunk_size).not_to be_nil

    puts 'verify events contain expected actions'
    event_types = events_response.events.map(&:event_type)
    expect(event_types).not_to be_empty
    puts "Generated event types: #{event_types.uniq.join(', ')}"

    # Check for any file-related events (more flexible than specific event types)
    file_events = event_types.select { |type| type.include?('ITEM_') }
    expect(file_events).not_to be_empty

    puts 'test user events with different stream types'
    all_events = BOX_CLIENT.user_events(0, stream_type: :all, limit: 10)
    expect(all_events.events).to be_an(Array)

    admin_events = BOX_CLIENT.user_events(0, stream_type: :admin_logs, limit: 10)
    expect(admin_events.events).to be_an(Array)

    puts 'test enterprise events'
    enterprise_events = BOX_CLIENT.enterprise_events(limit: 10)
    expect(enterprise_events).not_to be_nil
    expect(enterprise_events.events).to be_an(Array)
    expect(enterprise_events.next_stream_position).not_to be_nil

    puts 'test enterprise events with date filters'
    yesterday = Time.now - 86_400
    today = Time.now
    filtered_events = BOX_CLIENT.enterprise_events(
      created_after: yesterday,
      created_before: today,
      limit: 10
    )
    expect(filtered_events.events).to be_an(Array)

    puts 'test enterprise events with event type filter'
    file_events = BOX_CLIENT.enterprise_events(event_type: 'ITEM_UPDATE', limit: 10)
    expect(file_events.events).to be_an(Array)

    puts 'test enterprise events stream with block'
    stream_events = []
    BOX_CLIENT.enterprise_events_stream(0, limit: 5, refresh_period: 1) do |response|
      stream_events.concat(response.events)
      break if stream_events.length >= 5
    end
    expect(stream_events).to be_an(Array)

    puts 'cleanup test data'
    begin
      BOX_CLIENT.delete_file(test_file)
    rescue StandardError => e
      puts "Error deleting file #{test_file.name}: #{e.message}"
    end
    begin
      BOX_CLIENT.delete_folder(test_folder, recursive: true)
    rescue StandardError => e
      puts "Error deleting folder #{test_folder.name}: #{e.message}"
    end
  end
end

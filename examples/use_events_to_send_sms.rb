# frozen_string_literal: true

require 'dotenv'; Dotenv.load('../.env')
require 'boxr'
require 'twilio-ruby' # make sure you 'gem install twilio-ruby'

# Get your Account Sid, Auth Token, and phone number from twilio.com/user/account
TWILIO_PHONE_NUMBER = ENV['TWILIO_PHONE_NUMBER']
BOX_TRIGGER_EVENT = 'UPLOAD'

@twilio_client = Twilio::REST::Client.new(ENV['TWILIO_ACCOUNT_SID'], ENV['TWILIO_AUTH_TOKEN'])
@box_client = Boxr::Client.new(ENV['BOX_DEVELOPER_TOKEN'])

def send_sms_to_box_user(recipient, message)
  phone = @box_client.user(recipient, fields: [:phone]).phone
  unless phone.nil? || phone.empty?
    begin
      full_phone = "+1#{phone}"
      @twilio_client.account.messages.create(
        from: ENV['TWILIO_PHONE_NUMBER'],
        to: full_phone,
        body: message
      )
      puts "Sent SMS to user #{recipient.name} at #{full_phone}"
    rescue Twilio::REST::RequestError => e
      puts e.message
    end
  end
rescue Boxr::BoxrError => e
  # most likely error is that a collaborator is an external user and Box threw a 404
  puts e.message
end

# need to look back in time to make sure we get a valid stream position;
# normally your app will be persisting the last known stream position and you wouldn't have to look this up
now = Time.now.utc
start_date = now - (60 * 60 * 24) # one day ago
result = @box_client.enterprise_events(created_after: start_date, created_before: now)

# now that we have the latest stream position let's start monitoring in real-time
@box_client.enterprise_events_stream(result.next_stream_position, event_type: BOX_TRIGGER_EVENT, refresh_period: 5) do |result|
  if result.events.count == 0
    puts "no new #{BOX_TRIGGER_EVENT} events..."
  else
    puts "detected #{result.events.count} new #{BOX_TRIGGER_EVENT}"
    result.events.each do |e|
      folder = @box_client.folder(e.source.parent)
      message = "Document '#{e.source.item_name}' uploaded to folder '#{folder.name}' by #{e.created_by.name}"

      # first notify the folder owner
      send_sms_to_box_user(folder.owned_by, message)

      # now notify collaborators
      user_collabs = @box_client.folder_collaborations(folder).select { |c| c.accessible_by.type == 'user' }
      user_collabs.each { |c| send_sms_to_box_user(c.accessible_by, message) }
    end
  end
end

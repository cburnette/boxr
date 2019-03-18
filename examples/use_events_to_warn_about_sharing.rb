# frozen_string_literal: true

require 'dotenv'; Dotenv.load('../.env')
require 'boxr'
require 'mailgun' # make sure you 'gem install mailgun-ruby'

BOX_TRIGGER_EVENT = 'ITEM_SHARED_UPDATE,COLLABORATION_INVITE'
FROM_EMAIL = "box-admin@#{ENV['MAILGUN_SENDING_DOMAIN']}"
VALID_COLLABORATION_DOMAIN = ENV['VALID_COLLABORATION_DOMAIN'] # i.e. 'your-company.com'

@mailgun_client = Mailgun::Client.new ENV['MAILGUN_API_KEY']
@box_client = Boxr::Client.new(ENV['BOX_DEVELOPER_TOKEN'])

def file_warning_text(event)
  %(
  Our records indicate that you just created an open shared link for the document '#{event.source.item_name}'
  located in the folder '#{event.source.parent.name}'.

  If you meant to do this, please ignore this email.  Otherwise, please update this shared link
  so that it is no longer open access.

  Thanks,
  Your Box Admin
  )
end

def folder_warning_text(event)
  %(
  Our records indicate that you just created an open shared link for the folder '#{event.source.item_name}'.

  If you meant to do this, please ignore this email.  Otherwise, please update this shared link
  so that it is no longer open access.

  Thanks,
  Your Box Admin
  )
end

def collaboration_warning_text(event)
  %(
  Our records indicate that you just invited #{event.accessible_by.login} to be an external collaborator
  with the role of #{event.additional_details.role} in the folder '#{event.source.folder_name}'.

  If you meant to do this, please ignore this email.  Otherwise, please remove this collaborator.

  Thanks,
  Your Box Admin
  )
end

def send_email_to_box_user(from, to, subject, text)
  # this example code uses Mailgun to send email, but you can use any standard SMTP server
  message_params = { from: from, to: to, subject: subject, text: text }
  @mailgun_client.send_message ENV['MAILGUN_SENDING_DOMAIN'], message_params

  puts "Sent email to #{to} with subject '#{subject}'"
end

# need to look back in time to make sure we get a valid stream position;
# normally your app will be persisting the last known stream position and you wouldn't have to look this up
now = Time.now.utc
start_date = now - (60 * 60 * 24) # one day ago
result = @box_client.enterprise_events(created_after: start_date, created_before: now)

# now that we have the latest stream position let's start monitoring in real-time
@box_client.enterprise_events_stream(result.next_stream_position, event_type: BOX_TRIGGER_EVENT, refresh_period: 60) do |result|
  if result.events.count == 0
    puts "no new #{BOX_TRIGGER_EVENT} events..."
  else
    result.events.each do |e|
      puts "detected new #{e.event_type}"
      if e.event_type == 'ITEM_SHARED_UPDATE'
        if e.source.item_type == 'file'
          file = @box_client.file(e.source.item_id)
          if file.shared_link.effective_access == 'open'
            send_email_to_box_user(FROM_EMAIL, e.created_by.login, 'WARNING: Open Shared Link Detected', file_warning_text(e))
          end
        elsif e.source.item_type == 'folder'
          folder = @box_client.folder(e.source.item_id)
          if folder.shared_link.effective_access == 'open'
            send_email_to_box_user(FROM_EMAIL, e.created_by.login, 'WARNING: Open Shared Link Detected', folder_warning_text(e))
          end
        end
      elsif e.event_type == 'COLLABORATION_INVITE'
        email = e.accessible_by.login
        domain = email.split('@').last
        unless domain.casecmp(VALID_COLLABORATION_DOMAIN).zero?
          send_email_to_box_user(FROM_EMAIL, e.created_by.login, 'WARNING: External Collaborator Detected', collaboration_warning_text(e))
        end
      end
    end
  end
end

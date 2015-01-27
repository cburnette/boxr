# Boxr
Boxr is a Ruby client library for the Box V2 Content API that covers 100% of the underlying REST API.  Box employees affectionately refer to one another as Boxers, hence the name of this gem.  

The purpose of this gem is to provide a clear, efficient, and intentional method of interacting with the Box Content API. As with any SDK that wraps a REST API, it is important to fully understand the Box Content API at the REST endpoint level.  You are strongly encouraged to read through the Box documentation located [here](https://developers.box.com/docs/).

The full RubyDocs for Boxr can be found [here](http://www.rubydoc.info/gems/boxr/Boxr/Client).  You are also encouraged to rely heavily on the source code found in the [lib/boxr](https://github.com/cburnette/boxr/tree/master/lib/boxr) directory of this gem, as well as on the integration test found [here](https://github.com/cburnette/boxr/blob/master/spec/boxr_spec.rb).

## Installation
Add this line to your application's Gemfile:

```ruby
gem 'boxr'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install boxr

## Usage
Super-fast instructions:

1. go to http://developers.box.com
2. find or create your Box Content API app for testing
3. click 'Edit Application'
4. check the boxes for 'Read and write all files and folders' and 'Manage an enterprise'
5. click 'Create a developer token'
6. copy the token and use it in the code below in place of {BOX_DEVELOPER_TOKEN}

```ruby
require 'boxr'

client = Boxr::Client.new('{BOX_DEVELOPER_TOKEN}')
items = client.folder_items(Boxr::ROOT)
items.each {|i| puts i.name}
```

### Creating a client
There are a few different ways to create a Boxr client.  The simplest is to use a Box Developer Token (you generate these from your Box app's General Information page).  They last for 60 minutes and you don't have to go through OAuth2.
```ruby
client = Boxr::Client.new('yPDWOvnumUFaKIMrNBg6PGJpWXC0oaFW')

# Alternatively, you can set an environment variable called BOX_DEVELOPER_TOKEN to 
# the value of your current token. By default, Boxr will look for that.

client = Boxr::Client.new  #uses ENV['BOX_DEVELOPER_TOKEN']
```

The next way is to use an access token retrieved after going through the OAuth2 process.  If your application is going to handle refreshing the tokens in a scheduled way (more on this later) then this is the way to go.
```ruby
client = Boxr::Client.new('v2eAXqhZ28WIEpIWeAJcmyamLLt77icP')  #a valid OAuth2 access token

# Boxr will raise an error if this token becomes invalid. It is up to your application to generate
# a new pair of access and refresh tokens in a timely manner.
```

If you want Boxr to automatically refresh the tokens once the access token becomes invalid you can supply a refresh token, along with your client_id and client_secret, and a block that will get invoked when the refresh occurs.
```ruby
token_refresh_callback = lambda {|access, refresh, identifier| some_method_that_saves_them(access, refresh)}
client = Boxr::Client.new('zX3UjFwNerOy5PSWc2WI8aJgMHtAjs8T', 
                          refresh_token: 'dvfzfCQoIcRi7r4Yeuar7mZnaghGWexXlX89sBaRy1hS9e5wFroVVOEM6bs0DwPQ',
                          client_id: 'kplh54vfeagt6jmi4kddg4xdswwvrw8y',
                          client_secret: 'sOsm9ZZ8L8svwrn9FsdulLQVwDizKueU',
                          &token_refresh_callback)
                           
# By default Boxr will look for client_id and client_secret in your environment variables as
# BOX_CLIENT_ID and BOX_CLIENT_SECRET, respectively.  You can omit the two optional parameters above
# if those are present.

# Additionally, you can provide one other parameter called identifier. This can be used, for example, to
# hold the id of the user associated with this Boxr client.  When the callback is invoked this value 
# will be provided.
```
  
### A quick example
Before diving into detailed documentation, let's take a look at how to accomplish a simple task with Boxr.  This script will find a specific folder given its path, upload a file to that folder, and create an open shared link to that file.
```ruby
require 'boxr'

client = Boxr::Client.new  #using ENV['BOX_DEVELOPER_TOKEN']

folder = client.folder_from_path('/some/directory/structure')
file = client.upload_file('test.txt', folder)
file = client.create_shared_link_for_file(file, access: :open)
puts "Shared Link: #{file.shared_link.url}"
```

### Methods
#### [Folders](https://developers.box.com/docs/#folders)
```ruby
folder_from_path(path)

folder_from_id(folder_id, fields: [])
alias :folder :folder_from_id
     
folder_items(folder, fields: [], offset: 0, limit: FOLDER_ITEMS_LIMIT)
      
root_folder_items(fields: [], offset: 0, limit: FOLDER_ITEMS_LIMIT)
      
create_folder(name, parent)
     
update_folder(folder, name: nil, description: nil, parent_id: nil, shared_link: nil,
                folder_upload_email_access: nil, owned_by_id: nil, sync_state: nil, tags: nil,
                can_non_owners_invite: nil, if_match: nil)
     
delete_folder(folder, recursive: false, if_match: nil)
     
copy_folder(folder, dest_folder, name: nil)
      
create_shared_link_for_folder(folder, access: nil, unshared_at: nil, can_download: nil, can_preview: nil)
      
disable_shared_link_for_folder(folder)
     
trash(fields: [], offset: 0, limit: FOLDER_ITEMS_LIMIT)
      
trashed_folder(folder, fields: [])
     
delete_trashed_folder(folder)
      
restore_trashed_folder(folder, name: nil, parent_id: nil)
```
#### [Files](https://developers.box.com/docs/#files)
```ruby
file_from_path(path)

file_from_id(file_id, fields: [])
alias :file :file_from_id

update_file(file, name: nil, description: nil, parent_id: nil, shared_link: nil, tags: nil, if_match: nil)

download_file(file, version: nil, follow_redirect: true)

download_url(file, version: nil)

upload_file(path_to_file, parent, content_created_at: nil, content_modified_at: nil, 
            preflight_check: true, send_content_md5: true)

delete_file(file, if_match: nil)

upload_new_version_of_file(path_to_file, file, content_modified_at: nil, send_content_md5: true, 
                            preflight_check: true, if_match: nil)

versions_of_file(file)

promote_old_version_of_file(file, file_version)

delete_old_version_of_file(file, file_version, if_match: nil)

copy_file(file, parent, name: nil)

thumbnail(file, min_height: nil, min_width: nil, max_height: nil, max_width: nil)

create_shared_link_for_file(file, access: nil, unshared_at: nil, can_download: nil, can_preview: nil)

disable_shared_link_for_file(file)

trashed_file(file, fields: [])

delete_trashed_file(file)

restore_trashed_file(file, name: nil, parent_id: nil)
```
#### [Comments](https://developers.box.com/docs/#comments)
```ruby
file_comments(file, fields: [], offset: 0, limit: DEFAULT_LIMIT)
      
add_comment_to_file(file, message: nil, tagged_message: nil)
     
reply_to_comment(comment_id, message: nil, tagged_message: nil)
      
change_comment(comment, message)
     
comment(comment_id, fields: [])
      
delete_comment(comment)
```
#### [Collaborations](https://developers.box.com/docs/#collaborations)
```ruby
folder_collaborations(folder)
    
add_collaboration(folder, accessible_by, role, fields: [], notify: nil)
     
edit_collaboration(collaboration, role: nil, status: nil)
      
remove_collaboration(collaboration)
      
collaboration(collaboration_id, fields: [], status: nil)
      
pending_collaborations()
```
#### [Events](https://developers.box.com/docs/#events)
```ruby
user_events(stream_position: 0, stream_type: :all, limit: 100)
      
enterprise_events(stream_position: 0, limit: 100, event_type: nil, created_after: nil, created_before: nil)
```
#### [Shared Items](https://developers.box.com/docs/#shared-items)
```ruby
shared_item(shared_link, shared_link_password: nil)
```
#### [Search](https://developers.box.com/docs/#search)
```ruby
search(query, scope: nil, file_extensions: nil, created_at_range: nil, updated_at_range: nil, size_range: nil, 
        owner_user_ids: nil, ancestor_folder_ids: nil, content_types: nil, type: nil, 
        limit: 30, offset: 0)
```
#### [Users](https://developers.box.com/docs/#users)
```ruby
current_user(fields: [])
      
alias :me :current_user

user(user_id, fields: [])
      
all_users(filter_term: nil, fields: [], offset: 0, limit: DEFAULT_LIMIT)
     
create_user(login, name, role: nil, language: nil, is_sync_enabled: nil, job_title: nil,
            phone: nil, address: nil, space_amount: nil, tracking_codes: nil,
            can_see_managed_users: nil, is_external_collab_restricted: nil, status: nil, timezone: nil,
            is_exempt_from_device_limits: nil, is_exempt_from_login_verification: nil)


update_user(user, notify: nil, enterprise: true, name: nil, role: nil, language: nil, is_sync_enabled: nil,
            job_title: nil, phone: nil, address: nil, space_amount: nil, tracking_codes: nil,
            can_see_managed_users: nil, status: nil, timezone: nil, is_exempt_from_device_limits: nil,
            is_exempt_from_login_verification: nil, is_exempt_from_reset_required: nil, is_external_collab_restricted: nil)

delete_user(user, notify: nil, force: nil)
```
#### [Groups](https://developers.box.com/docs/#groups)
```ruby
groups(fields: [], offset: 0, limit: DEFAULT_LIMIT)
      
create_group(name)
     
update_group(group, name)
      
alias :rename_group :update_group

delete_group(group)
     
group_memberships(group, offset: 0, limit: DEFAULT_LIMIT)
      
group_memberships_for_user(user, offset: 0, limit: DEFAULT_LIMIT)
      
group_memberships_for_me(offset: 0, limit: DEFAULT_LIMIT)
      
group_membership(membership_id)
     
add_user_to_group(user, group, role: nil)
      
update_group_membership(membership, role)
      
delete_group_membership(membership)
      
group_collaborations(group, offset: 0, limit: DEFAULT_LIMIT)
```
#### [Tasks](https://developers.box.com/docs/#tasks)
```ruby
file_tasks(file, fields: [])
      
create_task(file, action: :review, message: nil, due_at: nil)
      
task(task_id)
     
update_task(task, action: :review, message: nil, due_at: nil)
      
delete_task(task)
      
task_assignments(task)
      
create_task_assignment(task, assign_to_id: nil, assign_to_login: nil)
      
task_assignment(task)
      
delete_task_assignment(task)
      
update_task_assignment(task, message: nil, resolution_state: nil)
```
#### [Metadata](https://developers.box.com/metadata-api/#crud)
```ruby
create_metadata(file, metadata, type: :properties)
      
metadata(file, type: :properties)
     
update_metadata(file, updates, type: :properties)
     
delete_metadata(file, type: :properties)
```
## Contributing

1. Fork it ( https://github.com/cburnette/boxr/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

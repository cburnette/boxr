# Boxr
Boxr is a Ruby client library for the Box V2 Content API that covers 100% of the underlying REST API.  Box employees affectionately refer to one another as Boxers, hence the name of this gem.  

The purpose of this gem is to provide a clear, efficient, and intentional method of interacting with the Box Content API. As with any SDK that wraps a REST API, it is important to fully understand the Box Content API at the REST endpoint level.  You are strongly encouraged to read through the Box documentation located [here](https://developers.box.com/docs/).

The full RubyDocs for Boxr can be found [here](http://www.rubydoc.info/gems/boxr).  You are also encouraged to rely heavily on the source code found in the [lib/boxr](https://github.com/cburnette/boxr/tree/master/lib/boxr) directory of this gem, as well as on the integration test found [here](https://github.com/cburnette/boxr/blob/master/spec/boxr_spec.rb).

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


## Contributing

1. Fork it ( https://github.com/cburnette/boxr/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

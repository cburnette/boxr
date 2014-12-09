# Boxr

PLEASE NOTE: this is still a work in progress as I need to complete this README, complete the integration test suite, and add a few more convenience methods.  Feel free to try it out, and I'm almost finished with the integration test suite. Thanks!

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

Super-fast instructions for now (much more to come):

1. go to https://developers.box.com
2. find or create your Box Content API app for testing
3. click 'Edit Application'
4. check the boxes for 'Read and write all files and folders' and 'Manage an enterprise'
5. click 'Create a developer token'
6. copy the token and use it in the code below in place of {BOX_DEVELOPER_TOKEN}

```ruby
require 'boxr'

client = Boxr::Client.new({BOX_DEVELOPER_TOKEN})
items = client.folder_items(Boxr::ROOT)
items.each {|i| puts i.name}
```

## Contributing

1. Fork it ( https://github.com/cburnette/boxr/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

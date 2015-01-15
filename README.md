# Boxr

Boxr is a Ruby client library for the Box V2 Content API that covers 100% of the underlying REST API.  Box employees affectionately refer to one another as Boxers, hence the name of this gem.

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

1. go to http://developers.box.com
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

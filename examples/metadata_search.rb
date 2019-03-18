# frozen_string_literal: true

require 'dotenv'; Dotenv.load('../.env')
require 'awesome_print'
require 'boxr'

box_client = Boxr::Client.new(ENV['BOX_DEVELOPER_TOKEN'])

mdfilters = [
  {
    'templateKey' => 'test1',
    'scope' => 'enterprise',
    'filters' => {
      'attrone' => 'blah',
      'attrtwo' => { 'gt' => '4', 'lt' => '7' }
    }
  }
]

results = box_client.search(mdfilters: mdfilters)
ap results

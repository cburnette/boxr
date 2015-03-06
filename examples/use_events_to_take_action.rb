require 'dotenv'; Dotenv.load("../.env")
require 'boxr'
require 'awesome_print'
require 'lru_redux'

client = Boxr::Client.new(ENV['BOX_DEVELOPER_TOKEN'])
cache = LruRedux::Cache.new(1000)


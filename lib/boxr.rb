require 'oj'
require 'httpclient'
require 'hashie'
require 'addressable/template'
require 'jwt'
require 'securerandom'

require 'boxr/version'
require 'boxr/errors'
require 'boxr/client'
require 'boxr/shared_items'
require 'boxr/folders'
require 'boxr/files'
require 'boxr/comments'
require 'boxr/users'
require 'boxr/groups'
require 'boxr/collaborations'
require 'boxr/collections'
require 'boxr/search'
require 'boxr/tasks'
require 'boxr/metadata'
require 'boxr/events'
require 'boxr/auth'
require 'boxr/web_links'

module Enumerable
  def files
    self.select{|i| i.type == 'file'}
  end

  def folders
    self.select{|i| i.type == 'folder'}
  end

  def web_links
    self.select{|i| i.type == 'web_link'}
  end
end

class BoxrMash < Hashie::Mash
  def entries
    self["entries"]
  end

  def size
    self["size"]
  end
end

module Boxr
  Oj.default_options = {:mode => :compat }

  #The root folder in Box is always identified by 0
  ROOT = 0

  #HTTPClient is high-performance, thread-safe, and supports persistent HTTPS connections
  #http://bibwild.wordpress.com/2012/04/30/ruby-http-performance-shootout-redux/
  BOX_CLIENT = HTTPClient.new
  BOX_CLIENT.cookie_manager = nil
  BOX_CLIENT.send_timeout = 3600 #one hour; needed for lengthy uploads
  BOX_CLIENT.agent_name = "Boxr/#{Boxr::VERSION}"
  BOX_CLIENT.transparent_gzip_decompression = true
  #BOX_CLIENT.ssl_config.add_trust_ca("/Users/cburnette/code/ssh-keys/dev_root_ca.pem")

  def self.turn_on_debugging(device=STDOUT)
    BOX_CLIENT.debug_dev = device
    BOX_CLIENT.transparent_gzip_decompression = false
    nil
  end

  def self.turn_off_debugging
    BOX_CLIENT.debug_dev = nil
    BOX_CLIENT.transparent_gzip_decompression = true
    nil
  end
end

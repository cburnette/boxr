require 'oj'
require 'httpclient'
require 'hashie'

require 'boxr/version'
require 'boxr/exceptions'
require 'boxr/client'
require 'boxr/shared_items'
require 'boxr/folders'
require 'boxr/files'
require 'boxr/comments'
require 'boxr/users'
require 'boxr/groups'
require 'boxr/collaborations'
require 'boxr/search'
require 'boxr/tasks'
require 'boxr/metadata'
require 'boxr/events'

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

module Boxr
  Oj.default_options = {:mode => :compat }

	#The root folder in Box is always identified by 0
	ROOT = 0
end

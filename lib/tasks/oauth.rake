require 'dotenv/tasks'
require 'boxr'

namespace :oauth do
	desc "some stuff"
	task :get_tokens, [:client_id] => [:environment] do |task, args|
		
		puts args.client_id
	end
end
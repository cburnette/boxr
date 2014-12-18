require 'dotenv/tasks'
require 'boxr'

#to call this from bash, etc. use: rake oauth:get_tokens[YOUR_CLIENT_ID, YOUR CLIENT_SECRET]

#however, if you use zsh you must call as such: rake 'oauth:get_tokens[YOUR_CLIENT_ID, YOUR CLIENT_SECRET]'
#the single quotes are important for zsh!


namespace :oauth do
	desc "some stuff"
	task :get_tokens, [:client_id, :client_secret] => :environment do |task, args|
		puts args.client_id, args.client_secret

		# print "Whoa! Pushing to production. Type 'pushitrealgood' to continue: "
  #   if STDIN.gets.chomp == 'pushitrealgood'
  #     system "heroku pgbackups:capture -e -a zenph-production" or abort "aborted backing up production database"
  #   else
  #     abort 'task aborted'
  #   end
	end
end
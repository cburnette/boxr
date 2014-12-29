require 'dotenv/tasks'
require 'boxr'

#make sure you have BOX_CLIENT_ID and BOX_CLIENT_SECRET set in your .env file



#to call this from bash, etc. use: rake oauth:get_tokens[YOUR_CLIENT_ID, YOUR CLIENT_SECRET]

#however, if you use zsh you must call as such: rake 'oauth:get_tokens[YOUR_CLIENT_ID, YOUR CLIENT_SECRET]'
#the single quotes are important for zsh!


# namespace :oauth do
# 	desc "some stuff"
# 	task :get_tokens, [:client_id, :client_secret] => :environment do |task, args|
# 		puts args.client_id, args.client_secret

# 		# print "Whoa! Pushing to production. Type 'pushitrealgood' to continue: "
#   #   if STDIN.gets.chomp == 'pushitrealgood'
#   #     system "heroku pgbackups:capture -e -a zenph-production" or abort "aborted backing up production database"
#   #   else
#   #     abort 'task aborted'
#   #   end
# 	end
# end

namespace :oauth do
	desc "something"
	task :get_tokens => :environment do
		oauth_url = Boxr::oauth_url("skljdflkjsdfklj")

		puts oauth_url
	end
end
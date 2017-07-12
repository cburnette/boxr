require 'boxr'
require 'trollop'
require 'json'
require 'awesome_print'
# This script is an example of a one-shot using Boxr to authenticate with RSA keys, get a token, 
# create a directory ("Folder"), upload a file, test existance of a file, and then add users
# to collaborate on the folder via email address.  Lots of digging in docs to make this work 
# as well as some help from the OSS team at Box, so I decided to share it.  
# 
# It uses: 
#   - A Box App service account (no AppUsers are required)
#   - Invitations to collaborators to share files
#   - "Server to Server" authentication (e.g, not the default oauth2 implementation but instead JWT
#
#  Wes Deviers
#  Rosetta Stone


# How to start -
# 1) You want to log in as your Box developer account.
# 2) Create a new App; This test script doesn't need any special permissions so you can turn off all features, as well as
#   - "Perform actions as Users"
#   - "Generate user access tokens"
# 3) Your Enterprise admin will have to grant access to the application
# 4) Download the helpfully generated JSON file + either generate an RSA keypair or upload your own


BOX_UPLOAD_LOCATION = 'Some_Delightful_Folder'

# The script has two basic modes
#  1 - Add a collaboration user to the folder
#  2 - Upload a file

opts = Trollop::options do
  opt :file, "File to upload", :type => String
  opt :user, "User to add for collaboration to folder, user@rosettastone.com", :type => String
  opt :debug, "Turn on call debugging [Expert]", :default => false
  banner <<-EOS
This script does one of two things: upload a file to Box, or add a user to the Box collaboration.
Usage:
    uploader.rb -f filename | uploader.rb -u user

EOS
end

ap opts if opts[:debug]
Trollop::educate unless opts[:file] or opts[:user]

# First we have to grab the enterprise token, even though we don't want to do anything 'enterprisey'
config = JSON.parse(File.read('config.json'))

# Just for ease of use:
enterprise_id = config['enterpriseID']
auth = config['boxAppSettings']['appAuth']
settings = config['boxAppSettings']
ent_token = Boxr::get_enterprise_token(client_id: settings['clientID'], client_secret: settings['clientSecret'],
      enterprise_id: enterprise_id, private_key: auth['privateKey'], public_key_id: auth['publicKeyId'],
      private_key_password: auth['passphrase'])

token = ent_token.access_token.to_s

# Then we use that token to auth.  The token + private key + client_id (which is actually the application ID)
# uniquely identified our junk versus other people's junk.

client = Boxr::Client.new(token)

if opts[:debug]
  # This is protocol (HTTP) debugging.  Don't turn this on unless you're super-serious about debugging
  #Boxr::turn_on_debugging
  require 'syslog/logger'
  @logger = Syslog::Logger.new 'Box Uploader'
  def debug (string)
    @logger.info(string)
    ap string
  end
end


# Make sure the folder we intend to use exists
begin
  folder = client.folder_from_path(BOX_UPLOAD_LOCATION)
rescue Boxr::BoxrError => error
  # An error at this point probably means the path doesn't exist yet  
  begin
    logger("Creating Box directory") if opts[:debug]
    folder = client.create_folder(BOX_UPLOAD_LOCATION,Boxr::ROOT)
  rescue Exception => error
    debug error.message
    folder = nil
  end
end

if folder.nil?
  puts "Cannot find or create designated folder.  Please look into it."
  exit
end

if opts[:user]
  debug "Attempting to add #{opts[:user]} as a collaborator." if opts[:debug]

  # It's not obvious from docs or code that Boxr needs a hash for who we want to add, but in the API
  # docs you can either make it a numeric user ID or an email address via "accessable_by":
  #  https://developer.box.com/reference#add-a-collaboration
  # using id: or login: respectively.  *This* application doesn't have or want access to enterprise features so
  # I had no way to look up users by ID.
  access = { login: opts[:user] }
  begin
    client.add_collaboration(folder, access, 'editor')
  rescue Exception => e
    puts "Adding user failed: #{e.message}"
  end
end

if opts[:file]
  unless File.file?(opts[:file])
    puts "#{opts[:file]} does not exist."
    exit
  end
  debug "Attempting upload of #{opts[:file]}" if opts[:debug]

  #Check if the file already exists; we shall not overwrite
  begin
    client.file_from_path("#{BOX_UPLOAD_LOCATION}/#{File.basename(opts[:file])}")
  # If we get an error here, it's because the path doesn't exist yet, so we can overwrite it.
  # I'm abusing exceptions here; it's actually negated logic.
  # -- try to see if the file exists; if it doesn't exist, the lib throws an error
  # -- -- an error? great! we can move on
  # -- no error? Uh oh...
  rescue Boxr::BoxrError
    begin
      box_folder = client.folder_from_path(BOX_UPLOAD_LOCATION)
      client.upload_file(opts[:file],box_folder)
    rescue Exception => e
      puts "File upload failed: #{e}"
      debug "File upload failed: #{e}"
    end # end embedded rescue
  else
    puts "The file already exists on Box and I am a coward. Refusing to overwrite"
    debug "Cannot overwrite #{opts[:file]} on box" if opts[:debug]
  end # end "does file exist?" rescue
end


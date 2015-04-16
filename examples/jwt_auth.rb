require 'dotenv'; Dotenv.load("../.env")
require 'boxr'
require 'awesome_print'
require 'jwt'
require 'securerandom'
require 'openssl'


private_key = OpenSSL::PKey::RSA.new File.read(ENV['JWT_SECRET_KEY_PATH']), ENV['JWT_SECRET_KEY_PASSWORD']
grant_type = "urn:ietf:params:oauth:grant-type:jwt-bearer"

payload = {
  iss: ENV['BOX_CLIENT_ID'],
  sub: ENV['BOX_ENTERPRISE_ID'],
  box_sub_type: "enterprise",
  aud: "https://api.box.com/oauth2/token",
  jti: SecureRandom.hex(64),
  exp: (Time.now.utc + 10).to_i
}

assertion = JWT.encode(payload, private_key, "RS256")

response = Boxr::get_token(grant_type: grant_type, assertion: assertion)
ap response

require 'sinatra'
require 'mongo/object'
require 'securerandom'
require 'openssl'
require 'base64'

Mongo.defaults.merge! mutlti: true, safe: true

connection = Mongo:: Connection.new
db = connection.default_test

db.some_collection

PBKDF2_ITERATIONS = 1000
SALT_BYTE_SIZE = 24
HASH_BYTE_SIZE = 24

HASH_SECTIONS = 4
SECTION_DELIMITER = ':'
ITERATIONS_INDEX = 1
SALT_INDEX = 2
HASH_INDEX = 3

# Returns a salted PBKDF2 hash of the password.
def createHash( password )
  salt = SecureRandom.base64( SALT_BYTE_SIZE )
  pbkdf2 = OpenSSL::PKCS5::pbkdf2_hmac_sha1(
      password,
      salt,
      PBKDF2_ITERATIONS,
      HASH_BYTE_SIZE
  )
  return ["sha1", PBKDF2_ITERATIONS, salt, Base64.encode64( pbkdf2 )].join( SECTION_DELIMITER )
end

def validatePassword( password, correctHash )
  params = correctHash.split( SECTION_DELIMITER )
  return false if params.length != HASH_SECTIONS

  pbkdf2 = Base64.decode64( params[HASH_INDEX] )
  testHash = OpenSSL::PKCS5::pbkdf2_hmac_sha1(
      password,
      params[SALT_INDEX],
      params[ITERATIONS_INDEX].to_i,
      pbkdf2.length
  )

  return pbkdf2 == testHash
end

enable :sessions

get '/' do
  @title = "Home is at Walden Books!"
  erb :index
end

get '/users' do
  @title = "DB Test"
  @collection = db.units.all()

  erb :users
end

post '/login' do
  @username = params[:name]
  @password = params[:password]
  @rememberme = params[:cb]

  @possibleusers = db.units.find("username" => @username)
  @possibleusers.each do |user|
    if user[]
  end

end

get '/register' do
  @title = "Register Test"
  erb :register
end

post '/register' do

  @username = "#{params[:post][:username]}"
  @password = "#{params[:post][:password]}"
  @password = createHash(@password)
  db.units.save _id: Time.now.to_s + rand(1000000000).to_s, username: @username, password: @password
  redirect '/users'
end

get '/edit/:id' do
  @title = "Register Test"
  @user = db.units.first("_id" => params[:id])
  @id = params[:id]
  @username = @user["username"]
  @password = @user["password"]
  erb :edit
end

post '/edit/:id' do
  @username = "#{params[:post][:username]}"
  @password = "#{params[:post][:password]}"
  db.units.save _id: params[:id], username: @username, password: @password
  redirect '/users'
end

get '/delete/:id' do
  db.units.remove("_id" => params[:id])
  redirect '/users'
end
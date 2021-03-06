require 'sinatra'
require 'mongo/object'
require 'securerandom'
require 'openssl'
require 'base64'

Mongo.defaults.merge! mutlti: true, safe: true


connection = Mongo:: Connection.new
db = connection.default_test
stories = connection.other_test

db.some_collection
stories.some_collection

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
  @username
  @password
  if session[:rememberme] == "checked"
    @username = session[:username]
    @password = session[:password]
    @checked = session[:rememberme]
  end
  erb :index
end

get '/add_chapter/:id' do
  @story = stories.units.first("storyId" => params[:id], "chapterId" => 1)
  @id = params[:id]
  @storyName = @story["storyName"]
  erb :add_chapter
end

post '/add_chapter/:id' do
  @story = stories.units.first("storyId" => params[:id])
  @stories = stories.units.find("storyId" => params[:id])
  @storyId = params[:id]
  @storyName = @story["storyName"]
  @chapterId = @stories.count() + 1
  @chapterName = "#{params[:post][:chapterName]}"
  @content = "#{params[:post][:content]}"
  @username = session[:username]
  @dateCreated = @story["dateCreated"]
  @dateModified = Time.now.to_s
  if params[:post][:finished] == "on"
    @isFinished = true
  else
    @isFinished = false
  end
  stories.units.save storyId: @storyId, storyName: @storyName, chapterId: @chapterId, chapterName: @chapterName, content: @content, username: @username, dateCreated: @dateCreated, dateModified: @dateModified, isFinished: @isFinished
  redirect '/stories'
end

get '/create_story' do
  erb :create_story
end

post '/create_story' do
  @storyId = Time.now.to_s + rand(1000000000).to_s
  @storyName = "#{params[:post][:storyName]}"
  @chapterId = 1
  @chapterName = "#{params[:post][:chapterName]}"
  @content = "#{params[:post][:content]}"
  @username = session[:username]
  @dateCreated = Time.now.to_s
  @dateModified = Time.now.to_s
  if params[:post][:finished] == "on"
    @isFinished = true
  else
    @isFinished = false
  end
  stories.units.save storyId: @storyId, storyName: @storyName, chapterId: @chapterId, chapterName: @chapterName, content: @content, username: @username, dateCreated: @dateCreated, dateModified: @dateModified, isFinished: @isFinished
  redirect '/stories'
end

get '/delete/:id' do
  db.units.remove("_id" => params[:id])
  session[:rememberme] = ""
  redirect '/logout'
end

get '/edit/:id' do
  @title = "Edit Account"
  @user = db.units.first("_id" => params[:id])
  @id = params[:id]
  @username = @user["username"]
  @password = session[:password]
  erb :edit
end

post '/edit/:id' do
  @username = "#{params[:post][:username]}"
  @password = "#{params[:post][:password]}"
  @hashword = createHash(@password)
  db.units.save _id: params[:id], username: @username, password: @hashword
  redirect '/users'
end

get '/login' do
  @title = "Login"
  @username
  @password
  if session[:rememberme] == "checked"
    @username = session[:username]
    @password = session[:password]
    @checked = session[:rememberme]
  end
  erb :login
end

post '/login' do
  @user = db.units.first("username" => "#{params[:post][:username]}")
  if @user != nil
    if validatePassword("#{params[:post][:password]}", @user["password"])
      if params[:post][:cb] == "on"
        session[:rememberme] = "checked"
      else
        session[:rememberme] = ""
      end
      session[:username] = @user["username"]
      session[:password] = params[:post][:password]
      session[:userid] = @user["_id"]
      redirect "/"
    else
      redirect "/login"
    end
  else
    redirect '/login'
  end
end

get '/logout' do
  if session[:rememberme] != "checked"
    session.clear
  end
  session[:username] = nil
  session[:userid] = nil
  redirect '/'
end

get '/myStories' do
  @stories = stories.units.find("chapterId" => 1, "username" => session[:username])
  erb :myStories
end

get '/register' do
  @title = "Register"
  erb :register
end

post '/register' do
  @username = "#{params[:post][:username]}"
  @password = "#{params[:post][:password]}"
  @password = createHash(@password)
  @id = Time.now.to_s + rand(1000000000).to_s
  db.units.save _id: @id, username: @username, password: @password
  session[:username] = @username
  session[:password] = "#{params[:post][:password]}"
  session[:userid] = @id
  redirect '/stories'
end

get '/stories' do
  @stories = stories.units.find("chapterId" => 1)
  erb :stories
end

get '/users' do
  @title = "Users"
  @collection = db.units.all()

  erb :users
end

get '/view_story/:id' do
  @story = stories.units.first("storyId" => params[:id], "chapterId" => 1)
  @storyName = @story["storyName"]
  @username = @story["username"]
  @id = params[:id]
  @stories = stories.units.find("storyId" => params[:id])
  @lastChapter = stories.units.first("storyId" => params[:id], "chapterId" => @stories.count())
  @finished = @lastChapter["isFinished"]
  erb :view_story
end




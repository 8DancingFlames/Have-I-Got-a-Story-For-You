require 'sinatra'
require 'mongo/object'

Mongo.defaults.merge! mutlti: true, safe: true

$username
$password
$id
$rememberme
connection = Mongo:: Connection.new
db = connection.default_test

db.some_collection

enable :sessions
get '/' do
  @title = "Home is at Walden Books!"
  erb :index
end

get '/users' do
  @title = "Users"
  @collection = db.units.all()

  erb :users
end

get '/login' do
  @title = "Login"
  @username
  @password
  if $rememberme == "checked"
    @username = session[:username]
    @password = session[:password]
    @checked = $rememberme
  end

  erb :login
end

post '/login' do
  @user = db.units.first("username" => "#{params[:post][:username]}", "password" => "#{params[:post][:password]}")
  if @user != nil
    if params[:post][:cb] == "on"
      session[:username] = @user["username"]
      session[:password] = params[:post][:password]
      $rememberme = "checked"
    else
      $rememberme = ""
    end
    $username = @user["username"]
    $id = @user["_id"]
    redirect "/"
  else
    redirect '/login'
  end
end

get '/logout' do
  if $rememberme != "checked"
    session.clear
  end
  $username = nil
  $id = nil
  redirect '/'
end

get '/register' do
  @title = "Register"
  erb :register
end

post '/register' do
  @username = "#{params[:post][:username]}"
  @password = "#{params[:post][:password]}"
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
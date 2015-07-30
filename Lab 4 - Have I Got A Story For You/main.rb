require 'sinatra'
require 'mongo/object'

Mongo.defaults.merge! mutlti: true, safe: true

connection = Mongo:: Connection.new
db = connection.default_test

db.some_collection

get '/' do
  @title = "Home is at Walden Books!"
  erb :index
end

get '/users' do
  @title = "DB Test"
  @collection = db.units.all()

  erb :users
end

get '/register' do
  @title = "Register Test"
  erb :register
end

post '/register' do
  @username = "#{params[:post][:username]}"
  @password = "#{params[:post][:password]}"
  db.units.save _id: Time.now.to_s + rand(1000000000).to_s, username: @username, password: @password
  redirect '/users'
end

get '/delete/:id' do
  db.units.remove("_id" => params[:id])
  redirect '/users'
end
require 'sinatra'

get '/' do
  @title = "Home is at Walden Books!"
  erb :index
end
require 'sinatra'

class MobileFilter < Sinatra::Base
  get '/' do
    body 'hello, world'
  end
end

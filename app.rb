require 'sinatra'

class App < Sinatra::Base

  get '/' do
    require './lib/wikicrawl.rb'
    d = Time.now
    day = fetch(d.strftime("%B %-d"))
    # pick a random event
    eventIndex = rand(day["Events"].count)
    @event = processEvent(day["Events"][eventIndex])
    
    erb :index
  end
end

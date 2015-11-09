require 'sinatra'

class App < Sinatra::Base
  
  configure do
    set :lastFetchedDay, nil
    set :lastFetchedString, nil
  end

  get '/' do
    @js = "index.js"
    erb :index
    # erb :hardcode
  end
  
  get '/reason' do
    require './lib/wikicrawl.rb'
    d = Time.now.strftime("%B %-d")
    
    # some days are hardcoded
    hardcoded = {"February 9" => "National Pizza Day",
                 "July 10" => "Pizza Day in Brazil",
                 "September 5" => "National Cheese Pizza Day",
                 "September 20" => "National Pepperoni Pizza Day",
                 "October 11" => "National Sausage Pizza Day",
                 "November 9" => "the First Day of Pizzamas",
                 "November 10" => "the Second Day of Pizzamas",
                 "November 11" => "National Pizza with the Works Except Anchovies Day, and the Third Day of Pizzamas",
                 "November 12" => "the Fourth Day of Pizzamas",
                 "November 13" => "the Fifth Day of Pizzamas",
                 "November 14" => "the Sixth Day of Pizzamas",
                 "November 15" => "the Seventh Day of Pizzamas",
                 "November 16" => "the Eighth Day of Pizzamas",
                 "November 17" => "the Ninth Day of Pizzamas",
                 "November 18" => "the Tenth Day of Pizzamas",
                 "November 19" => "the Eleventh Day of Pizzamas",
                 "November 20" => "the Twelfth Day of Pizzamas"}
    if (hardcoded.keys.index(d) != nil)
      reason = "<p>because today is #{hardcoded[d]}</p>"
    else
      
      # only fetch a day if we haven't stored one already
      if (settings.lastFetchedString != d)
        day = fetch(d)
        settings.lastFetchedDay = day
        settings.lastFetchedString = d
      else
        puts "retrieving day from cached"
        day = settings.lastFetchedDay
      end
      
      # pick a random event
      eventIndex = rand(day["Events"].count)
      event = processEvent(day["Events"][eventIndex])
      while (event["text"] == "")
        event = processEvent(day["Events"][eventIndex])
      end
      
      excuses = [
        "that reason isn't fucking good enough",
        "I need a different goddamn reason",
        "so what?",
        "I don't give a shit about that",
        "not pizza-worthy"
      ]
      excuse = excuses[rand(excuses.length)]
      
      reason = "<p>because on this day in #{event["year"]}, #{event["text"]}</p><p id='excuse'><a href='/'>#{excuse}</a></p>"
    end
    
    reason
  end

end

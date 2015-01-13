require 'sinatra'

class App < Sinatra::Base

  get '/' do
    require './lib/wikicrawl.rb'
    d = Time.now.strftime("%B %-d")
    
    # some days are hardcoded
    hardcoded = {"February 9" => "National Pizza Day",
                 "July 10" => "Pizza Day in Brazil",
                 "September 5" => "National Cheese Pizza Day",
                 "September 20" => "National Pepperoni Pizza Day",
                 "October 11" => "National Sausage Pizza Day",
                 "November 10" => "the First Day of Pizzamas",
                 "November 11" => "the Second Day of Pizzamas",
                 "November 12" => "National Pizza with the Works Except Anchovies Day, and the Third Day of Pizzamas",
                 "November 13" => "the Fourth Day of Pizzamas",
                 "November 14" => "the Fifth Day of Pizzamas",
                 "November 15" => "the Sixth Day of Pizzamas",
                 "November 16" => "the Seventh Day of Pizzamas",
                 "November 17" => "the Eighth Day of Pizzamas",
                 "November 18" => "the Ninth Day of Pizzamas",
                 "November 19" => "the Tenth Day of Pizzamas",
                 "November 20" => "the Eleventh Day of Pizzamas",
                 "November 21" => "the Twelfth Day of Pizzamas"}
    if (hardcoded.keys.index(d) != nil)
      @reason = "today is #{hardcoded[d]}"
    else
      day = fetch(d)
      # pick a random event
      eventIndex = rand(day["Events"].count)
      event = processEvent(day["Events"][eventIndex])
      @reason = "on this day in #{event["year"]}, #{event["text"]}"
    end
    
    
    erb :index
  end

end

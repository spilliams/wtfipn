require 'wikipedia'
require 'json'

DEBUG = false

# takes in raw content string for event
# returns presentable html
def processEvent(e)
  year = e.split("&ndash;").first.strip
  year = year.split("|").last.tr_s("[","").tr_s("]","")
  
  text = e.split("&ndash;").last.strip
  while text.index("[[")
    startIndex = text.index("[[")
    stopIndex = text.index("]]")
    token = text[startIndex+2, stopIndex-startIndex-2]
    token = token.split("|").last
    text[startIndex, stopIndex-startIndex+2] = token
  end
  return {"year" => year, "text" => text}
  
  # NLP ideas:
  # other idea: if first word is not a proper noun, decapitalize it
  # change tenses of verbs...
end

def fetch(pageName)
  response = Wikipedia.find(pageName);
  json = JSON.parse(response.json);
  pages = json["query"]["pages"];
  page = pages[pages.keys.first];
  content = page["revisions"].first["*"];

  # splits on category titles, ie Events, Births, Deaths
  split = content.split(/==/);
  day = {}
  categories = ["History", "Events", "Births", "Deaths", "Holidays", "References", "See Also", "External Links"]
  # we can't assume anything about presence or order of specific categories, but we can assume
  # that categories appear at odd-numbered indices
  for k in 1..split.count
    next if k%2 != 1
    begin
      # search for split[k] in categories
      for l in 0..categories.count
        category = categories[l]
        if (split[k].downcase.lstrip.index(category.downcase.lstrip))
          day[category] = split[k+1].split("\n*")
          break
        end
      end # categories loop
    rescue
      
    end
  end
  
  # fill out day, make sure it has all the right keys
  for l in 0..categories.count
    day[categories[l]] = [] if day[categories[l]] == nil
  end
  
  puts "#{pageName}, #{day["Events"].count}, #{day["Births"].count}, #{day["Deaths"].count}, #{day["Holidays"].count}" if DEBUG
  return day
end

def fetchAll
  days = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
  months = ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"]

  for i in 0...12
    dateString = months[i]+" "
    for j in 1..days[i]
      pageName = dateString+String(j);
      day = fetch(pageName)
    end
  end
  
end

require 'wikipedia'
require 'json'

DEBUG = false

def removeTokens(text, startString, stopString, replace)
  while text != nil && text.index(startString)
    startIndex = text.index(startString)
    stopIndex = text[startIndex,text.length-startIndex].index(stopString) + startIndex
    inner = text[startIndex+startString.length, stopIndex-startIndex-startString.length]
    # replace can be "true" for "use the token's inner string", or it can be a string to replace the whole token with
    replaceString = replace===false ? "" : (replace===true ? inner : replace)
    # puts "inner #{inner}, replace string: #{replaceString}"
    text[startIndex, stopIndex-startIndex+stopString.length] = replaceString
  end
  text
end

# takes in raw content string for event
# returns presentable html
def processEvent(e)
  if (e.index("&ndash;") == nil)
    return {"year" => "", "text" => ""}
  end
  
  year = e.split("&ndash;").first.strip
  year = year.split("|").last.tr_s("[","").tr_s("]","")

  text = e.split("&ndash;").drop(1).join.strip
  
  text = removeTokens(text, "<ref", ">", false)
  text = removeTokens(text, "</ref", ">", false)
  text = removeTokens(text, "{{'", "}}", "'")
  
  # remove [[foo|bar]] tokens
  while text.index("[[")
    startIndex = text.index("[[")
    stopIndex = text.index("]]")
    token = text[startIndex+2, stopIndex-startIndex-2]
    token = token.split("|").last
    text[startIndex, stopIndex-startIndex+2] = token
  end
  
  text = removeTokens(text, "<!--", "-->", false)
  #TODO: do something about {foo|bar|qaz} tokens
  #TODO: <sub> and <sup>
  #TODO: decapitalize the first word if it is an article (or if it wasn't originally in a token?!)
  #TODO: change tenses of verbs...
  
  text = text.strip
  
  return {"year" => year, "text" => text}
  
end

def fetch(pageName)
  puts "fetch #{pageName}"
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
  numDays = [31, 29, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
  months = ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"]

  days = []
  for i in 0...12
    dateString = months[i]+" "
    for j in 1..numDays[i]
      pageName = dateString+String(j);
      day = fetch(pageName)
      days.push day
    end
  end
  
  days
  
end

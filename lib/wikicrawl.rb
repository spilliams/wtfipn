require 'wikipedia'
require 'json'

DEBUG = false

def removeTokens(text, startString, stopString, replace)
  while text != nil and text.index(startString)
    startIndex = text.index(startString)
    stopIndex = text[startIndex + startString.length, text.length - startIndex - startString.length].index(stopString) + startIndex + startString.length
    inner = text[startIndex + startString.length, stopIndex - startIndex - startString.length]
    # replace can be "true" for "use the token's inner string", or it can be a string to replace the whole token with
    replaceString = replace===false ? "" : (replace===true ? inner : replace)
    # puts "inner #{inner}, replace string: #{replaceString}"
    text[startIndex, stopIndex - startIndex + stopString.length] = replaceString
  end
  text
end

def shipFromSplitToken(inner)
  # remove blanks
  inner = inner.insert(0, "").uniq.drop(1)
  
  # weeding
  if (inner[0].index("battleship") != nil)
    inner = inner.drop(1)
  end
  if (inner[0].index("cruiser") != nil)
    inner = inner.drop(1)
  end
  if (inner[0].index("aircraft carrier") != nil)
    inner = inner.drop(1)
  end
  
  finalInner = ""
  if (inner[0].upcase == inner[0])
    finalInner = inner[0]
    inner = inner.drop(1)
  end
  
  "#{finalInner} <i>#{inner[0]}</i>"
end
def removeShips(text)
  # those that start with Ship or ship
  while text != nil and text.index(/{{[sS]hip/)
    startIndex = text.index(/{{[sS]hip/)
    stopIndex = text[startIndex, text.length-startIndex].index(/}}/) + startIndex
    inner = text[startIndex+7, stopIndex-startIndex-7].split("|")
    finalInner = shipFromSplitToken(inner)
    text[startIndex, stopIndex-startIndex+2] = finalInner
  end
  
  # those that just start with the abbreviation
  abbrevs = ["HMS", "RMS", "USS", "HMAS", "SS", "MS", "AMS", "SMU", "MV", "GS", "SMS", "ss", "USCGC", "HMNZS"]
  for abbrevIndex in 0...abbrevs.length
    abbrev = abbrevs[abbrevIndex]
    startString = "{{#{abbrev}"
    stopString = "}}"
    while text != nil and text.index(startString)
      startIndex = text.index(startString)
      stopIndex = text[startIndex, text.length-startIndex].index(stopString) + startIndex
      inner = text[startIndex+2, stopIndex-startIndex-2].split("|")
      inner[0] = inner[0].upcase
      finalInner = shipFromSplitToken(inner)
      text[startIndex, stopIndex-startIndex+2] = finalInner
    end
  end
  
  # ship classes
  while text != nil and text.index("{{sclass-")
    startIndex = text.index("{{sclass-")
    stopIndex = text[startIndex, text.length - startIndex].index("}}") + startIndex
    inner = text[startIndex+2, stopIndex-startIndex-2].split("|")
    # 0th is "sclass-", 1st is name, 2nd is size
    name = inner[1]
    size = inner[2]
    text[startIndex, stopIndex-startIndex+2] = "<i>#{name}</i>-class #{size}"
  end
  
  text
end

def processItalics(text)
  while text != nil and text.index("''")
    startIndex = text.index("''")
    stopIndex = text[startIndex+2, text.length - startIndex - 2].index("''")
    if (stopIndex == nil)
      stopIndex = text.length
    else
      stopIndex = stopIndex + startIndex + 2
    end
    inner = text[startIndex+2, stopIndex - startIndex - 2]
    text[startIndex, stopIndex-startIndex+2] = "<i>#{inner}</i>"
  end
  
  text
end

def processSpaceShuttles(text)
  replaces = {"{{OV|105}}" => "Endeavour", "{{OV|104}}" => "Atlantis", "{{OV|099}}" => "Challenger", "{{OV|102}}" => "Columbia", "{{OV|103}}" => "Discovery", "{{OV|101}}" => "Enterprise"}
  for replaceIndex in 0...replaces.keys.length
    replaceToken = replaces.keys[replaceIndex]
    replaceInner = replaces[replaceToken]
    while text != nil and text.index(replaceToken)
      text[text.index(replaceToken), replaceToken.length] = "Space Shuttle <i>#{replaceInner}</i>"
    end
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
  
  text = removeTokens(text, "<ref", "</ref>", false)
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
  text = removeShips(text)
  text = removeTokens(text, "{{Cite ", "}}", false)
  text = removeTokens(text, "{{cite ", "}}", false)
  text = removeTokens(text, "{{Citation", "}}", false)
  text = removeTokens(text, "{{citation", "}}", false)
  text = removeTokens(text, "{{Disambiguation ", "}}", false)
  text = removeTokens(text, "{{disambiguation ", "}}", false)
  text = removeTokens(text, "{{$", "}}", "$")
  
  test = removeTokens(text, "{{okina", "}}", "ʻ")
  
  test = processItalics(text)
  text = processSpaceShuttles(text)
  
  # TODO:
  # do something about {{foo|bar|baz}} tokens
    # 177, Events, 69 has newlines in the {{}}
    # [] citations
  # <sub> and <sup>
  # decapitalize the first word if it is an article (or if it wasn't originally in a token?!)
  # change tenses of verbs...
  # search for all special characters: `~!@#$%^&*()-=_+[]\{}|;':",./<>?
  
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

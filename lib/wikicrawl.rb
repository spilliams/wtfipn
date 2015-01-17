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

def processColons(text)
  # we just care about the first colon
  if text != nil and text.index(":")
    colonIndex = text.index(":")
    matches = [
      "Acteal massacre", "American Civil Rights Movement", "American Civil War", "American Indian Wars", "American Revolution", "American Revolutionary War", "Apollo program", "Arab Spring", "Arab–Byzantine wars",
      "Battle of Colmar", "Battle of Nancy", "Battle of Quebec", "Battle of Reading", "Battle of Tucapel", "Battle of Westbroek", "Battles of Pultusk and Golymin", "Bosnian War",
      "Chad–Sudan relations", "Challenger expedition", "Chinese Civil War", "Cold War", "Crimean War",
      "Dissolution of Czechoslovakia", "Dreyfus affair",
      "Eighty Years' War", "English Civil War", "English Restoration",
      "Falklands War", "First Balkan War", "First Barbary War", "First Crusade", "First Indochina War", "Franco-Prussian War", "French and Indian War", "French Revolution", "French Revolutionary Wars",
      "Gadsden Purchase", "Georgetown-IBM experiment", "Granada massacre", "Great Depression", "\"Greatest Game Ever Played\"", "Greek War of Independence", "Gulf War",
      "History of Slovenia", "Holocaust", "Hundred Years' War",
      "Indonesian National Revolution", "Iran–Contra affair", "Iranian election protests", "Iraq War", "Israeli–Palestinian conflict",
      "Korean War", "Kosovo War",
      "Lancaster House Agreement",
      "Mariner program", "Meiji Restoration in Japan", "Mexican–American War", "Mexican Revolution",
      "Napoleonic Wars", "New Deal",
      "Operation Auca", "Operation Cast Lead", "Orange Revolution",
      "Peninsular War", "Project Mercury",
      "Queen Anne's War",
      "Radio", "Reconquista", "Rizal Day bombings", "Roboski airstrike", "Russo-Japanese War",
      "Second Battle of Wissembourg", "Second Boer War", "Second Gulf of Sidra incident", "Second Jacobite rising", "Second Northern War/the Deluge", "Second Seminole War", "Second Sino-Japanese War", "Seven Years' War", "Sino-Burmese War", "Sino-French War", "Soviet war in Afghanistan", "Space Shuttle program", "Spanish–American War", "Spanish Civil War", "Sri Lankan Civil War", "Surveyor Program",
      "Tangiwai disaster", "Tay Bridge disaster", "Texas Revolution", "The 1987 Maryland train collision", "The Battle of Savenay", "The First Chechen War", "The foundation of the Kingdom of Hungary", "The Holocaust", "The <i>Trent Affair</i>", "The Troubles", "Third Indochina War", "Thirty Years' War",
      "Uruguayan War",
      "Venera program", "Vietnam War",
      "War in Somalia", "War of 1812", "War of the Austrian Succession", "Wars of the Roses", "Watergate scandal", "Winter War", "World War I", "World War II",
    
      "War of the Spanish Succession", "Apartheid", "Iran hostage crisis", "Anglo-Zulu War", "Baseball", "Explorer program", "Lewinsky scandal", "War of the Pacific", "Six-Day War", "American Old West", "Irish War of Independence", "Siege of Jerusalem", "Women's suffrage", "Bangladesh Liberation War", "Polish–Soviet War", 

      "Ranger program", "Space Race", "Glorious Revolution", "Siege of Rome", "War of the Second Coalition", "First War of Scottish Independence", "California Gold Rush", "Third Crusade", "Rwandan Genocide", "Irish Rebellion of 1798", "Wars of Scottish Independence", "Scopes Trial", "Watergate Scandal", "Nuclear testing", "Philippine–American War", 

      "Tonkin Campaign", "Second Anglo-Dutch War", "Boxer Rebellion", "Second Balkan War", "Women's rights", "German reunification", "French Wars of Religion", "Censorship", "Yugoslav Wars", "Franco-Dutch War", "First Coalition", "Cuban Revolution", "Capital punishment", "Great Northern War", "Anglo-Spanish War", "Boshin War", "Finnish War", "Gunpowder Plot", "Viking program", "War on Drugs", "Second Punic War", "2003 invasion of Iraq", "Suez Crisis", "Second Congo War", "Finnish Civil War", "Partitions of Poland", "Gothic War", "Indo-Pakistani War", "Red Scare", "Greek Civil War", "Second Vatican Council", "First Chechen War", "Führerbunker", "Greco-Turkish War", "Oklahoma City bombing", "Iraq disarmament crisis", 

      "Protestant Reformation", "Tokhtamysh–Timur war", "Greek military junta of 1967–74", "Lewis and Clark Expedition", "1948 Arab–Israeli War", "Tupelo-Gainesville tornado outbreak", "Russo-Turkish War", "Easter Rising", "Apartheid in South Africa", "Libyan Civil War", "Eritrean War of Independence", "The Chernobyl Disaster", "My Lai Massacre", "Iran-Contra Affair", "North Korea nuclear weapons program", "Louisiana Purchase", "Indian Rebellion of 1857", "McCarthyism", "Yom Kippur War", "War of the First Coalition", "Second Opium War", "War in Iraq", "U.S. invasion of Afghanistan", "Abdication Crisis", "Reconstruction", "Arab–Israeli War", "United Irishmen Rebellion", "Arab–Israeli conflict", "<i>Gleichschaltung</i>", "World War I, Western Front", "Italian Wars", "The Second Boer War", "Argentine War of Independence", "Mongol–Jin War", "Salem witch trials", "Mercury program", "Monmouth Rebellion", "Nagorno-Karabakh War", "Project Vanguard", "War of the Sixth Coalition", "Abbasid Revolution", "Buddhist crisis", "Second Italo-Abyssinian War", "Seventh Crusade", "Second Chechen War", "Congo Crisis", "An Lushan Rebellion", "Gleichschaltung", "Pike expedition", "Persian Constitutional Revolution", "Nuclear weapons testing", "Romanian Revolution", "Ukrainian–Soviet War", "Crossing of the Andes", "Black July", "Anglo-Afghan War", "Long War", "Indian Wars", "Battle of Mohács", "Imjin War", "Nine Years' War", "Sputnik program", "Dissolution of the Soviet Union, August Coup", "Serbo-Bulgarian War", "Iran–Iraq War", "Lebanese Civil War", "Franco-Thai War", "Project Gemini", "STS-41-D", "Third English Civil War", "Munich massacre", "November Uprising", "Nigerian Civil War", "Montreal", "Pioneer program", "Salvadoran Civil War", "War in Afghanistan", "German Autumn", "Manifest Destiny", "Cuban missile crisis", "Second Battle of El Alamein", "Vietnamization", "Northern Crusades", 

      "First Chechnya War", "Cherry Valley massacre", "Second Battle of Khotyn in Ukraine", "Veteran's Day weekend tornado outbreak", "United Nations Resolution 3379", "Anglo-Dutch War", "Battle of Varna", "Fourth Crusade", "Nuclear false alarm", "Armistice Day Blizzard", "Remembrance Day bombing", "Operation Grapple X, Round C1", "Greco-Italian War", "Venlo Incident", "Beer Hall Putsch", "Stockholm Bloodbath begins", "Battle of Andrassos", "United States Senate bombing", "Wunder von Lengede", "Third Battle of Gaza ends", "Battle of Belmont", "Tecumseh's War", "Lam Sơn uprising", "Cleveland Browns relocation controversy", "Sumburgh disaster", "Green March begins", "Third Battle of Ypres ends", "October Revolution", "Women's suffrage in the United States", "Australian constitutional crisis of 1975", "City and South London Railway", "Battle of Johnsonville", "Newport Rising", "Armagnac–Burgundian Civil War", "Greensboro massacre", "Quiz show scandals", "Time zone", "Operation Ivy", "Operation Buster–Jangle", "Abolition of the Ottoman Sultanate", "Malbone Street Wreck", "(22 October O.S.) Time of Troubles in Russia", "Iraq disarmament crisis begins", "Vietnam War October surprise", "The Battle of Britain ends", "Battle of Beersheba", "Ballet of Chestnuts", "The Tangier Protocol is signed", "Suez Crisis begins", "Safsaf massacre", "Battle of Wauhatchie", "Second Northern War", "Battle of Brustem", "Plame affair", "End of Cuban missile crisis", "March on Rome", "The Battle of Fair Oaks & Darbytown Road (also known as the Second Battle of Fair Oaks) ends", "Battle of White Plains", "Battle of Amba Sel", "Battle of Yaunis Khan", "Battle of the Milvian Bridge", "October 27, 1997 mini-crash", "Battle of Segale", "The British lose their first battleship of World War I", "Černová massacre", "Moscow theater hostage crisis", "The Erie Canal opens", "Killed in the Battle of Agincourt", "Operation Urgent Fury", "Nedelin catastrophe", "Moscow Theatre Siege begins", "The Watergate scandal", "The Springhill Mine bump", "Battle of Leyte Gulf", "Kaprun disaster", "First use of aircraft in war", "Battle of Westport", "War of Jenkins' Ear starts", "Battle of Edgehill", "Liberators' civil war", "Canada", "Haymarket affair defendants", "Panic of 1907", "The Great Anticipation", "Scilly naval disaster", "Battle of Liaoluo Bay", "The 1383–85 Crisis in Portugal", "Aberfan disaster", "Mau Mau Uprising", "Battle of Trafalgar", "Nanboku-chō", "People's Crusade", "\"Saturday Night Massacre\"", "Battle of Navarino", "Philippines", "Karachi bombing", "Bolivian gas conflict", "Peaceful Revolution", "Santa Cruz massacre", "Kepler's Supernova", "Battle of Neville's Cross", "London tornado of 1091", "Battle of Placentia", "Nuremberg trial executions of the Main Trial", "Hawaii earthquake", "Luby's shooting", "Nuremberg Trials", "The Dreyfus affair", "Battle of the Rhyndacus", "The Vietnam War", "The Cuban missile crisis begins", "Battle of Bristoe Station", "Norman Conquest", "Jaffna University Helidrop", "Brighton hotel bombing", "First Oktoberfest", "Battle of Hatfield Chase", "Pala accident", "First English Civil War", "Zaian War", "Television", "Second Boer War begins", "Battle of Camperdown", "Sack of Wexford", "United Airlines Boeing 247 mid-air explosion", "Tau Epsilon Phi", "The Great Chicago Fire", "Battle of Dormans", "Battle of Brunkeberg in Stockholm", "Battle of Tours", "Battle of Karbala", 

      "Rangoon bombing", "Battle of Britain", "Regicide at Marseille", "Black Sox Scandal", "Siege of Antwerp", "Battle of Tom's Brook", "Battle of Santa Rosa Island", "2005 Kashmir earthquake", "Operation Sealords", "Spiegel scandal", "First Balkan War begins", "Eulmi incident", "Battle of Perryville", "Rail transport", "Croatian War of Independence", "Bahia incident", "Morea expedition", "Battle of Kings Mountain", "Battle of La Motta", "Battle of Tigranocerta", "Battle of Arausio", "Chicago Tylenol murders", "Operation Primicia", "Guildford pub bombings", "Naval Battle of Guadalcanal", "Hollywood Black Friday", "Maxim restaurant suicide bombing in Haifa, Israel", "Siberia Airlines Flight 1812", "Russian Constitutional Crisis", "El Al Flight 1862", "Battle of Germantown", "Battle of Marsaglia", "Battle of Mogadishu", "Spaceflight", "First Battle of Philippi", "Ethan Allen boating accident", "The Texas Revolution begins with the Battle of Gonzales", "Battle of Rancagua", "Thrilla in Manila", "Los Angeles Times bombing", "Russo-Persian War", "Holocaust in Kiev, Ukraine", "Battle of Bárbula", "Battle of the Baggage", "Battle of Verona", "Space Shuttle", "China–Japan relations", "Holocaust in Kiev, Soviet Union", "Munich Agreement", "Chaco War", "World War I, Battle of St. Quentin Canal", "Battle of Pákozd", "Battle of Auray", "Hong Kong protests ", "Al-Aqsa Intifada", "Ottoman–Venetian War", "Battle of Mursa Major", "Zug massacre", "Serbian–Turkish wars", "Friso-Hollandic Wars", "Maze Prison escape", "\"Black Friday\"", "Belgian Revolution", "Kauhajoki school shooting", "Hurricane Jeanne", "Second Anglo-Maratha War", "Slavery in the United States", "Battle of Zutphen", "Battle of Salamis", "America", "Mahdist War", "Battle of Prestonpans", "Livonian Crusade", "Maldives civil unrest", "Battle of Alma", "Spanish revolution", "Third Battle of Winchester", "Battle of Iuka", "Battle of Poitiers", "Siege of Damascus", "Fashoda Incident", "Panic of 1873", "Black Wednesday", "1982 Lebanon war", "The Wall Street bombing", "16th Street Baptist Church bombing", "First Sino-Japanese War", "Late-2000s financial crisis", "Ip massacre", "\"Night of the three Caliphs\"", "Goiânia accident", "People's Republic of China", "Anglo-Egyptian War", "Battle of the Plains of Abraham", "Dawson's Field hijackings", "Tirah Campaign", "Battle of North Point", "Austro-Ottoman War", "Albigensian Crusade", "Sixteen Kingdoms", "Battle of Marathon", "Casualties of the September 11 attacks", "Bhola cyclone", "The Mountain Meadows massacre", "Christiana Resistance", "Battle of Brandywine", "Battle of Saint Cast", "Siege of Barcelona", "Battle of Malplaquet", "Siege of Drogheda ends", "Lithuanian Civil War (1389–92)", "Battle of Stirling Bridge", "Russian Civil War", "Lattimer massacre", "First case of a computer bug being found", "Treznea massacre", "Gays in the military", "Treaty of San Francisco", "Honda Point Disaster", "Galveston Hurricane of 1900", "Second Battle of Sabine Pass", "War on Terror", "Battle of Bassano", "Battle of Orsha", "Battle of Kulikovo", "Battle of Huoyi", "Treaty of Craiova", "Italian re-unification", "Mountain Meadows massacre", "French invasion of Russia ", "Battle of the Frigidus", "Camp David Accords", "Voyager program", "Sacramento, California", "Battle of the Winwaed", "Operation Jefferson Glenn begins", "Chile", "Roscoe \"Fatty\" Arbuckle party in San Francisco ends with the death of the young actress Virginia Rappe", "Battle of the Chesapeake in the American Revolutionary War", "War of the Grand Alliance ", "Great Fire of London ends", "Fall of Nicolas Fouquet", "Canterbury earthquake", "Little Rock Crisis", "American Civil War Maryland Campaign", "Sino-Soviet split", "Dagen H in Sweden", "Siege of the British Residency in Kabul", "Battle of Morgarten", "Combat ends in the Pacific Theater", "Labor Day Hurricane of 1935", "Rock Springs massacre", "Final War of the Roman Republic", "Battle of Tippermuir", "Siege of Constantinople", "Polish-Bolshevik War", "Battle of Zsibó", "Battle of Dumlupınar", "Philippine Revolution", "Battle of Richmond", "Creek War", "First Battle of Kulm", "2007 United States Air Force nuclear weapons incident", "Soviet atomic bomb project", "Battle of Winchelsea (or Les Espagnols sur Mer)", "Battle of Montecatini", "Skylab program", "Ramstein airshow disaster", "March on Washington for Jobs and Freedom", "Battle of Grand Port", "Second Bishop's War", "Turkish–Portuguese War (1538–1557)", "Internal conflict in Burma", "Battle of Étreux", "Anglo-Zanzibar War", "Battle of Long Island", "Killed in the Battle of Crécy", "Papal conclave", "Holocaust in Chortkiav, western Ukraine", "Chilean War of Independence", "Battle of St. Jakob an der Birs", "Battle of Manzikert", "Battle of Strasbourg", "Second day of two-day Hebron massacre during the 1929 Palestine riots", "Singing Revolution", "Hebron Massacre during the 1929 Palestine riots", "Battle of Mons", "Battle of Sobota", "Fettmilch Uprising", "Battle of Gifu Castle", "Japanese invasions of Korea"
    ]
    for matchIndex in 0...matches.length
      if (text[0, colonIndex].downcase == matches[matchIndex].downcase)
        text = text[colonIndex+2, text.length-colonIndex-2]
      end
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
  text = processColons(text)
  
  # TODO:
  # do something about {{foo|bar|baz}} tokens
    # 177, Events, 69 has newlines in the {{}}
    # [] citations
  # <sub> and <sup>
  # decapitalize the first word if it is an article (or if it wasn't originally in a token?!)
  # change tenses of verbs...
  # search for all special characters: `~!@#$%^&*()-=_+[]\{}|;':",./<>?
  # remove instances of negative emotion?
  # for sentence fragments, rearrange the reason. current: "because on this day in 1986, First meeting of the Internet Engineering Task Force". fixed: "because today in 1986 was the First meeting of the Internet Engineering Task Force"
  
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

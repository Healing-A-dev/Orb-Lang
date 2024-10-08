local utils = {}

--Literally only used in the interpreter to get each line and every character
function utils.stringify(toStingify)
  local ss,syn = {},{}
  for line in toStingify do
    syn[#syn+1] = line
  end
  for _,i in pairs(syn) do
    ss[_] = {}
    for s = 1, #i do
      ss[_][#ss[_]+1] = i:sub(s,s)
    end
  end
  return ss, syn
end

function utils.getFunctionName(line,dec)
    if dec == nil then
        local Fname = syntax[line]:match("func.+%(") or syntax[line]:match(".+%s?=%s?func%s?%(")
        Fname = Fname:gsub("func",""):gsub("[%=%s+%(]","")
        return Fname:gsub("[%s+%@]","")
    else
        return syntax[line]:match(".+%("):gsub("[%=%s+%(]",""):gsub("[%s+%@]",""):match("[%w?%.?]+%w+$")
    end
end

--Does what it says...inverts the keys and values of a table
function table.invert(t)
  local s = {}
  for _,i in pairs(t) do
    s[i] = _
  end
  return s
end

--idk, didnt make it...
function spairs(t, order)
  -- collect the keys
  local keys = {}
  for k in pairs(t) do keys[#keys+1] = k end

  -- if order function given, sort by it by passing the table and keys a, b,
  -- otherwise just sort the keys 
  if order then
      table.sort(keys, function(a,b) return order(t, a, b) end)
  else
      table.sort(keys)
  end

  -- return the iterator function
  local i = 0
  return function()
      i = i + 1
      if keys[i] then
          return keys[i], t[keys[i]]
      end
  end
end
 
--Also just does what it says...just searches a table for a value
function table.search(t,value)
  local num = 0
  for _,i in pairs(t) do
    num = num + 1
    if value == i then
      return true
    elseif value ~= i and num == #t then
      return false
    end
  end
end

--LITERALLY just splits a string into individual characters
function string.split(string)
  local str = {}
  for s = 1, #string do
    str[#str+1] = string:sub(s,s)
  end
  return str
end

--ok..i honestly dont remeber what this does...I think it returns the position of a phrase in a string
function utils.stringSearch(list,item)
  local store = {}
  local substore = list:split()
  local string = ""
  for _,i in pairs(substore) do
    if i == item or type(tonumber(i)):upper() == item then
      store[#store+1] = _
    end
    if type(substore[_]) == "string" then
      store[#store+1] = _
    end
  end
  string = table.concat(store," ")
  if #string == 0 then
    return nil
  else
    return string
  end
end

function table.position(t,item) -- Just returns the position of and item in a table
  local store = {}
  local string = ""
  for _,i in pairs(t) do
    if i == item then
      store[#store+1] = #t-(#t-_)
    end
  end
  for _,i in pairs(store) do
    string = string..tostring(i).."\n"
  end
  if #string == 0 then
    return nil
  else
    return string
  end
end

function string.position(string,phrase,line)
  --If there is no table for the current line, make one
  if phraseTable[line] == nil then phraseTable[line] = {} end
  --If the phrase length is less than 1 and is not a letter or number, then add the escape character "%"
  if phrase:len() == 1 and not tonumber(phrase) and not phrase:find("%w") then
    phrase = "%"..phrase
  end
  --Keep the original phrase (just makes life a bit easier)
  local ophrase = phrase:gsub("%%","")
  --If it is the phrases first time being found, create a table for it and add its starting and end point
  if phraseTable[line][phrase] == nil then
    phraseTable[line][phrase] = {}
    --Starting and End points for the phrase
    phraseTable[line][phrase].Start,phraseTable[line][phrase].End = string:find(phrase)
    --If phrase hasa already been found but has been found again, change the values of the phrases starting and ending points to the new one
  else
    --If phrase length is equal to 1 then find new position 1 space after the current phrase so it doesnt find itself again in the same position
    if phrase:gsub("%%",""):len() == 1 then
      --Check to see if value is nil or not
      if string:find(phrase,phraseTable[line][phrase].End+1) ~= nil then
        --Assign new position
        phraseTable[line][phrase].Start,phraseTable[line][phrase].End = string:find(phrase,phraseTable[line][phrase].End+1)
      end
    else --If phrase length is greater than 1 do the same as before (just in case)
      --Same as before
      if string:find(phrase,phraseTable[line][phrase].End+1) ~= nil then
        --Same as before
        phraseTable[line][phrase].Start,phraseTable[line][phrase].End = string:find(phrase,phraseTable[line][phrase].End+1)
      end
    end
  end
  return {Start = phraseTable[line][phrase].Start, End = phraseTable[line][phrase].End, Phrase = ophrase}
end

function utils.varCheck(var,isFunction)
    if not isFunction then
        if Variables.Global[var] ~= nil then
            return {Real = true, Type = Variables.Global[var].Type, Value = Variables.Global[var].Value, Class = "global"}
        elseif Variables.Static[var] ~= nil then
            return {Real = true, Type = Variables.Static[var].Type, Value = Variables.Static[var].Value, Class = "static"}
        elseif Variables.Temporary[var] ~= nil then
            return {Real = true, Type = Variables.Temporary[var].Type, Value = Variables.Temporary[var].Value, Class = "static"}
        else
            return {Real = false, Type = nil}
        end
    else
        if Variables.Global[var] ~= nil and Variables.Global[var].Type == "Function" then
            return {Real = true, Type = Variables.Global[var].Type, Value = Variables.Global[var].Value, Class = "Global"}
        elseif Variables.Static[var] ~= nil and Variables.Static[var].Type == "Function" then
            return {Real = true, Type = Variables.Static[var].Type, Value = Variables.Static[var].Value, Class = "Static"}
        elseif Variables.Temporary[var] ~= nil and Variables.Temporary[var].Type == "Function" then
            return {Real = true, Type = Variables.Temporary[var].Type, Value = Variables.Temporary[var].Value, Class = "Temporary"}
        else
            return {Real = false, Type = nil}
        end
    end
end

function string.index(string,index)
  local out = {}
  for split in string:gmatch("[^%+^%-^%^^%*^%/]+") do
    out[#out+1] = split
  end
  return out
end

function string.chop(string,locations)
  local splitString = string:split()
  if locations ~= nil then
    for _,i in pairs(locations) do
      table.remove(splitString,i)
    end
  else
    table.remove(splitString,#splitString)
  end
  return table.concat(splitString)
end

function removeValue(t,value)
  local out = {}
  for _,i in pairs(t) do
      out[_] = {}
      for s = 1, #i do
        if i[s] ~= nil and not i[s][1]:find(value) then
          out[_][#out[_]+1] = i[s]
        end
      end
  end
  return out
end

function string.replace(string,valueToReplace,replacementValue)
    local splitStr = string:split()
    local Slocation, Elocation = string:find(valueToReplace)
    if Elocation > Slocation then 
        for s = Slocation+1, Elocation do
            splitStr[s] = nil
        end
    end
    splitStr[Slocation] = replacementValue
    return table.concat(splitStr)
end

return utils
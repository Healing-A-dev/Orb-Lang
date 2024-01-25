local utils = {}

local phraseTable = {}


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

function table.invert(t)
  local s = {}
  for _,i in pairs(t) do
    s[i] = _
  end
  return s
end

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

function string.split(string)
  local str = {}
  for s = 1, #string do
    str[#str+1] = string:sub(s,s)
  end
  return str
end

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

function string.position(string,phrase,line)
  if phraseTable[line] == nil then phraseTable[line] = {} end
  if phrase:len() == 1 and not tonumber(phrase) and not phrase:find("%w") then
    phrase = "%"..phrase
  end
  local ophrase = phrase:gsub("%%","")
  local s,e = string:find(phrase)
  if phraseTable[line][phrase] == nil then
    phraseTable[line][phrase] = {}
    phraseTable[line][phrase].Start,phraseTable[line][phrase].End = string:find(phrase)
  else
    if phrase:gsub("%%",""):len() == 1 then
      if string:find(phrase,phraseTable[line][phrase].End+1) ~= nil then
        phraseTable[line][phrase].Start,phraseTable[line][phrase].End = string:find(phrase,phraseTable[line][phrase].End+1)
      end
    else
      if string:find(phrase,phraseTable[line][phrase].End+1) ~= nil then
        phraseTable[line][phrase].Start,phraseTable[line][phrase].End = string:find(phrase,phraseTable[line][phrase].End+1)
      end
    end
  end
  return {Start = phraseTable[line][phrase].Start, End = phraseTable[line][phrase].End, Phrase = ophrase}
end


return utils

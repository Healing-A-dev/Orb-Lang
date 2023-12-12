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

function table.search(table,value)
  local num = 0
  for _,i in pairs(table) do
    num = num + 1
    if value == i then
      return true
    elseif value ~= i and num == #table then
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
  local substore = {}
  local string = ""
  for s = 1, #list do
    substore[#substore+1] = list:sub(s,s)
  end
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

function string.position(string,phrase)
  local front, back = nil, nil
  if phrase:len() == 1 and not tonumber(phrase) then
    phrase = "%"..phrase
  end
  if phraseTable[phrase] ~= nil and phrase == phraseTable[phrase].Phrase then
    if string:find(phrase,phraseTable[phrase].Start+1) == nil then
      front, back = string:find(phrase)
    else
      front, back = string:find(phrase,phraseTable[phrase].Start+1)
    end
  else
    front, back = string:find(phrase)
  end
  if front ~= nil then 
    phraseTable[phrase] = {Phrase = phrase, Start = front, End = back}
  end
  return {Start = front, End = back, Phrase = phrase:gsub("%%",""), phraseLength = phrase:gsub("%%",""):len()}
end

return utils

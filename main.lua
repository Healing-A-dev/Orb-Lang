local errors = require("errors")
local lexer = require("lexer")
local utils = require("utils")
local Tokens = require("Tokens")

os.execute('clear')
currentFile = "main"
local pathToFile = {"main"}
local isString = {isString = false, stringSE = "NIL"}
lexer.lex("main")

fullTokens = {}
for _,i in spairs(syntax) do
  local prevToken = nil
  for k,v in spairs(tokenTable[_]) do
    local Skip = false
    for s,t in pairs(Tokens) do
      if prevToken ~= nil and prevToken..v[2] == t() then
        fullTokens[#fullTokens] = {s,prevToken..v[2]}
        Skip = true
      end
    end
    if not Skip then
      if not isString.isString and v[1]:find("QUOTE") then
        isString.isString = true
        isString.stringSE = v[1]
      elseif isString.isString and v[1] == isString.stringSE then
        isString.isString = false
        isString.stringSE = "NIL"
      end
      if isString.isString and not v[1]:find(isString.stringSE) then v[1] = "KOTKEN_TYPE_STRING" end
      fullTokens[#fullTokens+1] = {v[1], v[2]}
    end
    prevToken = v[2]
  end
end
for _,i in pairs(fullTokens) do
  print(_,i[1],i[2])
  if i[1]:find("EOL") then
    print()
  end  
end

--[[for _,i in spairs(syntax) do
  print("Line: ".._.." = {")
  for k,v in spairs(tokenTable[_]) do
    print("\tPosition: "..k.."\tToken: "..v[1].."\tPhrase: "..v[2])
  end
  print("}\n")
end]]
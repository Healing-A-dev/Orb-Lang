local errors = require("errors")
local lexer = require("lexer")
local utils = require("utils")
local Tokens = require("Tokens")


os.execute('clear')
currentFile = "main"
local pathToFile = {"main"}
local isString = {isString = false, stringSE = "NULL"}
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
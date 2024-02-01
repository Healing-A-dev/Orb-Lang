local error = require("errors")
local lexer = require("lexer")
local utils = require("utils")
local Tokens = require("Tokens")

os.execute('clear')
currentFile = "main"
pathToFile = {"main"}
lexer.lex("main")

function __LINELENGTH(s)
  local o = {}
  for str in s:gmatch("%w+") do
    o[#o+1] = str
  end
  for spec in s:gmatch("%p") do
    local concated = false
    for _,i in pairs(Tokens) do
      if #o > 0 and o[#o]..spec == i() then
        o[#o] = o[#o]..spec
        concated = true
      end
    end
    if not concated then
      o[#o+1] = spec
    end
  end
  return #o
end

local rtable = {}
if currentFile == "main" and not syntax[1]:find('@format "sh.io"') then
  error.newError("Format",currentFile,1)
elseif currentFile ~= "main" then
  if not syntax[1]:find('@foramt ".+"') then
    error.newError("Format",currentFile,1)
  elseif syntax[1]:find('@format ".+"') and not syntax[1]:match('"lib.module"') then
    error.newError("Format",currentFile,1)
  end
end

num = 0
local isStatement = false
for _,i in pairs(syntax) do
  if #i ~= 0 then
    num = num + __LINELENGTH(i)
    for s,t in pairs(fullTokens) do
      if t[3] == "STATEMENT" or t[3] == "STATEMENT_EXT" then
        isStatement = true
      end
    end
    if fullTokens[num] ~= nil and isStatement and fullTokens[num][1]:find("CBRACE") then
      fullTokens[num][1] = Tokens.OTOKEN_KEY_EOL()
      isStatement = false
    end
    if fullTokens[num] ~= nil and not fullTokens[num][1]:find("EOL") and not fullTokens[num][1]:find("OBRACE") and not fullTokens[num+1][1]:find("OBRACE") and not fullTokens[num+1][1]:find("EOL")then
      print(fullTokens[num][2])
      error.newError("EOL",currentFile,_)
    end
  end
end

--[[for _,i in pairs(fullTokens) do -- for token debugging
  print(i[1],i[2],i[3])
end]]

print("\027[94m".."No errors!!! :D".."\027[0m")
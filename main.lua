local error = require("errors")
local lexer = require("lexer")
local utils = require("utils")
local Tokens = require("Tokens")

os.execute('clear')
currentFile = "main"
pathToFile = {"main"}
lexer.lex("main")

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

function __LINELENGTH(s)
  local o = {}
  for str in s:gmatch("%w+") do
    o[#o+1] = str
  end
  for spec in s:gmatch("%p") do
    o[#o+1] = spec
  end
  return #o
end

num = 0
local isStatement = false
for _,i in pairs(syntax) do
  if #i ~= 0 then
    num = num + __LINELENGTH(i)
    for s,t in pairs(fullTokens) do
      if t[3] == "STATEMENT" then
        isStatement = true
      end
    end
    if isStatement and fullTokens[num][1]:find("CBRACE") and #i:gsub("%s","") == 1 then
      fullTokens[num][1] = Tokens.OTOKEN_KEY_EOL()
      isStatement = false
    end
    if not fullTokens[num][1]:find("EOL") and not fullTokens[num][1]:find("OBRACE") then
      --error.newError("EOL",currentFile,_)
    end
  end
end

for s,t in pairs(fullTokens) do
  print(t[1],t[2])
end
local error = require("errors")
local lexer = require("lexer")
local utils = require("utils")
local Tokens = require("Tokens")

os.execute('clear')
currentFile = "main"
pathToFile = {"main"}
lexer.lex("main")

--[[for _,i in pairs(fullTokens) do
  print(_,i[1],i[2])
  if i[1]:find("EOL") then
    print()
  end  
end]]

local rtable = {}
if currentFile == "main" and not syntax[1]:find('@format "sh.io"') then
  error.newError("Format",currentFile,1)
elseif currentFile ~= "main" and not syntax[1]:find("@foramt lib.module") then
  error.newError("Foramt",currentFile,1)
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
for _,i in pairs(syntax) do
  if #i ~= 0 then
    num = num + __LINELENGTH(i)
    if not fullTokens[num][1]:find("EOL") then
      error.newError("EOL",currentFile,_)
    end
  end
end

--print(lexer.fetchToken(";"))
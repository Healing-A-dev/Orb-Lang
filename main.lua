local error = require("errors")
local lexer = require("lexer")
local utils = require("utils")
local Tokens = require("Tokens")

os.execute('clear')
currentFile = "main"
pathToFile = {"main"}
lexer.lex("main")

function __ENDCHAR(lineNumber)
  lineNumber = tonumber(lineNumber)
  local lastValue = nil
  local inverted = {}
  local tmp = {}
  local position = nil
  for k,v in pairs(phraseTable[lineNumber]) do
    inverted[v.Start] = k
  end
  for s,t in spairs(inverted) do
    tmp[#tmp+1] = t:gsub("%%","")
    lastValue = t:gsub("%%","")
    position = s
  end
  return {Character = lastValue, Token = lexer.fetchToken(lastValue), oneBefore = tmp[#tmp-1], Position = position}
end


local rtable = {}
if currentFile == "main" and not syntax[1]:find('@format "sh.io"') then
  error.newError("Format",currentFile,1)
elseif currentFile ~= "main" then
  if not syntax[1]:find('@foramt ".+"') then
    error.newError("Format",currentFile,1)
  elseif syntax[1]:find('@format ".+"') and not syntax[1]:match('%s"lib.module"') then
    error.newError("Format",currentFile,1,syntax[1]:match('%s+'))
  end
end

num = 0
local Statement = {isStatement = false}
for _,i in pairs(syntax) do
  if #i ~= 0 then
    num = num + __ENDCHAR(_).Position
    for s,t in pairs(fullTokens[_]) do
      if t[3] == "STATEMENT" or t[3] == "STATEMENT_EXT" then
        if not __ENDCHAR(_).Token:find("OBRACE") or __ENDCHAR(_).Token:find("OBRACE") and not lexer.fetchToken(__ENDCHAR(_).oneBefore):find("COLON") then
          local currentStatement = t[2]
          error.newError("STATEMENT",currentFile,_,currentStatement)
        end
        if t[3] == "STATEMENT" then
          Statement[#Statement+1] = t[2]
        end
        Statement.isStatement = true
      end
    end
    if Statement.isStatement and __ENDCHAR(_).Token:find("CBRACE") then
      --erm...got some reworking to do i see...
      fullTokens[_][#fullTokens[_]][1] = Tokens.OTOKEN_KEY_EOL()
      table.remove(Statement,#Statement)
      if #Statement == 1 then print("STATEMENT DONE WITH") Statement.isStatement = false end
    end
    if not fullTokens[_][#fullTokens[_]][1]:find("EOL") and not fullTokens[_][#fullTokens[_]][1]:find("OBRACE") then
      --error.newError("EOL",currentFile,_)
    end
  end
end



for _,i in pairs(syntax) do
  for k,v in pairs(fullTokens[_]) do
    print(v[1].."\t"..v[2].."\t"..tostring(v[3]))
  end
  print()
end

print("\027[94m".."No errors!!! :D".."\027[0m")
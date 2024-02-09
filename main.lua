local error = require("errors")
local lexer = require("lexer")
local utils = require("utils")
local Tokens = require("Tokens")

os.execute('clear')
currentFile = "main"
pathToFile = {"main"}
Variables = {Global = {}, Static = {}}

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

lexer.lex("main")

local rtable = {}
if currentFile == "main" and not syntax[1]:find('@format "sh.io"') then
  error.newError("Format",currentFile,1)
elseif currentFile ~= "main" then
  if not syntax[1]:find('@foramt ".+"') then
    error.newError("Format",currentFile,1)
  elseif syntax[1]:find('@format ".+"') and not syntax[1]:match('%s"lib.module"') then
    error.newError("Format",currentFile,1,{syntax[1]:match('%s+')})
  end
end

local Statement = {isStatement = false} -- For statement checking
local Table = {isTable = false}

for _,i in pairs(syntax) do

  --If then legnth of the current line is greater than 0, move onto syntax checking
  if #i:gsub("%s+","") ~= 0 then
    
    --Loops through the completed token table
    for s,t in pairs(fullTokens[_]) do

      --Checks to see if the token assigned to the phrase is a keyword that requires a corresponding "end","do","then" in its Lua equivelent and makes sure that the proper symbol in Orb is used to initiate said statement ":{"
      if t[3] == "STATEMENT" and not t[1]:find("NAME") or t[3] == "STATEMENT_EXT" and not t[1]:find("NAME") then

        --Throws error if proper symbol is not found
        if not __ENDCHAR(_).Token:find("OBRACE") or __ENDCHAR(_).Token:find("OBRACE") and not lexer.fetchToken(__ENDCHAR(_).oneBefore):find("COLON") then
          error.newError("STATEMENT_INIT",currentFile,_,{t[2],Statement})
        end

        --If syntax check passed, add the statment to the statement table
        if t[3] == "STATEMENT" then
          Statement[#Statement+1] = t[2]
        end

        --For syntax and lexing reasons
        Statement.isStatement = true
      end

    end
    
    --Check to see if "}" is found and is the closing part of a statement
    if Statement.isStatement and __ENDCHAR(_).Token:find("CBRACE") and #i:gsub("%s+","") == 1 then
      --Adjust Accordingly to an <EOL> token
      fullTokens[_][#fullTokens[_]][1] = Tokens.OTOKEN_KEY_EOL()
      --Removes statement for the Statement table
      table.remove(Statement,#Statement)
      --Check to see if the Statement table is empty. If so, statement turn off statement checking
      if #Statement == 0 then Statement.isStatement = false end
    end

    --End of line syntax checking
    if not fullTokens[_][#fullTokens[_]][1]:find("EOL") and not fullTokens[_][#fullTokens[_]][1]:find("OBRACE") then
      error.newError("EOL",currentFile,_)
    end
  end
end


for _,i in pairs(Variables) do
  print(_)
  for s,t in pairs(i) do
    if type(t) == "table" then
      print(" - "..t[1]..": "..t[2])
    else
      print(" - "..s..": "..t)
    end
  end
  print()
end

print("\027[94m".."No errors!!! :D".."\027[0m") --Happy messege :D

--I can either make types required or have the compiler figure it out...HMMMMMM. Mind you, this is I need to choose for table syntax checking
-- File Imports--
local error = require("errors")
local lexer = require("lexer")
local utils = require("utils")
local Tokens = require("Tokens")
local variables = require("variables")
local expressions = require("expressions")

-- Some extra stuff needed for compilation (transpilation)
os.execute('clear') -- Clearing the console
pathToFile = {}
Variables = {Global = {}, Static = {},Temporary = {}}
local _Compiled = {}

_STACK = {
  pop = function(self)
    table.remove(self,#self)
  end,
  current = function(self)
    return self[#self]
  end,
  append = function(self,value)
    self[#self+1] = value
  end,
  len = function(self)
    return #self
  end
}

function __ENDCHAR(lineNumber,seek)
  seek = seek or 0
  lineNumber = tonumber(lineNumber+seek)
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
  return {Character = lastValue, Token = lexer.fetchToken(lastValue), oneBefore = tmp[#tmp-1] or tmp[#tmp], Position = position}
end


-- Below is going to be the compiler (trasnpiler) for the language
-- This file is going to be renamed to compiler.lua
-- I still have a lot of stuff to do like table syntaxing and defs and built it http (socket) support
-- But once this is done I'll start working on my bigger project >:)
-- Project Birdcage


lexer.lex("main") -- Tokenizing the file
function syntax.nextLine(line) if syntax[line+1] ~= nil then return syntax[line+1] end end -- Just to Seek ahead
pathToFile[#pathToFile+1] = currentFile -- Adding file to path

-- ERROR CHECKING --
if currentFile == "main" and not syntax[1]:find('@fmt "std.io"') then
  error.newError("FORMAT",currentFile,1)
elseif currentFile ~= "main" then
  if not syntax[1]:find('@fmt') then
    error.newError("FORMAT",currentFile,1)
  elseif syntax[1]:find('@fmt ".+"') and not syntax[1]:find('"lib.module"') then
    error.newError("FORMAT",currentFile,1,{syntax[1]:match('%s+')})
  end
end

for _,i in ipairs(syntax) do
  --If then legnth of the current line is greater than 0, move onto syntax checking
  if #i:gsub("%s+","") ~= 0 then
    --Loops through the completed token table
    for s,t in pairs(fullTokens[_]) do
      __ADDVARS(_)
      if t[3] == "STATEMENT" and not t[1]:find("NAME") or t[3] == "STATEMENT_EXT" and not t[1]:find("NAME") then
        --Throws error if proper initiation symbol is not found
        if not __ENDCHAR(_).Token:find("OBRACE") or __ENDCHAR(_).Token:find("OBRACE") and not lexer.fetchToken(__ENDCHAR(_).oneBefore):find("COLON") then
          error.newError("STATEMENT_INIT",currentFile,_,{t[2],_STACK:current()[2],fullTokens[_][s+1][2]})
        end
        --If syntax check passed, add the statment to the stack
        _STACK:append({t[1],t[2],t[3],_,fullTokens[_][s+1][2]})
        expressions.parseExpression(_)
        --For syntax and lexing reasons
      elseif t[3] == "VARIABLE" and __ENDCHAR(_).Token:find("OBRACE") and variables.isArray(t) then
        _STACK:append({t[1],t[2],t[3],_})
      end
    end
    --Check to see if "}" is found and is the closing part of a statement or table
    if __ENDCHAR(_).Token:find("EOL") and _STACK:len() > 0 and lexer.fetchToken(__ENDCHAR(_).oneBefore):find("CBRACE")  or __ENDCHAR(_).Token:find("CBRACE") and _STACK:len() > 0 then
      if _STACK:current()[3] ~= "VARIABLE" and #i:gsub("%s+","") == 1 then
        if _STACK:current()[2]:upper() == Tokens.OTOKEN_KEYWORD_FOR() then
          Variables.Temporary = {}
        end
        fullTokens[_][#fullTokens[_]][1] = Tokens.OTOKEN_KEY_EOL()
        _STACK:pop()
      elseif _STACK:current()[3] == "VARIABLE" then
        _STACK:pop()
      end
    end
    --End of line syntax checking
    if _STACK:len() > 0 then
      if _STACK:current()[3] == "VARIABLE" and not fullTokens[_][#fullTokens[_]][1]:find("COMMA") and not fullTokens[_][#fullTokens[_]][1]:find("OBRACE") and not syntax.nextLine(_):find("%}") then
        error.newError("EOL_TABLE",currentFile,_)
      elseif _STACK:current()[3] ~= "VARIABLE" and not fullTokens[_][#fullTokens[_]][1]:find("EOL") and not fullTokens[_][#fullTokens[_]][1]:find("OBRACE") then
        error.newError("EOL",currentFile,_)
      end
    elseif _STACK:len() == 0 and not fullTokens[_][#fullTokens[_]][1]:find("EOL") and not fullTokens[_][#fullTokens[_]][1]:find("OBRACE") then
      error.newError("EOL",currentFile,_)
    end
  end
end

if _STACK:len() > 0 and _STACK:current()[3]:find("STATEMENT") then
  error.newError("STATEMENT_END_FUNCTION",currentFile,_STACK:current()[4],{_STACK:current()[2],"",_STACK:current()[5]})
end

-- DEBUGGING --
for _,i in ipairs(_STACK) do
  print("{[".._.."] "..table.concat(i,", ").."}\n")
end

print("-------------------")

for _,i in pairs(Variables) do
  print(_..":")
  for s,t in pairs(i) do
    print(" - "..s..": "..t.Type.." |Value: "..t.Value.."|")
  end
  print()
end

--[[print("-------------------")

for _,i in pairs(fullTokens) do
  for s = 1, #i do
    print(fullTokens[_][s][1]..": ["..fullTokens[_][s][2].."]: "..tostring(fullTokens[_][s][3]))
  end
  print()
end]]
print("\027[94m".."No errors!!! :D".."\027[0m") --Happy messege :D

--local _function = syntax[#syntax-0]:match("%s?.+%.?%w?%("):chop()
for _,i in pairs(fullTokens) do
  for s = 1, #i do
    if _ > 1 then
      local PRINT = false
      local TOKEN,nextTOKEN = fullTokens[_][s][1],nil
      local VALUE,nextVALUE = fullTokens[_][s][2],nil
      if fullTokens[_][s+1] ~= nil then
        nextTOKEN = fullTokens[_][s+1][1]
        nextVALUE = fullTokens[_][s+1][2]
      end
      if TOKEN:find("COLON") and (nextVALUE:match("String") or nextVALUE:match("Number") or nextVALUE:match("Char") or nextVALUE:match("Array") or nextVALUE:match("Bool") or nextVALUE:match("Any")) then
        VALUE = "*#SKIP#*"
        fullTokens[_][s+1][2] = "*#SKIP#*"
      end
      if TOKEN:match("<EOL>") then
        VALUE = "end"
      elseif TOKEN:match("CONCAT") then
        VALUE = ".."
      elseif TOKEN:match("STATIC") then
        VALUE = "local "
      elseif TOKEN:match("PUTLN") then
        VALUE = "print("
        PUTLN = true
      elseif TOKEN:match("TYPE_EOL") and PUTLN then
        VALUE = ")\r"
        PUTLN = false
      elseif VALUE ~= "*#SKIP#*" and not TOKEN:match("QUOTE") and nextTOKEN ~= nil and not nextTOKEN:match("CONCAT") then
        VALUE = ""..VALUE.." "
      end
    end
  end
end

--print(table.concat(_Compiled,""))
local test = io.open("TEMP.lua","w+")
test:write(table.concat(_Compiled,""))
test:close()
dofile("TEMP.lua")
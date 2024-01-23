local lexer = {}

--[Imports]--
local utils   = require("utils")
local errors  = require("errors")
local Tokens  = require("Tokens")

--Creates the tokens
function lexer.fetchToken(ttf,line)
  local assignedToken = {}
  local Keywords = {}
  assignedToken[line] = {}
  assigned_Token[line] = {}
  for s in ttf:gmatch("([^%s]+)") do
    assignedToken[line][#assignedToken[line]+1] = s
  end
  for _,i in pairs(assignedToken[line]) do
    for k,v in pairs(Tokens) do
      for sepStr in i:gmatch("%w+") do --STRINGS
        if sepStr:upper() == v() or type(sepStr):upper() == v() and not table.search(Keywords,sepStr) then
          if tostring(k):find("KEYWORD") then
            Keywords[#Keywords+1] = sepStr
          end
          assigned_Token[line][#assigned_Token[line]+1] = {sepStr, k}
        end
      end
      if type(tonumber(i:gsub("%p"," "):match("%d+"))):upper() == v() then --NUMBERS
        for test in i:gmatch("%d+") do
          assigned_Token[line][#assigned_Token[line]+1] = {test, k}
        end
      elseif i:match("^%[%"..v().."]+") then
        assigned_Token[line][#assigned_Token[line]+1] = {i:match(v()), k}
      end
      for sep in i:gmatch("%p") do
        for pos,str in pairs(sep:split()) do
          if str:find("%"..v()) then
            assigned_Token[line][#assigned_Token[line]+1] = {str, k}
          end
        end
      end
    end
    for k,v in pairs(Tokens) do
      if i:gsub("%p","") == v() then
        assigned_Token[line][#assigned_Token[line]+1] = {i:gsub("%p",""), k}
      end
    end
  end
end

--Organizes the tokens into the order they appear and adjust them depeneding on location and other tokens
function lexer.lex(program)
  assigned_Token = {}
  tokenTable = {}
  phraseTable = {}
  if not program:find("%<lua>") then
    program = program..".orb"
  end
  f = io.open(program,"r") or error.newError("Not_found",program)
  local lines = f:lines()
  split, syntax = utils.stringify(lines)
  for _,i in pairs(syntax) do
    lexer.fetchToken(i,_)
  end
  for _,i in pairs(syntax) do
    tokenTable[_] = {}
    for k,v in pairs(assigned_Token[_]) do
      for s,t in spairs(v) do
        tokenTable[_][syntax[_]:position(v[1],_).Start] = {v[2],v[1]}
      end
    end
  end
  return tokenTable, split, syntax
end

return lexer
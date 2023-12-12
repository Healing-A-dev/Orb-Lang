local lexer = {}

--[Imports]--
local utils   = require("utils")
local errors  = require("errors")
local Tokens  = require("Tokens")

--Creates the tokens
function lexer.fetchToken(ttf,line)
  local assignedToken = {}
  assignedToken[line] = {}
  assigned_Token[line] = {}
  for _,i in pairs(Tokens) do
    assigned_Token[i()] = tostring(_)
  end
  for s in ttf:gmatch("([^%s]+)") do
    assignedToken[line][#assignedToken[line]+1] = s
  end
  for _,i in pairs(assignedToken[line]) do
    for k,v in pairs(Tokens) do
      for sepStr in i:gmatch("%w+") do
        if sepStr:upper() == v() or type(sepStr):upper() == v() and assigned_Token[line][sepStr] == nil then
          assigned_Token[line][sepStr] = k
        end
      end
      if type(tonumber(i:gsub("%p"," "):match("%d+"))):upper() == v() then
        for test in i:gmatch("%d+") do
          assigned_Token[line][test] = k
        end
      elseif i:match("^%[%"..v().."]+") then
        assigned_Token[line][i:match(v())] = k
      end
      for sep in i:gmatch("%p") do
        for pos,str in pairs(sep:split()) do
          if str:find("%"..v()) then
            assigned_Token[line][str] = k
          end
        end
      end
    end
    for k,v in pairs(Tokens) do
      if i:gsub("%p","") == v() then
        assigned_Token[line][i:gsub("%p","")] = k
      end
    end
  end
end

--Organizes the tokens into the order they appear and adjust them depeneding on location and other tokens
function lexer.lex(program)
  assigned_Token = {}
  tokenTable = {}
  if not program:find("%<lua>") then
    program = program..".orb"
  end
  f = io.open(program,"r") or __Orb.ThrowError("Not_found",program)
  local lines = f:lines()
  split, syntax = utils.stringify(lines)
  for _,i in pairs(syntax) do
    lexer.fetchToken(i,_)
  end
  for _,i in pairs(syntax) do
    tokenTable[_] = {}
    for k,v in spairs(split[_]) do
      for s,t in spairs(assigned_Token[_]) do
        if v == s then
          tokenTable[_][k] = {t,s}
        end
      end
    end
  end
  for _,i in pairs(syntax) do
    for k,v in spairs(assigned_Token[_]) do
      for s,t in spairs(tokenTable[_]) do
        if tokenTable[_][i:position(k).Start] == nil then tokenTable[_][i:position(k).Start] = {v,k} end
      end
      tokenTable[_][i:position(k).Start] = {v,k}
    end
  end
  return tokenTable, split, syntax
end

return lexer

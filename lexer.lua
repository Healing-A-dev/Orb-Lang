local lexer = {}

--[Imports]--
local utils   = require("utils")
local error   = require("errors")
local Tokens  = require("Tokens")
local types   = require("types")

--Creates the tokens
function lexer.createToken(ttf,line)
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
        if sepStr:upper() == v() or type(sepStr):upper() == v() and not table.search(Keywords,sepStr) and not tonumber(sepStr) then
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
        for _,str in pairs(sep:split()) do
          if str:find("%"..v()) then
            assigned_Token[line][#assigned_Token[line]+1] = {str, k}
          end
        end
      end
      if i:gsub("%p","") == v() then
        assigned_Token[line][#assigned_Token[line]+1] = {i:gsub("%p",""), k}
      end
    end
  end
end

--Fetch the Token of input variable
function lexer.fetchToken(token)
  local returnToken = {}
  for _,i in pairs(assigned_Token) do
    for s,t in pairs(i) do
      if t[1] == token then
        returnToken = t
        break
      end
    end
  end
  return returnToken[2]
end


--Organizes the tokens into the order they appear and adjusts them depeneding on location and other tokens
function lexer.lex(program)
  assigned_Token = {}
  tokenTable = {}
  phraseTable = {}
  fullTokens = {}
  Variables.Static = {}
  local isString = {isString = false, stringSE = nil}
  if not program:find("%<lua>") then
    program = program..".orb"
  end
  f = io.open(program,"r") or error.newError("Not_found",program)
  local lines = f:lines()
  split, syntax = utils.stringify(lines)

  for _,i in pairs(syntax) do --Gets tokens
    lexer.createToken(i,_)
  end

  for _,i in pairs(syntax) do --Arranges collected tokens
    tokenTable[_] = {}
    for k,v in pairs(assigned_Token[_]) do
      for s,t in spairs(v) do
        tokenTable[_][syntax[_]:position(v[1],_).Start] = {v[2],v[1]}
      end
    end
  end
  
  for _,i in spairs(syntax) do --Adjusts accordingly
    local prevToken = nil
    fullTokens[_] = {}
    for k,v in spairs(tokenTable[_]) do
      --print(tokenTable[_][k][2])
      local Skip = false
      for s,t in pairs(Tokens) do
        if prevToken ~= nil and prevToken[2]..v[2] == t() then
          fullTokens[_][#fullTokens[_]] = {s,t()}
          Skip = true
        end
      end
      if not Skip then
        if v[1]:find("IF") and not v[1]:find("ELIF") or v[1]:find("ELIF") or v[1]:find("FOR") and not v[1]:find("FORMAT") or v[1]:find("WHILE") or v[1]:find("DEF") and not v[1]:find("DEFCALL") or v[1]:find("INCLUDING") or v[1]:find("FUNC") then
          v[3] = "STATEMENT"
        end
        if v[1]:find("DIVIDE") then
          if prevToken ~= nil and prevToken[1]:find("NUMBER") then
            v[1] = v[1]
          elseif prevToken ~= nil and not prevToken[1]:find("NUMBER") then
            v[1] = "OTOKEN_SPECIAL_CONCAT"
          end
        elseif prevToken ~= nil and prevToken[1]:find("STATIC") and not v[1]:find("FUNC") then
          v[1] = "OTOKEN_SPECIAL_SVARIABLE"
          v[3] = "VARIABLE"
        elseif prevToken ~= nil and prevToken[1]:find("STATIC") and v[1]:find("FUNC") then
          v[1] = "OTOKEN_SPECAIL_SFUNC"
        elseif prevToken ~= nil and prevToken[1]:find("SET") and not v[1]:find("STATIC") and not v[1]:find("FUNC") then
          v[1] = "OTOKEN_SPECIAL_GVARIABLE"
          v[3] = "VARIABLE"
        elseif prevToken ~= nil and prevToken[1]:find("SFUNC") and not prevToken[1]:find("NAME") and not v[1]:find("OPAREN") then
          v[1] = "OTOKEN_SPECIAL_SFUNC_NAME"
        elseif prevToken ~= nil and prevToken[1]:find("SFUNC") and prevToken[1]:find("NAME") and not v[1]:find("OPAREN") then
          v[1] = "OTOKEN_SPECIAL_SFUNC_NAME_EXT"
        elseif prevToken ~= nil and prevToken[1]:find("FUNC") and not prevToken[1]:match("SFUNC") and not prevToken[1]:find("NAME") and not v[1]:find("OPAREN") then
          v[1] = "OTOKEN_SPECIAL_FUNC_NAME"
        elseif prevToken ~= nil and prevToken[1]:find("FUNC") and prevToken[1]:find("NAME") and not prevToken[1]:find("SFUNC") and not v[1]:find("OPAREN") then
          v[1] = "OTOKEN_SPECIAL_FUNC_NAME_EXT"
        end
        if not isString.isString and v[1]:find("QUOTE") then
          isString.isString = true
          isString.stringSE = v[1]
        elseif isString.isString and v[1] == isString.stringSE then
          isString.isString = false
          isString.stringSE = nil
        end
        if isString.isString and not v[1]:find(isString.stringSE) then v[1] = "OTOKEN_TYPE_STRING" v[3] = nil end
        fullTokens[_][#fullTokens[_]+1] = {v[1], v[2], v[3]}
      end
      prevToken = {v[1], v[2]}
    end
  end

  for _,i in pairs(fullTokens) do
    local fName = {}
    local prev = nil
    for s = 1, #i do
      local currentToken = fullTokens[_][s]
      if prev ~= nil and prev[1]:find("ASSIGN") and not currentToken[1]:find("FUNC") and not currentToken[1]:find("STATIC") then
        fullTokens[_][s][1] = "OTOKEN_SPECIAL_GVARIABLE_ANY"
        fullTokens[_][s][3] = "VARIABLE"
      elseif prev ~= nil and prev[1]:find("ASSIGN") and currentToken[1]:find("STATIC") then
        fullTokens[_][s+1][1] = "OTOKEN_SPECIAL_SAVARIABLE_ANY"
        fullTokens[_][s+1][3] = "VARIABLE"
      end

      -- Getting Function Names
      if currentToken[1]:find("NAME") then
        fName[#fName+1] = {currentToken[2], _, s, currentToken[1]}
      elseif currentToken[1]:find("OPAREN") and prev ~= nil and prev[1]:find("NAME") then
        break
      end
      prev = currentToken
    end
    if #fName > 0 then
      table.remove(fName,2)
      fullTokens[fName[1][2]][fName[1][3]] = {fName[1][4], utils.getFunctionName(fName,1), nil}
    end
  end
  for _,i in pairs(fullTokens) do
    for s = 1, #i do
      if i[s][1]:find("GVARIABLE") then
        local var = i[s][2]
        if not i[s][1]:find("ANY") then
          Variables.Global[var] = types.getVarType(var)
        else
          Variables.Global[var] = "Any"
        end
      elseif i[s][1]:find("SVARIABLE") then
        local var = i[s][2]
        Variables.Static[#Variables.Static+1] = {var, types.getVarType(var)}
      end
    end
  end

  return tokenTable, split, syntax
end


return lexer
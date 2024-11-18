local lexer = {}

--[Imports]--
local utils   = require("src/utils")
local error   = require("src/errors")
local Tokens  = require("src/Tokens")
local types   = require("src/types")

--Creates the tokens
function lexer.createToken(ttf,line)
  local assignedToken = {}
  local Keywords = {}
  assignedToken[line] = {}
  assigned_Token[line] = {}

  for s in ttf:gmatch("%s?.+%s?") do
    assignedToken[line][#assignedToken[line]+1] = s
  end
  for _,i in pairs(assignedToken[line]) do
    for k,v in pairs(Tokens) do
      for sepStr in i:gmatch("%w+") do --STRINGSprint("FOUND A PLUSSSS")
        if sepStr:upper() == v() or type(sepStr):upper() == v() and not table.search(Keywords,sepStr) and not tonumber(sepStr) then
          if tostring(k):find("KEYWORD") then
            Keywords[#Keywords+1] = sepStr
          end
          assigned_Token[line][#assigned_Token[line]+1] = {sepStr, k}
        end
      end
      for sep in i:gmatch("%W") do
        if sep == v() then
          assigned_Token[line][#assigned_Token[line]+1] = {sep, k}
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
  return returnToken[2] or false
end


--Organizes the tokens into the order they appear and adjusts them depeneding on location and other tokens
function lexer.lex(program)
  currentFile = program
  assigned_Token = {}
  tokenTable = {}
  phraseTable = {}
  fullTokens = {}
  fullTokens_SYNTAX = {}
  Variables.Static = {}
  local isString = {isString = false, stringSE = nil}
  local is_Multiline_Comment = false
  local f
  if not program:find("%s+") then
      if not program:find("%..+$") then
        program = program..".orb"
      end
      f = io.open(program,"r")
      local lines = f:lines()
      split, syntax = utils.stringify(lines)
      f:close()
  end
    for _,i in pairs(syntax) do --Gets tokens
      lexer.createToken(i,_)
    end
    
    for _,i in pairs(syntax) do --Arranges collected tokens
      tokenTable[_] = {}
      for k,v in pairs(assigned_Token[_]) do
        for s,t in ipairs(v) do
            tokenTable[_][syntax[_]:position(v[1],_).Start] = {v[2],v[1]}
        end
      end
    end
    
  for _,i in ipairs(syntax) do --Adjusts accordingly
    local prevToken = nil
    fullTokens[_] = {}
    for k,v in spairs(tokenTable[_]) do
      local Skip = false
      for s,t in pairs(Tokens) do
        if prevToken ~= nil and prevToken[2]..v[2] == t() then
          if s:find("COMMENT") then
            fullTokens[_][#fullTokens[_]] = {s,t(),Tokens.OTOKEN_KEY_COMMENT()}
          else
            fullTokens[_][#fullTokens[_]] = {s,t()}
          end
          Skip = true
        end
      end
      if not Skip then
        if v[1]:find("IF") and not v[1]:find("ELSEIF") or v[1]:find("ELSEIF") or v[1]:find("FOR") and not v[1]:find("FORMAT") or v[1]:find("WHILE") or v[1]:find("DEFINE") and not v[1]:find("DEFCALL") or v[1]:find("FUNC") then
          v[3] = "STATEMENT"
        end
        if v[1]:find("SPACE") then
            goto isSpace 
        end
        if prevToken ~= nil then
          if v[1]:find("SQUIGGLE") then
            -- if prevToken ~= nil and prevToken[1]:find("NUMBER") then
              -- v[1] = v[1]
            -- elseif prevToken ~= nil and not prevToken[1]:find("NUMBER") and not tokenTable[_][k+1][1]:find("NUMBER") then
              v[1] = "OTOKEN_SPECIAL_CONCAT"
            -- end
          end


          if prevToken[1]:find("SET") then
            if not v[1]:find("KEYWORD") and not tonumber(v[2]) then
              v[1] = "OTOKEN_SPECIAL_GVARIABLE"
              v[3] = "VARIABLE"
            elseif v[1]:find("KEYWORD") and not v[1]:find("STATIC") or tonumber(v[2]) then
              if tonumber(v[2]) then
                error.newError("SYNTAX_VAR",currentFile,_,{"number value",v[2]})
              else
                local keyword,word = v[1]:match("KEYWORD_"):gsub("_",""):lower(),v[1]:match("KEYWORD_%w+"):gsub("KEYWORD_",""):lower()
                if word == "function" then word = "func " end
                error.newError("SYNTAX_VAR",currentFile,_,{keyword,word})
              end
            end
          elseif prevToken[1]:find("STATIC") then
            if not v[1]:find("KEYWORD") and not tonumber(v[2]) then
              v[1] = "OTOKEN_SPECIAL_SVARIABLE"
              v[3] = "VARIABLE"
            elseif v[1]:find("KEYWORD") and v[1]:find("FUNC") then
              v[1] = "OTOKEN_SPECIAL_SFUNC"
            else
              if tonumber(v[2]) then
                error.newError("SYNTAX_VAR",currentFile,_,{"number value",v[2]})
              else
                local keyword,word = v[1]:match("KEYWORD_"):gsub("_",""):lower(),v[1]:match("KEYWORD_%w+"):gsub("KEYWORD_",""):lower()
                if word == "function" then word = "func " end
                error.newError("SYNTAX_VAR",currentFile,_,{keyword,word})
              end
            end
          elseif prevToken[1]:find("SFUNC") then
            if not prevToken[1]:find("NAME") and not v[1]:find("OPAREN") then
              v[1] = "OTOKEN_SPECIAL_SFUNC_NAME"
              v[2] = ""
            elseif prevToken[1]:find("NAME") and not v[1]:find("OPAREN") then
              v[1] = "OTOKEN_SPECIAL_SFUNC_NAME_EXT"
              v[2] = ""
            else

            end
          end
        end
        ::isSpace:: --This is just to ignore spaces in the code 
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
      if not v[1]:find("SPACE") then
        prevToken = {v[1], v[2]}
      end
    end
  end

  for _,i in pairs(fullTokens) do
    local prev = nil
    for s = 1, #i do
      local currentToken = fullTokens[_][s]
      if currentToken[1]:find("MLINE_COMMENT_START") then is_Multiline_Comment = true end
      if is_Multiline_Comment and currentToken[1]:find("MLINE_COMMENT_END") then
        is_Multiline_Comment = false
      end
      if prev ~= nil then
        if prev[1]:find("QUOTE") and currentToken[1]:find("COMMENT") or prev[1]:find("STRING") and currentToken[1]:find("COMMENT") then currentToken[1] = "OTOKEN_TYPE_STRING"  currentToken[3] = nil end
        if prev[1]:find("SLINE_COMMENT") and not currentToken[1]:find("EOL") then
          currentToken[1] = "OTOKEN_SPECIAL_SLINE_COMMENT"
          currentToken[3] = Tokens.OTOKEN_KEY_COMMENT()
        elseif prev[1]:find("SLINE_COMMENT") and currentToken[1]:find("EOL") then
          currentToken[3] = Tokens.OTOKEN_KEY_COMMENT()
        elseif is_Multiline_Comment and not currentToken[1]:find("MLINE_COMMENT_END") then
          currentToken[1] = "OTOKEN_SPECIAL_MLINE_COMMENT"
          currentToken[3] = Tokens.OTOKEN_KEY_COMMENT()
        end
      end
      prev = currentToken
      if currentToken[1]:find("FUNC") and not currentToken[1]:find("NAME") then
        function_name = utils.getFunctionName(_)
        local startpoint = s+1
        while not fullTokens[_][startpoint][2]:find("%w") do
            startpoint = startpoint + 1
        end
        fullTokens[_][startpoint] = {"OTOKEN_SPECIAL_FUNC_NAME", function_name, nil}
        startpoint = startpoint + 1
        while not fullTokens[_][startpoint][2]:find("%(") do
            fullTokens[_][startpoint][2] = ""
            startpoint = startpoint + 1
        end
      end
    end
  end

  for _,i in pairs(fullTokens) do
    local isVar = false
    local varType = ""
    local hold = {BufferPos = 0, BufferEnd = 0}
      for s = 1, #i do
      local currentToken = fullTokens[_][s]
      if currentToken ~= nil then
        if currentToken[3] ~= nil and currentToken[3]:find("VARIABLE") and not isVar then
          isVar = true
          varType = currentToken[1]
          hold.BufferPos = s
          hold[1] = currentToken[2]
        end
        if isVar and not currentToken[1]:find("COLON") and not currentToken[1]:find("STATIC") then
          currentToken[1] = varType
          currentToken[3] = "VARIABLE"
          hold[1] = hold[1]..currentToken[2]:gsub(hold[1],"")
        elseif currentToken[2]:find("%=") and isVar or currentToken[1]:find("COLON") and isVar then
          hold.BufferEnd = s
          fullTokens[_][hold.BufferPos] = {varType, hold[1], "VARIABLE"}
          for k = hold.BufferPos+1, hold.BufferEnd-1 do
            fullTokens[_][k] = nil
          end
          isVar = false
          varType = ""
        end
      end
    end
    
    for _,i in pairs(fullTokens) do
      for s = 1, #i do
        if s > #i then s = #i-1 end
          if i[s] == nil then
            fullTokens[_] = nil
          end
        end
      end
    end
    
  if is_Multiline_Comment then
    print("orb: <syntax> error\ntraceback:\n\t[orb]: multiline comment not closed\n\t[file]: "..currentFile..".orb")
    os.exit()
  end
  return tokenTable, split, syntax
end


return lexer

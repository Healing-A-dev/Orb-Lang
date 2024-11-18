local runtime = {}
-- File Imports--
local error = require("src/errors")
local lexer = require("src/lexer")
local utils = require("src/utils")
local Tokens = require("src/Tokens")
local variables = require("src/variables")
local expressions = require("src/expressions")
local Transpiler = require("src/transpiler")

local imported = {}
-- Extra/Utility Functions --
pathToFile = {}
Buffer = {}
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

function __REMOVETEMPVAR(line)
  for _,i in pairs(Variables.Temporary) do
    if i.Creation == line then
      Variables.Temporary[_] = nil
    end
  end
end

-- Generate Runtime --
function runtime.run(file)
    local importing = false
    file = file or arg[1]
    if file ~= "-e" then
        lexer.lex(file) -- Tokenizing the file
        function syntax.nextLine(line) if syntax[line+1] ~= nil then return syntax[line+1] end end -- Just to Seek ahead
        pathToFile[#pathToFile+1] = currentFile -- Adding file to path

        -- ERROR CHECKING --
        if #syntax < 1 then
            print("Orb: <format> error\ntraceback:\n\t[orb]: improper format typing\n\t[file]: "..table.concat(pathToFile,"\\")..".orb\n\t[line]: 1")
            os.exit()
        else
            if currentFile == arg[1] and not syntax[1]:find('@fmt "std.io"') then
              error.newError("FORMAT",currentFile,1)
            elseif currentFile ~= arg[1] then
              if not syntax[1]:find('@fmt') then
                error.newError("FORMAT",currentFile,1)
              elseif syntax[1]:find('@fmt ".+"') and not syntax[1]:find('"lib.module"') then
                error.newError("FORMAT",currentFile,1,{syntax[1]:match('%s+')})
              end
            end
        end
    else
        lexer.lex("Interactive Interpreter")
        pathToFile[#pathToFile+1] = "(command line)"
    end
    
    for _,i in ipairs(syntax) do
      --If then legnth of the current line is greater than 0, move onto syntax checking
      if #i:gsub("%s+","") ~= 0 then
        --Loops through the completed token table
            --print(tostring(fullTokens[_]),_)
            for s,t in pairs(fullTokens[_]) do
              __ADDVARS(_)
              if t[1]:find("INCLUDING") then
                local imports = i:gsub("@including",""):gsub("[%s+%{%}%;]","")
                for files in imports:gmatch("[^%,]+") do
                    if imported[files] ~= true then
                        files = files:gsub("['\"]","")
                        if not files:find("%.lua$") then
                            --print(files)
                            importing = true
                            local importFile = io.open(files..".orb","r")
                            if not importFile then
                                print("Orb: <import> error\ntraceback:\n\t[orb]: file '"..files..".orb' not found\n\t[file]: "..arg[1].."\n\t[line]: ".._) 
                                os.exit()
                            end
                            runtime.run(files)
                            Blocks.NewBlock(files,{extensions = ".VOID"})
                            for _,i in pairs(Transpiler.translate()) do
                                Blocks.WriteToBlock(files,table.concat(i))
                            end
                            Blocks[files].run()
                            imported[files] = true
                        else
                           dofile(files) 
                        end
                    end
                end
                if importing then
                    runtime.run()
                end
              end
              if t[3] == "STATEMENT" and not t[1]:find("NAME") or t[3] == "STATEMENT_EXT" and not t[1]:find("NAME") then
                if t[1]:find("FUNCTION") then
                    local startpoint = s+1
                    while not fullTokens[_][startpoint][2]:find("%w") do
                        startpoint = startpoint+1
                    end
                    _STACK:append({t[1],t[2],t[3],_,fullTokens[_][startpoint][2]})
                else
                    _STACK:append({t[1],t[2],t[3],_,fullTokens[_][s+1][2]})
                end
                --Throws error if proper initiation symbol is not found
                if not __ENDCHAR(_).Token:find("OBRACE") or __ENDCHAR(_).Token:find("OBRACE") and not lexer.fetchToken(__ENDCHAR(_).oneBefore):find("COLON") then
                  local startpoint = s+1
                  while not fullTokens[_][startpoint][2]:find("%w") do
                    startpoint = startpoint+1
                  end
                  error.newError("STATEMENT_INIT",currentFile,_,{t[2],_STACK:current()[2],fullTokens[_][startpoint][2]})
                end

                --If syntax check passed then parse the expression
                expressions.parseExpression(_)
                
                --For syntax and lexing reasons
              elseif t[3] == "VARIABLE" and __ENDCHAR(_).Token:find("OBRACE") and variables.isArray(t) then
                _STACK:append({t[1],t[2],t[3],_})
              end
            end
            
        --Check to see if "}" is found and is the closing part of a statement or table
        if __ENDCHAR(_).Token:find("EOL") and _STACK:len() > 0 and lexer.fetchToken(__ENDCHAR(_).oneBefore):find("CBRACE")  or __ENDCHAR(_).Token:find("CBRACE") and _STACK:len() > 0 then
          if _STACK:current()[3] ~= "VARIABLE" and #i:gsub("%s+","") == 1 then
            if _STACK:current()[2]:upper() == Tokens.OTOKEN_KEYWORD_FOR() or _STACK:current()[2]:upper() == Tokens.OTOKEN_KEYWORD_FUNCTION() then
              --Clear Temporary Variables
              __REMOVETEMPVAR(_STACK:current()[4])
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
          elseif _STACK:current()[3] ~= "VARIABLE" and not fullTokens[_][#fullTokens[_]][1]:find("EOL") and not fullTokens[_][#fullTokens[_]][1]:find("OBRACE") and fullTokens[_][#fullTokens[_]][3] == nil then
            error.newError("EOL",currentFile,_)
          end
        elseif _STACK:len() == 0 and not fullTokens[_][#fullTokens[_]][1]:find("EOL") and not fullTokens[_][#fullTokens[_]][1]:find("OBRACE") and fullTokens[_][#fullTokens[_]][3] == nil then
          error.newError("EOL",currentFile,_)
        end
      end 
      
      local isString = false
      for s,t in pairs(fullTokens[_]) do
        if not t[1]:find("SPACE") then
            if t[1]:match("OPAREN") then
                if fullTokens[_][s-1][1]:match("COMMONS") then
                    local funcName = utils.getFunctionName(_,true)
                    if not utils.varCheck(funcName).Real then 
                        local functionName = utils.getFunctionName(_,true)
                        error.newError("UNKNOWN_FUNCTION_CALL",currentFile,_,{functionName})
                    else
                        fullTokens[_][s-1][1] = "OTOKEN_FUNC_NAME"
                        local str = {}
                        local args = {}
                        local strEnd = false
                        local i = i:match("->%s?%(.+%)") or ""
                        i = i:gsub("->%s?",""):gsub("^%(",""):gsub("%)$","")
                        for arg in i:gmatch("[%S^%,]+") do
                            arg = arg:gsub("%(%)$",""):gsub("^%(",""):gsub("%)$","")
                            if arg:find("^['\"]") and not arg:find("['\"]$") then
                                isString = true
                            elseif arg:find("['\"]$") and isString then
                                strEnd = true
                                isString = false
                            end
                            if isString then
                                str[#str+1] = arg
                            elseif strEnd then
                                str[#str+1] = arg
                                args[#args+1] = table.concat(str,",")
                                strEnd = false
                            elseif arg:find("^['\"]") and arg:find("['\"]$") then
                                args[#args+1] = arg
                            else
                                if not utils.varCheck(arg).Real and not isString then
                                    error.newError("UNKNOWN_VAR_CALL",currentFile,_,{arg})
                                else
                                    args[#args+1] = arg
                                end
                            end
                            --Update temporray varible value
                            variables.__UPDATETEMPVAR(utils.getArgument(funcName,1),arg,_)
                        end
                    end
                end
            end
        end
      end
      
      for s,t in pairs(fullTokens[_]) do
        if not t[1]:find("SPACE") then
            local var = nil 
            if fullTokens[_][s-1] ~= nil then
                if t[1]:find("COMMON") and fullTokens[_][s+1][1]:find("EQUAL") and not fullTokens[_][s-1][1]:find("COLON") then
                    var = t[2]
                end
            elseif fullTokens[_][s-1] == nil then
                if t[1]:find("COMMON") and fullTokens[_][s+1][1]:find("EQUAL") then
                    var = t[2]
                end
            end
            if var ~= nil then
                if utils.varCheck(var).Real then
                    local allowedTypes = getAllowedTypes()
                    local afterEQS = i:match("=.+"):gsub("^%=",""):chop()
                    afterEQS = afterEQS:gsub("^%s+","")
                    if afterEQS:find("['\"]") or not utils.varCheck(afterEQS).Real then
                        if utils.varCheck(var).Type == "Number" then
                        
                        else
                            if type(allowedTypes[utils.varCheck(var).Type].required) == "table" then
                                if #allowedTypes[utils.varCheck(var).Type].required == 3 then
                                    local inc = 0
                                    for _,i in pairs(allowedTypes[utils.varCheck(var).Type].required) do
                                        if type(i) ~= "number" then
                                            if not afterEQS:match(i) or afterEQS:match(i) and #afterEQS > allowedTypes[utils.varCheck(var).Type].required[3] then
                                                inc = inc + 1
                                            end
                                            if inc == #allowedTypes[utils.varCheck(var).Type].required - 1 then
                                                print("NOT A PROPER VALUE DUMMY", var, utils.varCheck(var).Type) --CHANGE TMRW
                                                os.exit()
                                            end
                                        end
                                    end
                                else
                                    local inc = 0
                                    for _,i in pairs(allowedTypes[utils.varCheck(var).Type].required) do
                                        if not afterEQS:match(i) then
                                            inc = inc + 1
                                        end
                                        if inc == #allowedTypes[utils.varCheck(var).Type].required then
                                            print("NOT A PROPER VALUE DUMMY", var, utils.varCheck(var).Type) --CHANGE TMRW
                                            os.exit()
                                        end
                                    end
                                end
                            else
                                if not afterEQS:match(allowedTypes[utils.varCheck(var).Type].required) then
                                    print("NOT A PROPER VALUE DUMMY", var, utils.varCheck(var).Type) --CHANGE TMRW
                                    os.exit()
                                end
                            end
                        end
                    else
                        if utils.varCheck(afterEQS).Type ~= utils.varCheck(var).Type and utils.varCheck(var).Type ~= "Any" then
                            error.newError("ASSIGNMENT",currentFile,_,{var, utils.varCheck(var).Type, "'"..afterEQS.."'", " |varType: "..utils.varCheck(afterEQS).Type.."| "})
                        end
                    end
                else
                    error.newError("UNKNOWN_VAR",currentFile,_,{var})
                end
            end
          end
       end
    end

    if _STACK:len() > 0 and _STACK:current()[3]:find("STATEMENT") then
      error.newError("STATEMENT_END_FUNCTION",currentFile,_STACK:current()[4],{_STACK:current()[2],"",_STACK:current()[5]})
    end
   
   table.remove(pathToFile,#pathToFile)
end

return runtime

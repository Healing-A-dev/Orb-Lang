local error = {}

function error.fetchPrevious(line,token)
    local line = tonumber(line)
    if token ~= "TOKEN" then
        if __ENDCHAR(line).Token:find("QUOTE") then
            return __ENDCHAR(line).oneBefore
        else
            return __ENDCHAR(line).Character
        end
    elseif token == "TOKEN" then
        return __ENDCHAR(line).Token
    else
        error("INCORRECT THING",9) --Honestly it should never reach here, this is just in case my stupidity gets the best of me lol
    end
end

function error.newError(type,file,line,...)
    local line = tostring(line) or nil
    local function readStack(stack,adjust)
        if adjust then adjust = -1 else adjust = 0 end
        local outStr = "\n\t\t^ "
        if stack:len() == 0 or stack:len() == 1 and adjust == -1 then
            return ""
        else
            for s = stack:len()+adjust, 1, -1 do
                i = stack[s]
                if i[3] == "STATEMENT" and i[2] == "func" then
                    if s ~= 1 then
                        outStr = outStr.."in "..i[2].."tion '"..i[5].."' \t|starting at line: "..i[4].."|\n\t\t^ "
                    else
                        outStr = outStr.."in "..i[2].."tion '"..i[5].."' \t|starting at line: "..i[4].."|"
                    end
                elseif i[3] == "STATEMENT" and i[2] ~= "func" then
                    if s ~= 1 then
                        outStr = outStr.."in "..i[2].." statment \t|starting at line: "..i[4].."|\n\t\t^ "
                    else
                        outStr = outStr.."in "..i[2].." statment \t|starting at line: "..i[4].."|"
                    end
                end
            end
        end
        return outStr
    end
    local function __EXTRAINFO(PROCESS)
        local table,PROCESS = {}, PROCESS or {}
        local MAXPROCESSLENGTH = 32
        table[0] = Stack
        for i = 1, MAXPROCESSLENGTH do
            if PROCESS[i] == "func" then
                table[#table+1] = PROCESS[i].."tion '"..PROCESS[3].."'"
            elseif PROCESS[i] == "if" or PROCESS[i] == "elif" or PROCESS[i] == "for" or PROCESS[i] == "while" or PROCESS[i] == "including" then
                table[#table+1] = PROCESS[i].." statement"
            else
                table[#table+1] = PROCESS[i] or ""
            end
        end
        return table
    end

    local types = {
        Complier = "Working on it!",
        Not_found = "Orb: <import> error\ntraceback:\n\t[orb]: file '"..__EXTRAINFO(...)[1].."' not found\n\t[file]: "..table.concat(pathToFile,"\\")..".orb\n\t[line]: "..line,
        FORMAT = "Orb: <format> error\ntraceback:\n\t[orb]: improper format typing\n\t[file]: "..table.concat(pathToFile,"\\")..".orb\n\t[line]: "..line,
        EOL = "Orb: <eol> error\ntraceback:\n\t[orb]: ';' expected near '"..error.fetchPrevious(line).."'\n\t[file]: "..table.concat(pathToFile,"\\")..".orb\n\t[line]: "..line..readStack(_STACK),
        EOL_TABLE = "Orb: <eol> error\ntraceback:\n\t[orb]: ',' expected near '"..error.fetchPrevious(line).."'\n\t[file]: "..table.concat(pathToFile,"\\")..".orb\n\t[line]: "..line..readStack(_STACK,true),
        STATEMENT_INIT = "Orb: <statement> error\ntraceback:\n\t[orb]: :{ expected to initiate "..__EXTRAINFO(...)[1].."\n\t[file]: "..table.concat(pathToFile,"\\")..".orb\n\t[line]: "..line..readStack(_STACK,true),
        STATEMENT_END_FUNCTION = "Orb: <statement> error\ntraceback:\n\t[orb]: } expected to close "..__EXTRAINFO(...)[1].." |starting at line: "..line.."|\n\t[file]: "..table.concat(pathToFile,"\\")..".orb\n\t[line]: "..line..readStack(_STACK,true),
        STATEMENT_END_TABLE = "Orb: <statement> error\ntraceback:\n\t[orb]: } expected to close "..__EXTRAINFO(...)[1].."\n\t[file]: "..table.concat(pathToFile,"\\")..".orb\n\t[line]: "..line..readStack(_STACK),
        ASSIGNMENT = "Orb: <assignment> error\ntraceback:\n\t[orb]: improper value "..__EXTRAINFO(...)[3]..__EXTRAINFO(...)[4].."assigned to variable '"..__EXTRAINFO(...)[1].."' |varType: "..__EXTRAINFO(...)[2].."|\n\t[file]: "..table.concat(pathToFile,"\\")..".orb\n\t[line]: "..line..readStack(_STACK),
        COMPARISON = "Orb: <comparison> error\ntraceback:\n\t[orb]: attempt to compare "..__EXTRAINFO(...)[2].." with "..__EXTRAINFO(...)[1].." value "..__EXTRAINFO(...)[5].."\n\t[file]: "..table.concat(pathToFile,"\\")..".orb\n\t[line]: "..line..readStack(_STACK),
        UNKNOWN_TYPE = "Orb: <type> error\ntraceback:\n\t[orb]: unknown type '"..__EXTRAINFO(...)[2].."' assigned to variable '"..__EXTRAINFO(...)[1].."'\n\t[file]: "..table.concat(pathToFile,"\\")..".orb\n\t[line]: "..line..readStack(_STACK),
        UNKNOWN_VAR = "Orb: <assignment> error\ntraceback:\n\t[orb]: attempt to assign value to unknown variable '"..__EXTRAINFO(...)[1].."'\n\t[file]: "..table.concat(pathToFile,"\\")..".orb\n\t[line]: "..line..readStack(_STACK),
        FOR_KNOWN = "Orb: <argumrnt> error\n\ttraceback:\n\t[orb]: attempt to increment "..__EXTRAINFO(...)[2].." variable '"..__EXTRAINFO(...)[1].."' |varType: "..__EXTRAINFO(...)[3].."|\n\t[file]: "..table.concat(pathToFile,"\\")..".orb\n\t[line]: "..line..readStack(_STACK)
    }
    if line == nil then
        types["Not_found"] = "Orb: error\ntraceback\n\t[orb]: missing input file"
    end
    print(types[type])
    os.exit()
end


return error
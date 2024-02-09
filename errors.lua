local error = {}


function error.fetchPrevious(line,token)
    if token ~= "Token" then
        if __ENDCHAR(line).Token:find("QUOTE") then
            return __ENDCHAR(line).oneBefore
        else
            return __ENDCHAR(line).Character
        end
    elseif token == "Token" then
        return __ENDCHAR(line).Token
    else
        error("INCCORET THING",9) --Honestly it should never reach here, this is just in case my stupidity gets the best of me lol
    end
end

function error.newError(type,file,line,...)
    local line = tostring(line) or nil

    local function __EXTRAINFO(process)
        local table,process = {}, process or {}
        local maxProcessLength = 5
        table[0] = ""
        for i = 1, maxProcessLength do
            table[#table+1] = process[i] or ""
        end
        return table
    end

    local types = {
        Complier = "Working on it!",
        Not_found = "Orb: error\ntraceback:\n\t[orb]: <"..file.."> file not found\n\t[file]: "..table.concat(pathToFile,"\\").."\n\t[line]: "..line,
        Format = "Orb: format error\ntraceback:\n\t[orb]: improper format typing\n\t[file]: "..table.concat(pathToFile,"\\").."\n\t[line]: "..line,
        EOL = "Orb: <eol> error\ntraceback:\n\t[orb]: ';' expected near '"..error.fetchPrevious(line).."'\n\t[file]: "..table.concat(pathToFile,"\\").."\n\t[line]: "..line,
        EOL_TABLE = "Orb: <eol> error\ntraceback:\n\t[orb]: ',' expected near '"..error.fetchPrevious(line).."'\n\t[file]: "..table.concat(pathToFile,"\\").."\n\t[line]: "..line,
        STATEMENT_INIT = "Orb: statement error\n\ttraceback:\n\t[orb]: :{ expected to initiate "..__EXTRAINFO(...)[0].."\n\t[file]: "..table.concat(pathToFile,"\\").."\n\t[line]: "..line,
        STATEMENT_END = "Orb: statemtent error\n\ttraceback:\n\t[orb]: } expected to close "..__EXTRAINFO(...)[0].."\n\t[file]: "..table.concat(pathToFile,"\\").."\n\t[line]: "..line,
        UNDEFINED_VAR = "Orb: definition error\n\ttraceback:\n\t[orb]: undefined variable '"..__EXTRAINFO(...)[1].."' (typing expected, got nil)\n\t[file]: "..table.concat(pathToFile,"\\").."\n\t[line]: "..line,
        ASSIGNMENT = "Orb: assignment error\n\ttraceback:\n\t[orb]: improper value assigned to variable '"..__EXTRAINFO(...)[1].."' (varType: "..__EXTRAINFO(...)[2]..")\n\t[file]: "..table.concat(pathToFile,"\\").."\n\t[line]: "..line
    }
    if line == nil then
        types["Not_found"] = "Orb: error\ntraceback\n\t[orb]: missing input file"
    end
    print(types[type])
    os.exit()
end


return error
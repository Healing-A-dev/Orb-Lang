local error = {}


function error.fetchPrevious(line,token)
    local line = tonumber(line)
    if token ~= "Token" then
        if __ENDCHAR(line).Token:find("QUOTE") then
            return __ENDCHAR(line).oneBefore
        else
            return __ENDCHAR(line).Character
        end
    elseif token == "Token" then
        return __ENDCHAR(line).Token
    else
        error("INCORRCET THING",9) --Honestly it should never reach here, this is just in case my stupidity gets the best of me lol
    end
end

function error.newError(type,file,line,...)
    local line = tostring(line) or nil

    local function __EXTRAINFO(process)
        local table,process = {}, process or {}
        local MAXPROCESSLENGTH = 32
        table[0] = ""
        for i = 1, MAXPROCESSLENGTH do
            if #process < MAXPROCESSLENGTH then
                if process[i] == "func" then
                    table[#table+1] = process[i].."tion '"..process[#process].."'"
                elseif process[i] == "if" or process[i] == "elif" or process[i] == "for" or process[i] == "while" or process[i] == "including" then
                    table[#table+1] = process[i].." statement"
                else
                    table[#table+1] = process[i] or ""
                end
            end
        end
        return table
    end

    local types = {
        Complier = "Working on it!",
        Not_found = "Orb: <import> error\ntraceback:\n\t[orb]: file '"..__EXTRAINFO(...)[1].."' not found\n\t[file]: "..table.concat(pathToFile,"\\").."\n\t[line]: "..line,
        FORMAT = "Orb: <format> error\ntraceback:\n\t[orb]: improper format typing\n\t[file]: "..table.concat(pathToFile,"\\").."\n\t[line]: "..line,
        EOL = "Orb: <eol> error\ntraceback:\n\t[orb]: ';' expected near '"..error.fetchPrevious(line).."'\n\t[file]: "..table.concat(pathToFile,"\\").."\n\t[line]: "..line,
        EOL_TABLE = "Orb: <eol> error\ntraceback:\n\t[orb]: ',' expected near '"..error.fetchPrevious(line).."'\n\t[file]: "..table.concat(pathToFile,"\\").."\n\t[line]: "..line,
        STATEMENT_INIT = "Orb: <statement> error\ntraceback:\n\t[orb]: :{ expected to initiate "..__EXTRAINFO(...)[1].."\n\t[file]: "..table.concat(pathToFile,"\\").."\n\t[line]: "..line,
        STATEMENT_END = "Orb: <statemtent> error\ntraceback:\n\t[orb]: } expected to close "..__EXTRAINFO(...)[0].."\n\t[file]: "..table.concat(pathToFile,"\\").."\n\t[line]: "..line,
        ASSIGNMENT = "Orb: <assignment> error\ntraceback:\n\t[orb]: improper value assigned to variable '"..__EXTRAINFO(...)[1].."' (varType: "..__EXTRAINFO(...)[2]..")\n\t[file]: "..table.concat(pathToFile,"\\").."\n\t[line]: "..line,
        UNKNOWN_TYPE = "Orb: <type> error\ntraceback:\n\t[orb]: unknown type '"..__EXTRAINFO(...)[2].."' assigned to variable '"..__EXTRAINFO(...)[1].."'\n\t[file]: "..table.concat(pathToFile,"\\").."\n\t[line]: "..line
    }
    if line == nil then
        types["Not_found"] = "Orb: error\ntraceback\n\t[orb]: missing input file"
    end
    print(types[type])
    os.exit()
end


return error
local error = {}

function error.fetchPrevious(line)
    local linesread = 1
    local num = 0
    while linesread <= line do
        num = num + __LINELENGTH(syntax[linesread])
        linesread = linesread + 1
    end
    return fullTokens[num]
end

function error.newError(type,file,line)
    local line = tostring(line) or nil 
    local types = {
        ["Complier"] = "Working on it!",
        ["Not_found"] = "Orb: error\ntraceback\n\t[orb]: <"..file.."> file not found\n\t[file]: "..table.concat(pathToFile,"\\").."\n\t[line]: "..line,
        ["Format"] = "Orb: format error\ntraceback\n\t[orb]: improper format typing\n\t[file]: "..table.concat(pathToFile,"\\").."\n\t[line]: "..line,
        ["EOL"] = "Orb: <eol> error\ntraceback\n\t[orb]: ';' expected near '"..error.fetchPrevious(tonumber(line))[2].."'\n\t[file]: "..table.concat(pathToFile,"\\").."\n\t[line]: "..line
    }
    if line == nil then
        types["Not_found"] = "Orb: error\ntraceback\n\t[orb]: missing input file"
    end
    print(types[type])
    os.exit()
end


return error

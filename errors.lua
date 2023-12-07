local errors = {}

function __KytenThrowError(type,file,line)
    local line = line or nil 
    local types = {
        ["Complier"] = "Working on it!",
        ["Not_found"] = "Orbit: error\ntraceback\n\t[orbit]: <"..file.."> file not found\n\t[file]: "..currentFile.."\n\t[line]: "..tostring(line)
    }
    if line == nil then
        types["Not_found"] = "Orbit: error\ntraceback\n\t[orbit]: missing input file"
    end
    print(types[type])
    os.exit()
end


return errors
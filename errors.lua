local errors = {}

__Orb = {}

function __Orb.newError(type,file,line)
    local line = line or nil 
    local types = {
        ["Complier"] = "Working on it!",
        ["Not_found"] = "Orb: error\ntraceback\n\t[orb]: <"..file.."> file not found\n\t[file]: "..currentFile.."\n\t[line]: "..tostring(line)
    }
    if line == nil then
        types["Not_found"] = "Orb: error\ntraceback\n\t[orbit]: missing input file"
    end
    print(types[type])
    os.exit()
end


return errors

Blocks = {}
local function partialBuild(name)
    Blocks[name] = {}
    Blocks[name].runFile = arg[1]..".orb"
    Blocks[name].run = function()
        local runFileLines = {}
        local blockLines = {}
        os.execute("touch "..Blocks[name].runFile)
        local File = io.open(Blocks[name].runFile,"r")
        local lines = File:lines()
        for line in lines do
            runFileLines[#runFileLines+1] = line
        end
        File:close()
        for _,i in ipairs(Blocks[name]) do
            blockLines[#blockLines+1] = i
        end
        local File = io.open(Blocks[name].runFile,"w+")
        for _,i in ipairs(blockLines) do
            File:write(i.."\n")
        end
        File:close()
        dofile(Blocks[name].runFile)
        local File = io.open(Blocks[name].runFile,"w+")
        for _,i in ipairs(runFileLines) do
            File:write(i.."\n")
        end
        File:close()
        if Blocks[name].runFile:find("%.bkf") then
            os.remove(Blocks[name].runFile)
        end
    end

    Blocks[name].build = function(ext,path)
        local path = path or ""
        local ext = ext or ".lua"
        if not ext:find("%.") and ext:find(".+") then
            path = ext
            ext = ".lua"
        elseif ext == "" then
            ext = ".lua"
        end
        if path ~= "" and not io.open(path) then
            path = path.."/"
            local toMake = ""
            for pathName in path:gmatch("%w+") do
                os.execute("mkdir "..toMake..pathName)
                toMake = toMake..pathName.."/"
            end
        end
        local toRun = {}
        for _,i in ipairs(Blocks[name]) do
            toRun[#toRun+1] = i
        end
        local BlockFile = io.open(path..name..ext,"w+")
        BlockFile:write("local "..name.." = {}\n\n"..table.concat(toRun,"\n").."\n\nreturn "..name)
        BlockFile:close()
        return path..name
    end

    Blocks[name].contents = function()
        print("Block: "..name.."\n")
        for _,i in ipairs(Blocks[name]) do
            print("    "..i)
        end
        print("____________________\nExtensions:")
        for _,i in pairs(Blocks[name]) do
            if type(i) == "table" then
                print("    ".._..":\t\t"..tostring(i))
            end
        end
        print("____________________\nFunctions:")
        for _,i in pairs(Blocks[name]) do
            if type(i) == "function" then
                print("    ".._.."\t\t"..tostring(i))
            end
        end
    end
    
    
    
end

local function Build(file)
    local FileName = file
    local File = io.open(FileName,"r")
    local lines = File:lines()
    local filelines = {}
    local fileStore = {}
    local isBlock = false
    for line in lines do
        fileStore[#fileStore+1] = line
        if line:gsub("%s+",""):match("startBlock%s?.+") then
            isBlock = true
            blockName = line:gsub("startBlock",""):gsub("[%s+%:]","")
            Blocks[blockName] = {}
            line = ""
        elseif isBlock and line:gsub("%s+",""):match("endBlock") then
            isBlock = false
            line = ""
        end
        if isBlock then
            local line = line
            if #line:gsub("%s+","") > 0 then
                Blocks[blockName][#Blocks[blockName]+1] = line
                filelines[#filelines+1] = "--"..line..""
            end
        else
            if #line:gsub("%s+","") > 0 then
                local line = line
                local splitStr = {}
                for s = 1, #line do
                    splitStr[#splitStr+1] = line:sub(s,s)
                end
                if splitStr[line:len()] ~= "," and splitStr[line:len()] ~= "{"then
                    line = line..";"
                end
                filelines[#filelines+1] = line
            end
        end
    end
    File:close()

    -- ADDING UTILITY FUNCTIONS TO ALL BLOCKS IN THE BLOCK TABLE --
    for name,i in pairs(Blocks) do
        if type(i) == "table" then
            Blocks[name].run = function()
                local toRun = {}
                for _,i in ipairs(Blocks[name]) do
                    local splitStr = {}
                    for s = 1, #i do
                        splitStr[#splitStr+1] = i:sub(s,s)
                    end
                    if splitStr[i:len()] ~= "," and splitStr[i:len()] ~= "{" then
                        toRun[#toRun+1] = i..";"
                    else
                        toRun[#toRun+1] = i
                    end
                end
                local File = io.open(FileName,"w+")
                File:write(table.concat(toRun))
                File:close()
                dofile(FileName)
                local File = io.open(FileName,"w+")
                File:write(table.concat(fileStore,"\n"))
                File:close()
            end

            Blocks[name].build = function(ext,path)
                local path = path or ""
                local ext = ext or ".lua"
                if not ext:find("%.") and ext:find(".+") then
                    path = ext
                    ext = ".lua"
                elseif ext == "" then
                    ext = ".lua"
                end
                if path ~= "" and not io.open(path) then
                    path = path.."/"
                    local toMake = ""
                    for pathName in path:gmatch("%w+") do
                        os.execute("mkdir "..toMake..pathName)
                        toMake = toMake..pathName.."/"
                    end
                end
                local toRun = {}
                for _,i in ipairs(Blocks[name]) do
                    toRun[#toRun+1] = i
                end
                local BlockFile = io.open(path..name..ext,"w+")
                BlockFile:write("local "..name.." = {}\n\n"..table.concat(toRun,"\n").."\n\nreturn "..name)
                BlockFile:close()
                return path..name
            end

            Blocks[name].contents = function()
                print("Block: "..name.."\n")
                for _,i in ipairs(Blocks[name]) do
                    print("    "..i)
                end
                print("____________________\nExtensions:")
                for _,i in pairs(Blocks[name]) do
                    if type(i) == "table" then
                        print("    ".._..":\t\t"..tostring(i))
                    end
                end
                print("____________________\nFunctions:")
                for _,i in pairs(Blocks[name]) do
                    if type(i) == "function" then
                        print("    ".._.."\t\t"..tostring(i))
                    end
                end
            end

        end
    end
    return {
        Lines = filelines, 
        Run = function()
            local File = io.open(FileName,"w+")
            File:write(table.concat(filelines,"\n"))
            File:close()
            dofile(FileName)
            local File = io.open(FileName,"w+")
            File:write(table.concat(fileStore,"\n"))
            File:close()
        end
    }
end

-- Block Utility Functions
function Blocks.NewBlock(BlockName,extension,skip_nil_blocks)
    partialBuild(BlockName)
    local skip_nil_blocks = skip_nil_blocks or true
    -- ADDING BLOCK EXTENSIONS --
    for ext in extension.extensions:gmatch("%S+") do
        if Blocks[ext] == nil and not skip_nil_blocks then
            error("Blocks <Error>"..arg[0]..": Block '"..ext.."' does not exsit")
        elseif ext == ".VOID" and extension.extensions:gsub("%s+","") == ".VOID" then
            return
        else
            Blocks[BlockName][ext] = Blocks[ext]
        end
    end
end

function Blocks.WriteToBlock(BlockName, Data_To_Write)
    local function removeEnd(str)
        local split = {}
        local str = str:gsub("^\n","")
        for s=1, #str do
            split[#split+1] = str:sub(s,s)
        end
        return table.concat(split)
    end
    for line in Data_To_Write:gmatch(".+") do
        Blocks[BlockName][#Blocks[BlockName]+1] = removeEnd(line)
    end
end

function Blocks.ShowAllBlocks()
    for _,i in pairs(Blocks) do
        if type(i) == "table" then
            print("Block: ".._)
        end
    end
end

function Blocks.BuildFromFile(file,ext)
    local ext = ext or ".lua"
    local toBuild = ""
    if arg[1] == nil and file == nil then
        print("Blocks <Error>: "..arg[0]..": No file specified")
        os.exit()
    end
    if file ~= nil and file:find("%..+") then ext = "" end
    if arg[1] == nil then toBuild = file..ext else toBuild = arg[1] end
    local Blocks = Build(toBuild)
    Blocks.Run()
    return {Lines = Blocks.Lines}
end
return Blocks

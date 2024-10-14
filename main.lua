local Runtime = require("runtime")
local Blocks = require("Blocks")
local Transpiler = require("transpiler")
local variables = require("variables")
local runOrder = {}
local FILE = io.open(arg[1],"r")
if not FILE then
    print("Orb: <transpiler> error\ntraceback:\n\t[orb]: input file '"..arg[1].."' not found") 
    os.exit()
end
local lines = FILE:lines()
local INCLUDE = false

Variables = {Global = {}, Static = {},Temporary = {}}
local lineNumber = 0
for line in lines do
    lineNumber = lineNumber + 1
    if line:find("@including:{") then
        INCLUDE = true
    elseif INCLUDE and line:gsub("%s+","") == "}" then
        INCLUDE = false
    elseif INCLUDE then
        if not line:gsub("^%s+",""):match("^##") then
            local file,varName = line:match(".+:") or line:match(".+;"), line:match(":.+;"):gsub("[%s+;%:]","")
            local file = file:gsub("['\":%s+;]",""):gsub("%.","/")
            local fileOpen = io.open(file..".orb","r")
            if not fileOpen then 
                print("Orb: <import> error\ntraceback:\n\t[orb]: file '"..file.."' not found\n\t[file]: "..arg[1].."\n\t[line]: "..lineNumber) 
                os.exit()
            end
            Runtime.run(file) -- Generate File Runtime
            runOrder[#runOrder+1] = file
            Blocks.NewBlock(file,{extensions = ".VOID"})
            for _,i in pairs(Transpiler.translate()) do
                Blocks.WriteToBlock(currentFile,table.concat(i))
            end
        end
    end
end
FILE:close()

Runtime.run()
runOrder[#runOrder+1] = currentFile
Blocks.NewBlock(runOrder[#runOrder],{extensions = ".VOID"},true)
for _,i in pairs(Transpiler.translate()) do
    Blocks.WriteToBlock(currentFile,table.concat(i))
end
for _,i in ipairs(runOrder) do
    Blocks[i].run()
end

-- print("\027[94m".."No errors!!! :D".."\027[0m") --Happy messege :D
 
--[[for _,i in pairs(fullTokens) do
    for s = 1, #i do
        print(table.concat(i[s],":\t "))
    end
end]]

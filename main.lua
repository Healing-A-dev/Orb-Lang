local Runtime = require("runtime")
local Blocks = require("Blocks")
local Transpiler = require("transpiler")
local runOrder = {}

local FILE = io.open("main.orb","r")
local lines = FILE:lines()
local INCLUDE = false
for line in lines do
    if line:find("@including:{") then
        INCLUDE = true
    elseif INCLUDE and line:gsub("%s+","") == "}" then
        INCLUDE = false
    elseif INCLUDE then
        local file = line:match(".+:"):gsub("['\":%s+]",""):gsub("%.","/")
        Runtime.run(file) -- Generate File Runtime
        runOrder[#runOrder+1] = file
        Blocks.NewBlock(file,{extensions = ".VOID"})
        for _,i in pairs(Transpiler.translate()) do
            Blocks.WriteToBlock(currentFile,table.concat(i))
        end
    end
end
FILE:close()

Runtime.run()
runOrder[#runOrder+1] = currentFile
Blocks.NewBlock(runOrder[#runOrder],{extensions = ".VOID"})
for _,i in pairs(Transpiler.translate()) do
    Blocks.WriteToBlock(currentFile,table.concat(i))
end
for _,i in ipairs(runOrder) do
    Blocks[i].run()
end

--print("\027[94m".."No errors!!! :D".."\027[0m") --Happy messege :D
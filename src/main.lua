local Runtime = require("src/runtime")
local Blocks = require("src/Blocks")
local Transpiler = require("src/transpiler")
local variables = require("src/variables")
local runOrder = {}
local FILE = io.open(arg[1],"r")
if not FILE then
    print("Orb: <transpiler> error\ntraceback:\n\t[orb]: input file '"..arg[1].."' not found") 
    os.exit()
end
FILE:close()

--Variables Table global functions
Variables = {
    Global = {
        asString = {Type = "Function", Value = "", Args = {}, Return_Type = "String"},
        asNumber = {Type = "Function", Value = "", Args = {}, Return_Type = "Number"},
        asArray = {Type = "Function", Value = "", Args = {}, Return_Type = "Array"}
    },
    Static = {},
    Temporary = {}
}

Runtime.run()
runOrder[#runOrder+1] = currentFile
Blocks.NewBlock(runOrder[#runOrder],{extensions = ".VOID"},true)
for _,i in pairs(Transpiler.translate()) do
    local extraWords = Buffer[_] or {"","","","","","","","","",""}
    local toWrite = table.concat(i):gsub(extraWords[1].."%(%)",table.concat(extraWords)..";"):gsub("->.+$","")
    Blocks.WriteToBlock(currentFile,toWrite)
end
for _,i in ipairs(runOrder) do
    Blocks[i].run()
end
--Blocks["main.orb"].contents()

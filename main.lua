local errors = require("errors")
local lexer = require("lexer")
local utils = require("utils")
os.execute('clear')
currentFile = "main"
local pathToFile = {"main"}
local isString = {isString = false, stringSE = "NULL"}
lexer.lex("main")
--[[for _,i in spairs(syntax) do
  print("Line: ".._.." = {")
  for k,v in spairs(tokenTable[_]) do
    print("\tPosition: "..k.."\tToken: "..v[1].."\tPhrase: "..v[2])
  end
  print("}\n")
end]]

--print(phraseTable[4]["game"].Start,phraseTable[4]["game"].End)
--print(phraseTable[4]["gameManager"].Start,phraseTable[4]["gameManager"].End)
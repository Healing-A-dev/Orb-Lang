local errors = require("errors")
local lexer = require("lexer")
local utils = require("utils")

currentFile = "main"
local pathToFile = {"main"}
local isString = {isString = false, stringSE = nil}
lexer.lex("main")
for _,i in pairs(tokenTable) do
  for k,v in spairs(i) do
    if not isString.isString and v[1] == "KTOKEN_TYPE_DQUOTE" or not isString.isString and v[1] == "KTOKEN_TYPE_SQUOTE" then
      isString.isString = true
      isString.stringSE = v[2]
      print("String On")
    elseif isString.isString and v[2] == isString.stringSE then
      isString.isString = false
      isString.stringSE = nil
      print("String Off")
    end
    if isString.isString then
      v[1] = "KTOKEN_TYPE_STRING"
    else
      v[1] = v[1]
    end
    print("Item: "..v[2].."\nLine: ".._.."\nPosition: "..k.."\nToken: "..v[1].."\n")
  end
end
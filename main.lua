local errors = require("errors")
local lexer = require("lexer")
local utils = require("utils")

currentFile = "main"
local pathToFile = {"main"}
local isString = {isString = false, stringSE = "NULL"}
lexer.lex("main")
for _,i in spairs(syntax) do
  print("Line: ".._.." = {")
  for k,v in spairs(tokenTable[_]) do
    print(k,v[1],v[2])
  end
  print("}\n")
end

--[[for _,i in spairs(tokenTable) do
  for k,v in spairs(i) do
    if isString.isString and v[1] ~= assigned_Token[isString.stringSE] then
      v[1] = "KTOKEN_TYPE_STRING"
    else
      v[1] = v[1]
    end
    if not isString.isString and v[1] == "KTOKEN_TYPE_DQUOTE" or not isString.isString and v[1] == "KTOKEN_TYPE_SQUOTE" then
      isString.isString = true
      isString.stringSE = v[2]
    elseif isString.isString and v[2] == isString.stringSE then
      isString.isString = false
      isString.stringSE = "NULL"
    end
    io.read()
    os.execute('clear')
    print("String Token: "..assigned_Token[isString.stringSE])
    print("Item: "..v[2].."\nLine: ".._.."\nPosition: "..k.."\nToken: "..v[1].."\n\nString: "..tostring(isString.isString))
  end
end]]

--[[testStr = 'if ([typeof($words)] != "string"):{'
for _,i in pairs(testStr:position("string")) do
  print(_,i)
end]]

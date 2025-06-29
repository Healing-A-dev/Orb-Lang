local str = [[
function
main
(
)


puts
(
"Hello,
World!\n"
)

end


]]

puts = {
    contents = [[
        function
        puts
        (
        words
        )
        testing
        testing
        testing
        end
    ]]
}


-- Recurssive function call testing [Passed/Was implemented]--
local counter = 1
local Tokens = {}
function lex(data)
    Tokens[counter] = {}
    for token in data:gmatch("%S+") do
        Tokens[counter][#Tokens[counter]+1] = {token, "blank"}
    end
    for _,token in pairs(Tokens[counter]) do
        if token[1]:find("%(") and Tokens[counter][_-2][1] ~= "function" then
            if _G[Tokens[counter][_-1][1]].contents ~= nil then
                counter = counter + 1
                lex(_G[Tokens[counter-1][_-1][1]].contents)
            end
        end
    end
end

lex(str)
local concatstr = ""
for s = #Tokens, 1, -1 do
    for _,i in pairs(Tokens[s]) do
        concatstr = concatstr..i[1].." "
    end
    concatstr = concatstr.."\n\n"
end

print(concatstr)

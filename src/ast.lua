local ast = {}

ast = {}


local function evaluate(Data)
	
	return Data --For now
end

function ast.CV(data)
	local AST_DATA = {
		Tag = "CV",
		Variable_Name = data.Name,
		Classification = data.Classification,
		Value = evaluate(data.Value)
	}
	return AST_DATA
end

function ast.new(call,data)
	local _DATA = ast[call](data)
	ast[#ast+1] = _DATA
end

return ast

--[[


a := 35
b := 34

func add(x, y) {
	ret x + y
}

c := add(a, b)
puts(c)


-- AST VER --

%add 2: 
	push %1
	push %2	
%

c db add: a:, b:
call puts: c
	
]]

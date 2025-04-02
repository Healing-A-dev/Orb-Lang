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

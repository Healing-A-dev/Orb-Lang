local error = {}

-- Error Data Reader/Processor
local function __EXTRAINFO(PROCESS,SIZE)
	local table,PROCESS = {}, PROCESS or {}
    local MAXPROCESSLENGTH = SIZE or 8
	for i = 1, MAXPROCESSLENGTH do
		if PROCESS[i] == "func" then
			table[#table+1] = PROCESS[i].."tion <"..tostring(PROCESS[3])..">"
		elseif PROCESS[i] == "mod" then
			table[#table+1] = PROCESS[i].."ule <"..tostring(PROCESS[3])..">"
		elseif PROCESS[i] == "if" or PROCESS[i] == "elif" or PROCESS[i] == "for" or PROCESS[i] == "while" or PROCESS[i] == "including" then
			table[#table+1] = PROCESS[i].." statement"
		else
			table[#table+1] = PROCESS[i] or ""
		end
	end
	return table
end

-- Stack reader (reads the current stack)
local function readStack()
	local Stack = _STACK
	for s = #Stack, 1, -1 do
		local Type = Stack[s].Type:lower()
		if Type == "func" then
			Type = "function <"..Stack[s].Name..">"
		elseif Type == "mod" then
			Type = "module <"..Stack[s].Name..">"
		elseif Type == "if" or Type == "elseif" or Type == "for" or Type == "while" then
			Type = Type.." statment"
		end
		print("            ^".." in "..Type.." | "..Stack[s].Line_Created)
	end
end

-- Errors --
function error.new(type,line,...)
    local line = tostring(line) or nil
    local data = __EXTRAINFO(...)

	-- Available Errors
    local errors = {
		UNFINISHED_STRING = "Orb: <syntax> error\ntraceback\n    [orb]: unfinished string near '"..data[1].."'\n    [file]: "..arg[1].."\n    [line]: "..line,
		STATEMENT_INIT = "Orb: <syntax> error\ntraceback\n    [orb]: '{' expected near '"..data[1].."'\n    [file]: "..arg[1].."\n    [line]: "..line,
		STATEMENT_END = "Oorb: <syntax> error\ntraceback\n    [orb]: '}' expected (to close '"..data[1].."' at line "..data[2]..")\n    [file]: "..arg[1].."\n    [line]: "..line,
		UNKNOWN_VAR_CALL = "Orb: <call> error\ntraceback\n    [orb]: attempt to call unknwon variable '"..data[1].."'\n    [file]: "..arg[1].."\n    [line]: "..line,
		ARITHMETIC = "Orb: <FIXME> error\ntraceback\n    [orb]: cannot perform arithmetic operation on "..data[1]..data[2]..data[3].." '"..data[4].."'\n    [file]: "..arg[1].."\n    [line]: "..line,
		UNEXPECTED_TOKEN = "Orb: <syntax> error\ntraceback\n    [orb]: unexpected token '"..data[1].."' near '"..data[2].."'\n    [file]: "..arg[1].."\n    [line]: "..line,
		ASSIGN_TO_UNDECLARED = "Orb: <assignment> error\ntraceback\n    [orb]: cannot assign data to undeclared variable '"..data[1].."'\n    [file]: "..arg[1].."\n    [line]: "..line,
		UNKNOWN_FUNCTION_CALL = "Orb: <call> error\ntraceback\n    [orb]: attempt to call unknown function '"..data[1].."'\n    [file]: "..arg[1].."\n    [line]: "..line,
		NULL_VALUE_INDEX = "Orb: <call> error\ntraceback\n    [orb]: attempt to index null value '"..data[1].."'\n    [file]: "..arg[1].."\n    [line]: "..line,
		BAD_ARGUMENT = "Orb: <argument> error\ntraceback\n    [orb]: bad arguemnt #"..data[1].." in "..data[2].." |> "..data[4].." expected, got '"..data[5].."'\n    [file]: "..arg[1].."\n    [line]: "..line
	}

    if errors[type] ~= nil then
		-- Built-in Errors
        print(errors[type])
		readStack()
    else
		-- Custom Errors
		print("Orb: <custom> error\ntraceback:\n    [orb]: "..type.."\n    [file]: "..arg[1].."\n    [line]: "..file.Line)
    end
    print("\n\027[91mexit status <1>\027[0m")
    os.exit(1)
end


return error

local errors = {}

local function __EXTRAINFO(PROCESS,SIZE)
	local table, PROCESS = {}, PROCESS or {}
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

function errors.new(err, line, ...)
    if line ~= nil then
        line = tostring(line)
    else
        line = "???"
    end
    if not io.open(arg[1]) then
        arg[1] = "???"
    end
    local data = __EXTRAINFO(...)


    local available_errors = {
        DEFINITION_NAME = "Xohe: \027[91merror\027[0m: failure to process library header file <"..data[1]..">\n|> unnamed definition (line: "..line..")\n|> "..arg[1]..":"..file.Line,
        NO_LINKERFILE_LOCATION = "Xohe: \027[91merror\027[0m: failure to process library header file <"..data[1]..">\n|> linker file location not specified\n|> "..arg[1]..":"..file.Line,
        END_DEF_NOT_FOUND = "Xohe: \027[91merror\027[0m: failure to process library header file <"..data[1]..">\n|> definition '"..data[2].."' was not closed (line: "..line..")\n|> "..arg[1]..":"..file.Line,
        NO_ASM_OUTFILE = "Xohe \027[91merror\027[0m: failure to process library header file <"..data[1]..">\n|> assembly output file location not specidied (line: "..line..")\n|> "..arg[1]..":"..file.Line,
    }
    
    
    print(available_errors[err])
    os.exit(1)
end

function errors.warn(err, line, ...)
    if line ~= nil then
        line = tostring(line)
    else
        line = "???"
    end
    if not io.open(arg[1]) then
        arg[1] = "???"
    end
    local data = __EXTRAINFO(...)


    local available_errors = {
        DEFINITION_NAME = "Xohe: \027[93mwarning\027[0m: failure to process library header file <"..data[1]..">\n|> unnamed definition (line: "..line..")\n|> "..arg[1]..":"..file.Line,
        NO_LINKERFILE_LOCATION = "Xohe: \027[93mwaring\027[0m: failure to process library header file <"..data[1]..">\n|> linker file location not specified\n|> "..arg[1]..":"..file.Line,
        NO_LINKERFILE_LOCATION_WITH_ASM = "Xohe: \027[93mwaring\027[0m: failure to process library header file <"..data[1]..">\n|> linker file location not specified\n|> assembly file location specified <"..data[2]..">\n|> compiling new linker object file <"..data[3]..">",
        END_DEF_NOT_FOUND = "Xohe: \027[93mwarning\027[0m: failure to process library header file <"..data[1]..">\n|> definition '"..data[2].."' was not closed (line: "..line..")\n|> "..arg[1]..":"..file.Line,
    }
    
    if not COMPILER.FLAGS.EXECUTE or COMPILER.FLAGS.WARN then
        print(available_errors[err].."\n")
    end
end


return errors

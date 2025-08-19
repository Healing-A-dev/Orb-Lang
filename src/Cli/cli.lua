local cli = {}

-- Imports --
local FileBuilder = require("src/Cli/cli_file_builder")

-- Instance Variables --
cli.Stack = {}
local asm = {  -- Local ASM compiler table to reset global ASM compiler table after each compilation (same as src/Xohe/compiler.lua)
    HEADER = [[
    .section .bss
read_buffer:
    .skip 128

    ]],
    DATA = [[
.section .data
int_buffer:
    .fill 32, 1, 0

]],
    TEXT = [[
    .section .text
    .global _start
_start:
]],
    FUNC = [[
Orb_CFUNCTION_puts:
    mov $1, %rax
    mov $1, %rdi
    syscall
    ret

Orb_CFUNCTION_exit:
    mov $60, %rax
    syscall
    ret

Orb_CFUNCTION_puts_INT:
    mov %rax, %rdi
    mov $int_buffer + 32, %rsi
    mov $10, %rcx

.displayInt:
    xor %rdx, %rdx
    div %rcx
    add $'0', %dl
    dec %rsi
    mov %dl, (%rsi)
    test %rax, %rax
    jnz .displayInt

    mov $int_buffer + 32, %rdx
    sub %rsi, %rdx
    mov %rsi, %rsi
    callq "Orb_CFUNCTION_puts"
    ret

    ]]
}

cli.help_message = [[
Commands:
    !exit          |> Exits the interactive compiler and removes all created files
    !reset         |> Resets all stored data in the interactive compiler
    !clear         |> Clears the terminal
    !/<file_name>  |> Runs compiles and runs the given file
    ?commands      |> Displays this message
    ?version       |> Displays the current Orb version
]]

-- Code --
function cli.interactive(XOHE, file_name)
    -- Instance Variables
    local fname = FileBuilder.New(file_name) -- Creating file for interactive compilation
    local write_char = ": "

    -- Allowing passthough on error
    ERR_PASS_THROUGH = true

    -- Displaying OIC(Orb Interactive Compiler) Message
    print([[
        .    |]].."  \027[36mOrb Interactive Compiler (OIC):\027[0m\n"..[[
 /~\._|_     |]].."  \027[96mLicense: MIT 2025 (c) Healing\027[0m\n"..[[
.\_/| |_)    |]].."  \027[96mVersion: " .. XOHE.VERSION .. "\027[0m"..[[

_____________|______________________________________________
Type "?commands" for more information
]])

    while true do
        -- Writing write_char
        io.write(write_char)

        -- Instance Variables --
        local skip_push = true
        local data = io.read()
        local data_ending = data:gsub("%s+$", ""):match(".$") or ""

        -- CLI Stack Data Handling
        if data_ending:match("[%{%[]") then
            cli.Stack[#cli.Stack + 1] = data_ending
        end
        if data_ending:match("[%}%]]") then
            if cli.Stack[#cli.Stack] == "{" and data_ending:match("[%}%]]") == "}" or cli.Stack[#cli.Stack] == "[" and data_ending:match("[%}%]]") == "]" then
                table.remove(cli.Stack, #cli.Stack)
            end
        end

        -- Editing write_char
        if #cli.Stack > 0 then
            write_char = "    "
        else
            write_char = ": "
        end

        -- Command Handling
        local cmd_tag = data:match("^.")
        local cmd = data:match("[^%?^%!]+")

        if cmd_tag ~= nil and not cmd_tag:find("%w") then
            if cmd_tag == "!" then
                if cmd == "exit" then
                    -- Removing created files
                    COMPILER.CREATED_FILES[#COMPILER.CREATED_FILES+1] = fname
                    for s = 1, #COMPILER.CREATED_FILES do
                        os.remove(COMPILER.CREATED_FILES[s])
                    end

                    -- Exiting
                    os.exit()
                elseif cmd:match("%/%S+") then

                    -- Running an orb file
                    FileBuilder.CLEAR()
                    local file = cmd:gsub("^%/","")
                    FileBuilder.PushToXohe(file)
                    FileBuilder.CLEAR()
                elseif cmd == "reset" then

                    -- Clearing stored data
                    FileBuilder.CLEAR()
                    print("Stored data reset!")
                elseif cmd == "clear" then

                    -- Clearing command line
                    os.execute("clear")
                else
                    print("'"..cmd.."' is not a valid command!")
                end
            elseif cmd_tag == "?" then
                if cmd == "commands" then
                    -- Display help message
                    print(cli.help_message)
                elseif cmd == "version" then
                    -- Display current version
                    print("[version]: "..XOHE.VERSION)
                else
                    print("'"..cmd.."' is not a valid command!")
                end
            else
                print("'"..cmd_tag.."' is not a valid command tag!")
            end
        else
            FileBuilder.APPEND_TEMP(data)
            skip_push = false
        end

        -- Pushing command and resetting compiler tables
        if #cli.Stack == 0 and not skip_push or data == ".exec" and not skip_push then
            FileBuilder.PushToXohe()
            ASM.HEADER = asm.HEADER
            ASM.DATA = asm.DATA
            ASM.TEXT = asm.TEXT
            ASM.FUNC = asm.FUNC
        end
    end
end

return cli

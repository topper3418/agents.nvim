local M = {}

M.commands = {}

function M.register_command(cmd, fn, desc)
	M.commands[cmd] = {
		fn = fn,
		desc = desc,
	}
end

local default_commands = {
	require("agents.commands.new_session"),
	require("agents.commands.tool_results"),
}

for _, cmd in ipairs(default_commands) do
	M.register_command(cmd.command, cmd.fn, cmd.desc)
end

function M.handle_command(user_msg, buf, chat_object)
	local command = user_msg:sub(2):lower()
	local cmd = vim.split(command, "%s+")[1] -- isolate the command part
	if cmd == "help" then
		local help_text = {
			"# agents.nvim Commands",
			"",
			"- `/help`: Show this help message",
		}
		for cmd_name, cmd_info in pairs(M.commands) do
			table.insert(help_text, string.format("- `/%s`: %s", cmd_name, cmd_info.desc or "No description"))
		end
		return help_text
	elseif M.commands[cmd] then
		return M.commands[cmd].fn(user_msg, buf, chat_object)
	else
		return { "Unknown command: " .. cmd }
	end
end

return M

local M = {}

function M.get_system_prompt()
	local script_path = debug.getinfo(1, "S").source:sub(2)
	local plugin_root = vim.fn.fnamemodify(script_path, ":h") -- go up from chat.lua → agents → lua → root
	local prompt_path = plugin_root .. "/prompts/system.txt"

	local file = io.open(prompt_path, "r")
	if not file then
		vim.notify("agents.nvim: Could not read system prompt from " .. prompt_path, vim.log.levels.ERROR)
		return "You are a helpful coding assistant."
	end

	local content = file:read("*a")
	file:close()
	return vim.trim(content)
end

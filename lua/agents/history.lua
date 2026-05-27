-- lua/agents/history.lua
-- handles the conversation history

local M = {}

local function load_from_file()
	-- Get current working directory (where Neovim was opened)
	local cwd = vim.fn.getcwd()
	local file_path = cwd .. "/.nvim/agents/history.json"

	-- Check if the file exists
	if vim.fn.filereadable(file_path) == 0 then
		vim.notify("No history file found at " .. file_path, vim.log.levels.INFO)
		return {}
	end

	-- Read the file content
	local ok, content = pcall(vim.fn.readfile, file_path)
	if not ok then
		vim.notify("Failed to read history file: " .. content, vim.log.levels.ERROR)
		return {}
	end

	-- Decode JSON content
	local json_ok, history = pcall(vim.json.decode, table.concat(content))
	if not json_ok then
		vim.notify("Failed to decode JSON: " .. history, vim.log.levels.ERROR)
		return {}
	end

	return history
end

local function get_system_prompt()
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

M.history = load_from_file()

local function save_history()
	-- Get current working directory (where Neovim was opened)
	local cwd = vim.fn.getcwd()
	local dir_path = cwd .. "/.nvim/agents"
	local file_path = dir_path .. "/history.json"

	-- Ensure the directory exists (recursive)
	local ok, err = pcall(vim.fn.mkdir, dir_path, "p")
	if not ok then
		vim.notify("Failed to create directory: " .. err, vim.log.levels.ERROR)
		return false
	end

	-- Convert Lua table to JSON
	local json_ok, json_str = pcall(vim.json.encode, M.history)
	if not json_ok then
		vim.notify("Failed to encode JSON: " .. json_str, vim.log.levels.ERROR)
		return false
	end

	-- Write to file (using vim.fn.writefile for simplicity)
	local write_ok, write_err = pcall(vim.fn.writefile, { json_str }, file_path, "b")
	if not write_ok then
		vim.notify("Failed to write history file: " .. write_err, vim.log.levels.ERROR)
		return false
	end

	vim.notify("History saved to " .. file_path, vim.log.levels.INFO)
	return true
end

function M.add_system_prompt()
	if not M.system_prompt_added then
		table.insert(M.history, 1, {
			role = "system",
			content = get_system_prompt(),
		})
		M.system_prompt_added = true
		save_history() -- Save history after adding the system prompt
	end
end

function M.add_message(message)
	M.add_system_prompt() -- Ensure system prompt is added before any messages
	table.insert(M.history, message)
	save_history() -- Save history after adding a new message
end

return M

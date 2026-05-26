-- lua/agents/chat.lua
-- Handles opening the chat window (float or split)

local M = {}

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

-- Opens a new chat buffer in the configured style
function M.open(config)
	-- local config = require("agents").config
	config = config or { style = "split", position = "right" }

	-- Reuse existing chat buffer if it already exists
	local buf = vim.fn.bufnr("agents-chat")
	if buf == -1 then
		buf = vim.api.nvim_create_buf(false, true)
		vim.api.nvim_buf_set_name(buf, "agents-chat")
		vim.api.nvim_buf_set_option(buf, "filetype", "markdown")
		vim.api.nvim_buf_set_option(buf, "buftype", "nofile")
		vim.api.nvim_buf_set_option(buf, "buftype", "prompt")
	end

	M.history = M.history or {}

	if not M.system_prompt_added then
		table.insert(M.history, 1, {
			role = "system",
			content = get_system_prompt(),
		})
		M.system_prompt_added = true
	end

	-- Open the window
	if config.style == "float" then
		local width = math.floor(vim.o.columns * config.width)
		local height = math.floor(vim.o.lines * config.height)
		vim.api.nvim_open_win(buf, true, {
			relative = "editor",
			width = width,
			height = height,
			col = math.floor((vim.o.columns - width) / 2),
			row = math.floor((vim.o.lines - height) / 2),
			border = "rounded",
			style = "minimal",
		})
	else
		local cmd = config.position == "above" and "topleft" or "botright"
		if config.position == "left" or config.position == "right" then
			cmd = "vertical " .. cmd
		end
		vim.cmd(cmd .. " split")
		vim.api.nvim_win_set_buf(0, buf)
	end

	-- Render current history + chat cursor
	M.render(buf)

	-- Debug: show available tools in a notification
	local tool_names = vim.tbl_keys(require("agents.tools").available_tools)
	-- vim.notify("🛠️  Loaded tools: " .. table.concat(tool_names, ", "), vim.log.levels.INFO)

	-- Set up buffer-local keymaps and protections
	M.setup_buffer_keymaps(buf)
end

-- Render history + chat cursor into the buffer
function M.render(buf)
	local lines = { "# agents.nvim Chat — chatting with Grok (xAI)", "" }

	-- Add previous messages
	for _, msg in ipairs(M.history or {}) do
		require("agents.rendering").msg.render(lines, msg, M.show_tool_results)
	end
	table.insert(lines, "")

	vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
	vim.api.nvim_buf_set_option(buf, "modifiable", true)

	-- Move cursor to the input line
	local input_line = #lines
	vim.api.nvim_win_set_cursor(0, { input_line, 2 }) -- right after the "> "
end

-- Protect the buffer and set up sending
function M.setup_buffer_keymaps(buf)
	-- Send on <CR> in NORMAL mode
	vim.keymap.set("n", "<CR>", function()
		M.send(buf)
	end, { buffer = buf, silent = true, desc = "Send message to Grok" })

	-- Send on <CR> in INSERT mode
	vim.keymap.set("i", "<CR>", function()
		vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "n", false)
		vim.schedule(function()
			M.send(buf)
		end)
	end, { buffer = buf, silent = true, desc = "Send message to Grok" })

	-- Protection: only enforce when trying to INSERT above the input line
	vim.api.nvim_create_autocmd("InsertEnter", {
		buffer = buf,
		callback = function()
			local cursor = vim.api.nvim_win_get_cursor(0)
			local total_lines = vim.api.nvim_buf_line_count(buf)

			if cursor[1] < total_lines or (cursor[1] == total_lines and cursor[2] < 2) then
				-- Jump to input line and stay in insert mode
				vim.api.nvim_win_set_cursor(0, { total_lines, 2 })
				-- No need to call startinsert again — we're already entering Insert mode
			end
		end,
	})

	-- Quick normal-mode shortcut to jump to input and start typing
	vim.keymap.set("n", "r", function()
		local total_lines = vim.api.nvim_buf_line_count(buf)
		vim.api.nvim_win_set_cursor(0, { total_lines, 2 })
		vim.cmd("startinsert")
	end, { buffer = buf, silent = true, desc = "Reply / jump to input" })

	-- Auto-enter insert mode the first time the window opens
	vim.cmd("startinsert")
end

-- Send the current input and get a reply
function M.send(buf)
	local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
	local input_line = lines[#lines]

	-- Strip the "> " prefix
	local user_msg = input_line:gsub("^>%s*", ""):gsub("^%%%s*", "")
	if user_msg == "" then
		return
	end

	-- intercept any kind of user command
	-- if it starts with /
	local is_command = user_msg:sub(1, 1) == "/"
	if is_command then
		require("agents.commands").handle_command(user_msg, buf, M)
		return
	end

	-- Initialize history if first time
	M.history = M.history or {}

	-- Add user message to history
	table.insert(M.history, { role = "user", content = user_msg })

	-- Show "thinking..." while we wait
	vim.api.nvim_buf_set_lines(buf, -1, -1, false, { "Thinking..." })
	vim.cmd("redraw")

	-- Show that we're calling the LLM
	-- vim.api.nvim_buf_set_lines(buf, -1, -1, false, { "Thinking..." })
	vim.cmd("redraw")

	require("agents.agent_loop").loop(M, buf)

	M.render(buf)
end

return M

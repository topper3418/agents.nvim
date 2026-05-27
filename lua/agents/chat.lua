-- lua/agents/chat.lua
-- Handles opening the chat window (float or split)

local M = {}

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
		vim.api.nvim_buf_set_option(buf, "buflisted", false)
		vim.api.nvim_buf_set_option(buf, "bufhidden", "wipe")
		vim.api.nvim_buf_set_option(buf, "swapfile", false)
		vim.api.nvim_buf_set_option(buf, "modified", false)
		vim.api.nvim_buf_set_option(buf, "modifiable", false)
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

local function set_cursor_in_buf(buf, line, col)
	local wins = vim.fn.win_findbuf(buf)
	if #wins > 0 then
		vim.api.nvim_win_set_cursor(wins[1], { line, col })
	end
end

-- Render history + chat cursor into the buffer
function M.render(buf)
	-- unlock buffer for rendering
	vim.api.nvim_buf_set_option(buf, "modifiable", true)
	local lines = { "# agents.nvim Chat — chatting with Grok (xAI)", "" }

	-- Add previous messages
	for _, msg in ipairs(require("agents.history").history) do
		require("agents.rendering").msg.render(lines, msg, M.show_tool_results)
	end
	table.insert(lines, "")

	vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
	vim.api.nvim_buf_set_option(buf, "modified", false)
	vim.api.nvim_buf_set_option(buf, "modifiable", false)

	-- Move cursor to the input line
	local input_line = #lines
	set_cursor_in_buf(buf, input_line, 2)
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

	-- Smart modifiable toggle: only allow editing on the input line
	vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
		buffer = buf,
		callback = function()
			local cursor = vim.api.nvim_win_get_cursor(0)
			local total_lines = vim.api.nvim_buf_line_count(buf)

			local on_input_line = (cursor[1] == total_lines)

			vim.api.nvim_buf_set_option(buf, "modifiable", on_input_line)
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

	-- Add user message to history
	require("agents.history").add_message({
		role = "user",
		content = user_msg,
	})

	-- Show "thinking..." while we wait
	vim.api.nvim_buf_set_lines(buf, -1, -1, false, { "🤔 Thinking..." })
	vim.cmd.redraw()

	vim.schedule(function()
		require("agents.agent_loop").loop(buf, function()
			M.render(buf) -- re-render to show the new assistant message
		end)
	end)
end

return M

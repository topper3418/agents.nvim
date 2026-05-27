-- lua/agents/chat/init.lua
-- wrapper for the chat object

local M = {}

M.window = require("agents.chat.window")

-- Opens a new chat buffer in the configured style
function M.open(config)
	M.buf = M.window.acquire_buffer()

	M.window.open(config)

	-- Render current history + chat cursor
	M.render(M.buf)

	-- Set up buffer-local keymaps and protections
	M.setup_buffer_keymaps(M.buf)
end

local function set_cursor_in_buf(line, col)
	local wins = vim.fn.win_findbuf(M.buf)
	if #wins > 0 then
		vim.api.nvim_win_set_cursor(wins[1], { line, col })
	end
end

-- Render history + chat cursor into the buffer
function M.render()
	-- unlock buffer for rendering
	vim.api.nvim_buf_set_option(M.buf, "modifiable", true)
	local lines = { "# agents.nvim Chat — chatting with Grok (xAI)", "" }

	-- Add previous messages
	for _, msg in ipairs(require("agents.history").history) do
		require("agents.rendering").msg.render(lines, msg, M.show_tool_results)
	end
	table.insert(lines, "")

	vim.api.nvim_buf_set_lines(M.buf, 0, -1, false, lines)
	vim.api.nvim_buf_set_option(M.buf, "modified", false)
	vim.api.nvim_buf_set_option(M.buf, "modifiable", false)

	-- Move cursor to the input line
	local input_line = #lines
	set_cursor_in_buf(M.buf, input_line, 2)
end

-- Protect the buffer and set up sending
function M.setup_buffer_keymaps()
	-- Send on <CR> in NORMAL mode
	vim.keymap.set("n", "<CR>", function()
		M.send(M.buf)
	end, { buffer = M.buf, silent = true, desc = "Send message to Grok" })

	-- Send on <CR> in INSERT mode
	vim.keymap.set("i", "<CR>", function()
		vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "n", false)
		vim.schedule(function()
			M.send(M.buf)
		end)
	end, { buffer = M.buf, silent = true, desc = "Send message to Grok" })

	-- Smart modifiable toggle: only allow editing on the input line
	vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
		buffer = M.buf,
		callback = function()
			local cursor = vim.api.nvim_win_get_cursor(0)
			local total_lines = vim.api.nvim_buf_line_count(M.buf)

			local on_input_line = (cursor[1] == total_lines)

			vim.api.nvim_buf_set_option(M.buf, "modifiable", on_input_line)
		end,
	})

	-- Quick normal-mode shortcut to jump to input and start typing
	vim.keymap.set("n", "r", function()
		local total_lines = vim.api.nvim_buf_line_count(M.buf)
		vim.api.nvim_win_set_cursor(0, { total_lines, 2 })
		vim.cmd("startinsert")
	end, { buffer = M.buf, silent = true, desc = "Reply / jump to input" })

	-- Auto-enter insert mode the first time the window opens
	vim.cmd("startinsert")
end

-- Send the current input and get a reply
function M.send()
	local lines = vim.api.nvim_buf_get_lines(M.buf, 0, -1, false)
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
		require("agents.commands").handle_command(user_msg, M.buf, M)
		return
	end

	-- Add user message to history
	require("agents.history").add_message({
		role = "user",
		content = user_msg,
	})

	-- Show "thinking..." while we wait
	vim.api.nvim_buf_set_lines(M.buf, -1, -1, false, { "🤔 Thinking..." })
	vim.cmd.redraw()

	vim.schedule(function()
		require("agents.agent_loop").loop(M.buf, function()
			M.render(M.buf) -- re-render to show the new assistant message
		end)
	end)
end

return M

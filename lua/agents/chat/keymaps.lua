-- lua/agents/chat/keymaps.lua
-- sets the keymaps for the chat buffer

local M = {}

function M.set(buf, send_callback)
	-- Send on <CR> in INSERT mode
	vim.keymap.set("i", "<CR>", function()
		vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "n", false)
		vim.schedule(function()
			send_callback(buf)
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

	-- TODO: make this actually work
	-- Quick normal-mode shortcut to jump to input and start typing
	vim.keymap.set("n", "r", function()
		local total_lines = vim.api.nvim_buf_line_count(buf)
		vim.api.nvim_win_set_cursor(0, { total_lines, 2 })
		vim.cmd("startinsert")
	end, { buffer = buf, silent = true, desc = "Reply / jump to input" })

	-- Auto-enter insert mode the first time the window opens
	vim.cmd("startinsert")
end

return M

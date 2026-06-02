-- lua/agents/chat/keymaps.lua
-- sets the keymaps for the chat buffer

local M = {}

function M.set(buf, send_callback)
	if vim.b[buf].agents_keymaps_set then
		return
	end
	vim.b[buf].agents_keymaps_set = true
	-- Send on <CR> in NORMAL mode
	vim.keymap.set("n", "<CR>", function()
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
			local input_line = require("agents.properties").input_line or 1

			-- If the cursor is above the input line, make the buffer unmodifiable to prevent edits.
			vim.api.nvim_buf_set_option(buf, "modifiable", true) --cursor[1] >= input_line)

			if vim.fn.mode():match("i") then
				-- Insert mode: force cursor back instead of toggling modifiable
				if cursor[1] < input_line or (cursor[1] == input_line and cursor[2] < 2) then
					vim.api.nvim_win_set_cursor(0, { input_line, 2 })
				end
			end
		end,
	})

	-- User can still hold the delete button and delete all the way up,
	-- so guard against that too
	vim.api.nvim_create_autocmd("TextChangedI", {
		buffer = buf,
		callback = function()
			local input_line = require("agents.properties").input_line or 1
			local line = vim.api.nvim_buf_get_lines(buf, input_line - 1, input_line, false)[1] or ""
			if not line:match("^> ") then
				-- restore prompt without moving the cursor
				vim.api.nvim_buf_set_lines(buf, input_line - 1, input_line, false, { "> " .. line:gsub("^> ?", "") })
			end
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

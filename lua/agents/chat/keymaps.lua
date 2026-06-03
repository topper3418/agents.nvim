-- lua/agents/chat/keymaps.lua
-- sets the keymaps for the chat buffer

local M = {}

function M.set(buf, send_callback)
	-- Guard against multiple calls to set() for the same buffer, which can happen if the user opens/closes the window multiple times.
	if vim.b[buf].agents_keymaps_set then
		return
	end
	vim.b[buf].agents_keymaps_set = true

	-- helper to send the buffer content to the callback on the main loop
	local function submit_buffer()
		vim.schedule(function()
			send_callback(buf)
		end)
	end

	-- Submit on write
	vim.api.nvim_create_autocmd("BufWriteCmd", {
		buffer = buf,
		callback = function()
			vim.bo[buf].modified = false
			submit_buffer()
		end,
	})

	-- Smart modifiable toggle: only allow editing on the input line
	vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
		buffer = buf,
		callback = function()
			local cursor = vim.api.nvim_win_get_cursor(0)
			local input_line = vim.b[buf].input_line or 1

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
			local input_line = vim.b[buf].input_line or 1
			local line = vim.api.nvim_buf_get_lines(buf, input_line - 1, input_line, false)[1] or ""
			if not line:match("^> ") then
				-- restore prompt without moving the cursor
				vim.api.nvim_buf_set_lines(buf, input_line - 1, input_line, false, { "> " .. line:gsub("^> ?", "") })
			end
		end,
	})

	local function focus_input_then(keys)
		local input_line = vim.b[buf].input_line or 1
		local cursor = vim.api.nvim_win_get_cursor(0)
		if cursor[1] < input_line then
			vim.api.nvim_win_set_cursor(0, { input_line, 2 })
		end
		vim.api.nvim_feedkeys(keys, "n", false)
	end

	for _, key in ipairs({ "i", "I", "a", "A", "o", "O", "c", "C", "s", "S" }) do
		vim.keymap.set("n", key, function()
			focus_input_then(key)
		end, { buffer = buf, silent = true })
	end

	-- Auto-enter insert mode the first time the window opens
	vim.cmd("startinsert")
end

return M

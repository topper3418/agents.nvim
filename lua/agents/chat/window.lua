-- lua/agents/chat/window.lua
-- Author: travisopperud
-- Description: handles the window-related responsibilites of the chat window

local Window = {}

function Window.acquire_buffer()
	-- Reuse existing chat buffer if it already exists
	Window.buf = vim.fn.bufnr("agents-chat")
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
	return Window.buf
end

function Window.open(config)
	-- local config = require("agents").config
	config = config or { style = "split", position = "right" }

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
		vim.api.nvim_win_set_buf(0, Window.buf)
	end
end

return Window

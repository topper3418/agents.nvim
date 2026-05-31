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
	require("agents.chat.render").render(M.buf, set_cursor_in_buf)
end

-- Protect the buffer and set up sending
function M.setup_buffer_keymaps()
	require("agents.chat.keymaps").set(M.buf, M.send)
end

-- Send the current input and get a reply
function M.send()
	require("agents.chat.send").send(M.buf, function()
		vim.schedule(function()
			require("agents.agent_loop").loop(M.buf, function()
				M.render() -- re-render to show the new assistant message
			end)
		end)
	end)
end

return M

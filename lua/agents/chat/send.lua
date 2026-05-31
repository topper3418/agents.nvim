-- lua/agents/chat/send.lua
-- Handles the logic of a submission being triggered on the buffer

local M = {}

function M.send(buf, callback)
	local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
	local input_line = lines[#lines]

	-- Strip the "> " prefix
	local user_msg = input_line:gsub("^>%s*", ""):gsub("^%%%s*", "")
	if user_msg == "" then
		return
	end

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

	callback()
end

return M

-- lua/agents/chat/submit.lua
-- Handles the logic of a submission being triggered on the buffer

local M = {}

function M.submit(buf, callback)
	-- guard against double sends
	if vim.b[buf].is_sending then
		return
	end
	vim.b[buf].is_sending = true

	-- Get the last line of the buffer, which should be the start of user input
	local input_start = vim.b[buf].input_line or vim.api.nvim_buf_line_count(buf)
	local raw = vim.api.nvim_buf_get_lines(buf, input_start - 1, -1, false)

	-- join all lines after the prompt, stripping the leading "> " only from the first
	local user_msg = table.concat(raw, "\n"):gsub("^>%s*", ""):gsub("\n>%s*", "\n"):gsub("^%%%s*", "")
	user_msg = vim.trim(user_msg)
	if user_msg == "" then
		return
	end

	-- handle commands
	local is_command = user_msg:sub(1, 1) == "/"
	if is_command then
		local command_results = require("agents.commands").handle_command(user_msg, buf, M)
		require("agents.chat").render({
			command_output = command_results,
		})
		return
	end

	-- normal message Add user message to history
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

-- lua/agents/commands/clear_history.lua
-- clears the history, and resets the buffer

function clear(user_msg, buf, chat_object)
	require("agents.history").clear_history()
	vim.api.nvim_buf_set_lines(buf, 0, -1, false, {
		"# agents.nvim Chat — chatting with Grok (xAI)",
		"",
	})
	vim.cmd("redraw")
end

return {
	command = "clear",
	fn = clear,
}

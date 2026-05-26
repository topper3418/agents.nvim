local M = {}

function M.handle_command(user_msg, buf, chat_object)
	local command = user_msg:sub(2):lower()
	local parts = vim.split(command, "%s+") -- split on whitespace
	local cmd = parts[1]
	local arg = parts[2]
	if cmd == "clear" then
		chat_object.history = nil
		vim.api.nvim_buf_set_lines(buf, 0, -1, false, {
			"# agents.nvim Chat — chatting with Grok (xAI)",
			"",
		})
		vim.cmd("redraw")
		return
	elseif cmd == "help" then
		local help_text = {
			"# agents.nvim Commands",
			"",
			"- `/clear`: Clear the chat history",
			"- `/tool-results [show|hide|toggle]`: Show or hide tool results in the chat history (default: toggle)",
			"- `/help`: Show this help message",
		}
		vim.api.nvim_buf_set_lines(buf, 0, -1, false, help_text)
		vim.cmd("redraw")
		return
	elseif cmd == "tool-results" then
		if arg == "show" then
			chat_object.show_tool_results = true
		elseif arg == "hide" then
			chat_object.show_tool_results = false
		elseif arg == "toggle" or arg == nil then
			chat_object.show_tool_results = not (chat_object.show_tool_results or false)
		else
			vim.notify("Unknown tool-results option: " .. arg, vim.log.levels.WARN)
			return
		end
		vim.cmd("redraw")
		vim.notify("tool-results: " .. (chat_object.show_tool_results and "shown" or "hidden"))

		return
	else
		vim.notify("Unknown command: " .. cmd, vim.log.levels.WARN)
		return
	end
end

return M

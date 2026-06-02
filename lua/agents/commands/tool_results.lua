-- lua/agents/commands/tool_results.lua
-- shows or hides tool results in the chat history

local function tool_results(user_msg, buf, chat_object)
	local command = user_msg:sub(2):lower()
	local parts = vim.split(command, "%s+") -- split on whitespace
	local arg = parts[2]
	local props = require("lua.agents.properties")
	if arg == "show" then
		props.show_tool_results = true
	elseif arg == "hide" then
		props.show_tool_results = false
	elseif arg == "toggle" or arg == nil then
		props.show_tool_results = not (props.show_tool_results or false)
	else
		vim.notify("Unknown tool-results option: " .. arg, vim.log.levels.WARN)
		return
	end
	vim.cmd.redraw()
	vim.notify("tool-results: " .. (props.show_tool_results and "shown" or "hidden"))
end

return {
	command = "tool-results",
	fn = tool_results,
	desc = "Show or hide tool results in the chat history. Usage: `/tool-results [show|hide|toggle]`",
}

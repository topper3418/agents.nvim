-- lua/agents/commands/clear_history.lua
-- clears the history, and resets the buffer

local function clear(_user_msg, _buf, _chat_object)
	require("lua.agents.history.init").clear_history()
	return {}
end

return {
	command = "clear",
	fn = clear,
	desc = "Clear the chat history and reset the buffer. Usage: `/clear`",
}

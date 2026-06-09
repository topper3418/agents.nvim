-- lua/agents/commands/new_session.lua
-- creates a new conversation session, and sets it as active

return {
	command = "new",
	desc = "Start a new conversation session. Usage: `/new [session name]`",
	fn = function(user_msg, _buf, _chat_object)
		-- get the new session name
		local session_name = user_msg:match("^/new%s+(.*)$")
		if not session_name then
			return { "Please provide a name for the new session. Usage: `/new [session name]`" }
		end
		local agents = require("agents")

		-- create the new session
		agents.history.sessions.new_session(session_name)
		-- redraw the buffer to show the new session
		agents.history.refresh()
		agents.chat.render()
	end,
}

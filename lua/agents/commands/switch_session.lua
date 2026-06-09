-- lua/agents/commands/switch_session.lua
-- switches to a different conversation session

return {
	command = "switch",
	desc = "Switch to a different conversation session. Usage: `/switch [session id]`",
	fn = function(user_msg, _buf, _chat_object)
		-- get the session id to switch to
		local session_id_str = user_msg:match("^/switch%s+(%d+)$")
		if not session_id_str then
			return { "Please provide a session ID to switch to. Usage: `/switch [session id]`" }
		end
		local session_id = tonumber(session_id_str)
		local agents = require("agents")
		local success, err = pcall(function()
			agents.history.sessions.set_active_session(session_id)
			agents.history.refresh()
			agents.chat.render()
		end)
		if not success then
			return { "Error switching sessions: " .. tostring(err) }
		end
	end,
}

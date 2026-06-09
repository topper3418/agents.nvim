-- lua/agents/commands/delete_session.lua
-- deletes a conversation session, and all its messages

return {
	command = "delete",
	desc = "Delete a conversation session and all its messages. Usage: `/delete [session id]`",
	fn = function(user_msg, _buf, _chat_object)
		-- get the session id to delete
		local session_id_str = user_msg:match("^/delete%s+(%d+)$")
		if not session_id_str then
			return { "Please provide a session ID to delete. Usage: `/delete [session id]`" }
		end
		local session_id = tonumber(session_id_str)
		local agents = require("agents")
		local success, err = pcall(function()
			agents.history.sessions.delete_session(session_id)
			agents.history.refresh()
			agents.chat.render()
		end)
		if not success then
			return { "Error deleting session: " .. tostring(err) }
		end
	end,
}

-- lua/agents/commands/list_sessions.lua
-- lists all conversation sessions, and their IDs, for use with the `/switch` command

return {
	command = "sessions",
	desc = "List all conversation sessions. Usage: `/sessions`",
	fn = function(_user_msg, _buf, _chat_object)
		local sessions = require("agents.history.sessions").list_sessions()
		local lines = { "Sessions:" }
		for _, session in ipairs(sessions) do
			local active_marker = session.is_active and "*" or " "
			table.insert(
				lines,
				string.format(
					"%s [%d] %s (created at %s)",
					active_marker,
					session.session_id,
					session.name,
					session.created_at
				)
			)
		end
		return lines
	end,
}

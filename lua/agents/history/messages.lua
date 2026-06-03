-- lua/agents/history/message.lua
-- Handles storing and retrieving individual messages within conversation sessions

local M = {}

local db = require("agents.history.db")

function M.add_message(message)
	local sessions = require("agents.history.sessions")
	local active_session = sessions.get_active_session()
	if not active_session then
		error("No active session found. Cannot add message.")
	end

	local tool_calls_json = nil
	if message.tool_calls then
		tool_calls_json = vim.json.encode(message.tool_calls)
	end

	local message_id = db.insert(
		[[
		INSERT INTO messages (session_id, role, content, tool_calls)
		VALUES (?, ?, ?, ?)
	]],
		{ active_session.session_id, message.role, message.content or "", tool_calls_json }
	)
	return message_id
end

function M.get_messages_for_session(session_id)
	local rows = db.query(
		[[
		SELECT message_id, role, content, tool_calls, created_at
		FROM messages
		WHERE session_id = ?
		ORDER BY created_at ASC
	]],
		{ session_id }
	)

	local messages = {}
	for _, row in ipairs(rows) do
		local tool_calls = nil
		if row[4] then
			local success, decoded = pcall(vim.json.decode, row[4])
			if success then
				tool_calls = decoded
			else
				vim.notify("Failed to decode tool_calls JSON for message_id " .. row[1], vim.log.levels.WARN)
			end
		end

		table.insert(messages, {
			message_id = tonumber(row[1]),
			role = row[2],
			content = row[3],
			tool_calls = tool_calls,
			created_at = row[5],
		})
	end

	return messages
end

return M

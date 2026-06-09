-- lua/agents/history/message.lua
-- Handles storing and retrieving individual messages within conversation sessions

local M = {}

local db = require("agents.history.db")

function M.add_message(message)
	-- ensure session
	local sessions = require("agents.history.sessions")
	local active_session = sessions.get_active_session()
	if not active_session then
		error("No active session found. Cannot add message.")
	end
	-- Encode tool_calls as JSON if present
	local tool_calls_json = nil
	if message.tool_calls then
		tool_calls_json = vim.json.encode(message.tool_calls)
	end
	print("session: " .. tostring(active_session))
	-- db insert
	local message_id = db.insert(
		[[
		INSERT INTO messages (session_id, role, content, tool_calls, tool_call_id, tool_name)
VALUES (?, ?, ?, ?, ?, ?)
	]],
		{
			active_session.session_id,
			message.role,
			message.content,
			tool_calls_json,
			message.tool_call_id,
			message.tool_name,
		}
	)
	require("agents.history").refresh() -- refresh cache after insert
	return message_id
end

function M.get_messages_for_session(session_id)
	local rows = db.query(
		[[
		SELECT id, role, content, tool_calls, tool_call_id, tool_name, created_at
		FROM messages
		WHERE session_id = ?
		ORDER BY created_at ASC
	]],
		{ session_id }
	)

	local messages = {}
	for _, row in ipairs(rows) do
		local tool_calls = nil
		local tc = row.tool_calls
		if type(tc) == "string" and tc ~= "" and tc ~= "NULL" then
			local success, decoded = pcall(vim.json.decode, tc)
			if success then
				tool_calls = decoded
			else
				vim.notify("Failed to decode tool_calls JSON for message_id " .. row.id, vim.log.levels.WARN)
			end
		end

		table.insert(messages, {
			id = tonumber(row.id),
			role = row.role,
			content = row.content,
			tool_calls = tool_calls,
			tool_call_id = row.tool_call_id,
			tool_name = row.tool_name,
			created_at = row.created_at,
		})
	end

	return messages
end

return M

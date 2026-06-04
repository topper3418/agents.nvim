-- lua/agents/history/sessions.lua
-- Manages conversation sessions, allowing for multiple threads of interaction with the assistant

local M = {}

local db = require("agents.history.db")

function M.list_sessions()
	local rows = db.query("SELECT session_id, name, created_at, is_active FROM sessions")
	local sessions = {}
	for _, row in ipairs(rows) do
		table.insert(sessions, {
			session_id = tonumber(row[1]),
			name = row[2],
			created_at = row[3],
			is_active = row[4] == "1",
		})
	end
	return sessions
end

function M.get_session(session_id)
	local rows =
		db.query("SELECT session_id, name, created_at, is_active FROM sessions WHERE session_id = ?", { session_id })
	if not rows or #rows == 0 then
		return nil
	end
	local row = rows[1]
	return {
		session_id = tonumber(row[1]),
		name = row[2],
		created_at = row[3],
		is_active = row[4] == "1",
	}
end

function M.get_active_session()
	local rows = db.query("SELECT session_id, name, created_at FROM sessions WHERE is_active = 1 LIMIT 1")
	if not rows or #rows == 0 then
		return nil
	end
	local row = rows[1]
	return {
		session_id = tonumber(row[1]),
		name = row[2],
		created_at = row[3],
	}
end

function M.set_active_session(session_id)
	-- ensure the session exists
	local session = M.get_session(session_id)
	if not session then
		error("Session ID " .. session_id .. " does not exist")
	end
	-- Deactivate all sessions
	db.exec("UPDATE sessions SET is_active = 0")
	-- Activate the selected session
	db.exec("UPDATE sessions SET is_active = 1 WHERE session_id = ?", { session_id })
end

function M.new_session(name)
	local new_session_id = db.insert("INSERT INTO sessions (name, is_active) VALUES (?, 0)", { name })
	M.set_active_session(new_session_id)
	return new_session_id
end

function M.delete_session(session_id)
	-- ensure the session exists
	local session = db.query("SELECT session_id FROM sessions WHERE session_id = ?", { session_id })
	if not session or #session == 0 then
		error("Session ID " .. session_id .. " does not exist")
	end
	-- Delete messages and tool calls associated with this session
	db.exec(
		[[
		DELETE FROM tool_calls WHERE message_id IN (
			SELECT message_id FROM messages WHERE session_id = ?
		)
	]],
		{ session_id }
	)
	db.exec("DELETE FROM messages WHERE session_id = ?", { session_id })
	db.exec("DELETE FROM sessions WHERE session_id = ?", { session_id })
end

function M.rename_session(session_id, new_name)
	-- ensure the session exists
	local session = db.query("SELECT session_id FROM sessions WHERE session_id = ?", { session_id })
	if not session or #session == 0 then
		error("Session ID " .. session_id .. " does not exist")
	end
	db.exec("UPDATE sessions SET name = ? WHERE session_id = ?", { new_name, session_id })
end

return M

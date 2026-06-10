local M = {}

local db = require("agents.history.db")

function M.init_db()
	-- Sessions table
	db.exec([[
    CREATE TABLE IF NOT EXISTS sessions (
      session_id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
      is_active BOOLEAN DEFAULT 0
    )
  ]])

	-- Messages table (tool_calls stored as JSON blob for flexibility)
	db.exec([[
    CREATE TABLE IF NOT EXISTS messages (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      session_id INTEGER NOT NULL,
      role TEXT NOT NULL,
      content TEXT,
      tool_calls TEXT,  -- JSON encoded
      tool_call_id TEXT, -- If this is a tool call message
      tool_name TEXT, -- If this is a tool call message
      created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
      FOREIGN KEY(session_id) REFERENCES sessions(session_id)
    )
  ]])

	-- Ensure at least one active session exists
	local sessions = require("agents.history.sessions")
	local active = sessions.get_active_session()
	if not active then
		sessions.new_session("Default")

		-- Add initial system prompt
		require("agents.history.messages").add_system_prompt()
	end
end

return M

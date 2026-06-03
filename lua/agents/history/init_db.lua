local M = {}

local db = require("agents.history.db")

function M.init_db()
	-- Sessions table
	db.execute([[
    CREATE TABLE IF NOT EXISTS sessions (
      session_id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
      is_active BOOLEAN DEFAULT 0
    )
  ]])

	-- Messages table (tool_calls stored as JSON blob for flexibility)
	db.execute([[
    CREATE TABLE IF NOT EXISTS messages (
      message_id INTEGER PRIMARY KEY AUTOINCREMENT,
      session_id INTEGER NOT NULL,
      role TEXT NOT NULL,
      content TEXT,
      tool_calls TEXT,  -- JSON encoded
      created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
      FOREIGN KEY(session_id) REFERENCES sessions(session_id)
    )
  ]])

	-- Tool calls table
	db.execute([[
    CREATE TABLE IF NOT EXISTS tool_calls (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      message_id INTEGER NOT NULL,
      tool_name TEXT NOT NULL,
      tool_call_id TEXT NOT NULL,
      results TEXT,  -- JSON encoded
      created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
      FOREIGN KEY(message_id) REFERENCES messages(message_id)
    )
  ]])

	-- Ensure at least one active session exists
	local active = db.eval("SELECT session_id FROM sessions WHERE is_active = 1 LIMIT 1")
	if not active or #active == 0 then
		db.execute([[
      INSERT INTO sessions (name, is_active)
      VALUES ('default', 1)
    ]])
		local session_row = db.eval("SELECT session_id FROM sessions WHERE is_active = 1 LIMIT 1")
		local sid = session_row[1].session_id

		-- Add initial system prompt
		db.execute(
			[[
      INSERT INTO messages (session_id, role, content)
      VALUES (?, 'system', 'You are a helpful coding assistant inside Neovim.')
    ]],
			{ sid }
		)
	end
end

return M

-- lua/agents/history.lua
-- handles the conversation history

local M = {}

M.init_db = require("agents.history.init_db").init_db

M.system_prompt = require("agents.history.system_prompt").get_system_prompt()

M.sessions = require("agents.history.sessions")

M.messages = require("agents.history.messages")

M.chat_history = {}

M.active_session = nil

function M.refresh()
	M.init_db()
	M.active_session = M.sessions.get_active_session()
	M.chat_history = M.messages.get_messages_for_session(M.active_session.session_id)
end

return M

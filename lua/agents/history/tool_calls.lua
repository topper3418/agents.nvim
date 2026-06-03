-- lua/agents/history/tool_calls.lua
-- Handles storing and retrieving tool call information associated with messages in conversation sessions

local M = {}

local db = require("agents.history.db")

function M.get_tool_calls_for_message(message_id)
	local rows = db.query(
		[[
		SELECT id, tool_name, tool_call_id, results, created_at
		FROM tool_calls
		WHERE message_id = ?
		ORDER BY created_at ASC
	]],
		{ message_id }
	)

	local tool_calls = {}
	for _, row in ipairs(rows) do
		local results = nil
		if row[4] then
			local success, decoded = pcall(vim.json.decode, row[4])
			if success then
				results = decoded
			else
				vim.notify("Failed to decode results JSON for tool_call id " .. row[1], vim.log.levels.WARN)
			end
		end

		table.insert(tool_calls, {
			id = tonumber(row[1]),
			tool_name = row[2],
			tool_call_id = row[3],
			results = results,
			created_at = row[5],
		})
	end

	return tool_calls
end

function M.add_tool_call(message_id, tool_name, tool_call_id, results)
	local results_json = nil
	if results then
		results_json = vim.json.encode(results)
	end

	db.execute(
		[[
		INSERT INTO tool_calls (message_id, tool_name, tool_call_id, results)
		VALUES (?, ?, ?, ?)
	]],
		{ message_id, tool_name, tool_call_id, results_json }
	)
end

return M

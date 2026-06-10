-- lua/agents/rendering/messages.lua
-- responsible for rendering chat messages from the history

M = {}

function M.user(buf_lines, msg)
	table.insert(buf_lines, "**You:**")
	for _, line in ipairs(vim.split(msg.content, "\n")) do
		table.insert(buf_lines, line)
	end
end

function M.assistant(buf_lines, msg)
	table.insert(buf_lines, "**Grok:**")
	for _, line in ipairs(vim.split(msg.content, "\n")) do
		table.insert(buf_lines, line)
	end
end

local history = require("agents.history")

function M.tool(buf_lines, msg)
	local tool_call = history.messages.get_tool_call(msg.tool_call_id) or {}
	local args = vim.json.decode((tool_call["function"] or {}).arguments or "{}") or {}
	local name = msg.tool_name or "unknown"
	-- short message if tool results are hidden
	if not require("agents.properties").show_tool_results then
		local result_len = #tostring(msg.content)
		table.insert(
			buf_lines,
			"*Tool Result:* " .. name .. "(" .. (args and #args or "") .. ") => " .. result_len .. " chars"
		)
		return
	end
	table.insert(buf_lines, "**Tool Result:**")
	local ok, decoded = pcall(vim.json.decode, msg.content)
	-- show the tool that was called
	table.insert(buf_lines, "*Tool:* " .. name)
	-- show the args given
	table.insert(buf_lines, "*Args:*")
	for key, value in pairs(args) do
		table.insert(buf_lines, tostring(key) .. ": " .. value)
	end
	-- show the results
	table.insert(buf_lines, "*Results:*")
	if ok and type(decoded) == "table" then
		if decoded.content then
			-- read_file style result
			table.insert(buf_lines, "```")
			for _, line in ipairs(vim.split(decoded.content, "\n")) do
				table.insert(buf_lines, line)
			end
			table.insert(buf_lines, "```")
		else
			-- Generic table result
			local pretty = vim.inspect(decoded)
			for _, line in ipairs(vim.split(pretty, "\n")) do
				table.insert(buf_lines, line)
			end
		end
	else
		-- Fallback to raw content
		for _, line in ipairs(vim.split(msg.content, "\n")) do
			table.insert(buf_lines, line)
		end
	end
end

function M.render(buf_lines, msg, opts)
	if msg.role == "user" then
		M.user(buf_lines, msg)
	elseif msg.role == "assistant" then
		M.assistant(buf_lines, msg)
	elseif msg.role == "tool" then
		M.tool(buf_lines, msg)
	end
	-- add a dividing two spaces and a dividng line after each message
	table.insert(buf_lines, "")
	table.insert(buf_lines, "-------------------------------------------")
end

return M

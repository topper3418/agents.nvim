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

function M.tool(buf_lines, msg)
	-- short message if tool results are hidden
	if not require("lua.agents.properties").show_tool_results then
		table.insert(buf_lines, "**Tool Result:** " .. (msg.tool_name or "unknown"))
		return
	end
	table.insert(buf_lines, "**Tool Result:**")
	local ok, decoded = pcall(vim.json.decode, msg.content)
	-- show the tool that was called
	table.insert(buf_lines, "*Tool:* " .. (msg.tool_name or "unknown"))
	-- show the args given
	table.insert(buf_lines, "*Args:*")
	for _, line in ipairs(vim.split(msg.raw_arguments or "{}", "\n")) do
		table.insert(buf_lines, line)
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

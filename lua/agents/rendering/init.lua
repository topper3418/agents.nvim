local M = {}

M.msg = {}

function M.msg.user(buf_lines, msg)
	table.insert(buf_lines, "**You:**")
	for _, line in ipairs(vim.split(msg.content, "\n")) do
		table.insert(buf_lines, line)
	end
end

function M.msg.assistant(buf_lines, msg)
	table.insert(buf_lines, "**Grok:**")
	for _, line in ipairs(vim.split(msg.content, "\n")) do
		table.insert(buf_lines, line)
	end
end

function M.msg.tool(buf_lines, msg)
	table.insert(buf_lines, "**Tool Result:**")
	local ok, decoded = pcall(vim.json.decode, msg.content)
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

function M.msg.render(buf_lines, msg)
	if msg.role == "user" then
		M.msg.user(buf_lines, msg)
	elseif msg.role == "assistant" then
		M.msg.assistant(buf_lines, msg)
	elseif msg.role == "tool" then
		table.insert(buf_lines, "**Tool Result:**")
		local ok, decoded = pcall(vim.json.decode, msg.content)
		if ok and type(decoded) == "table" then
			M.msg.tool(buf_lines, msg)
		end
	end
end

return M

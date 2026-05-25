-- lua/agents/tools/init.lua
-- Minimal public API for all tools

local M = {}

-- Registry of all available tools
M.available_tools = {}

-- Register a tool with full schema
function M.register(name, fn, description, parameters)
	parameters = parameters or {
		type = "object",
		properties = vim.empty_dict(),
		required = vim.empty_dict(),
	}

	M.available_tools[name] = {
		fn = fn,
		description = description or "No description provided",
		parameters = parameters,
	}
end

-- Call a tool by name
function M.call(name, args)
	local tool = M.available_tools[name]
	if not tool then
		error("Unknown tool: " .. name)
	end
	return tool.fn(args)
end

-- Return tool list for the LLM
function M.get_tool_list()
	local list = {}
	for name, tool in pairs(M.available_tools) do
		table.insert(list, {
			type = "function",
			["function"] = {
				name = name,
				description = tool.description,
				parameters = tool.parameters,
			},
		})
	end
	return list
end

vim.schedule(function()
	require("agents.tools.read_file")
	require("agents.tools.find_files")
end)

return M

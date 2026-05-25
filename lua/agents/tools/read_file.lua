-- lua/agents/tools/read_file.lua

local tools = require("agents.tools")

local function read_file(args)
	local path = args.path
	if not path then
		return { error = "Missing 'path' argument" }
	end

	local ok, content = pcall(vim.fn.readfile, path)
	if not ok then
		return { error = "Could not read file: " .. path }
	end

	return { content = table.concat(content, "\n") }
end

tools.register("read_file", read_file, "Read the full content of a file on disk given its path.", {
	type = "object",
	properties = {
		path = { type = "string", description = "Full path to the file" },
	},
	required = { "path" },
})

return {}

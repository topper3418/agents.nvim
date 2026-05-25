-- lua/agents/tools/find_files.lua

local tools = require("agents.tools")

local function find_files(args)
	local query = args.query or "*"
	if query == "" then
		query = "*"
	end

	local cwd = vim.uv.cwd()
	local scandir = require("plenary.scandir")
	local files = scandir.scan_dir(cwd, {
		search_pattern = query,
		depth = 12,
		add_dirs = false,
		hidden = true,
	})

	return { files = files }
end

tools.register("find_files", find_files, "Recursively search for files in the current project.", {
	type = "object",
	properties = {
		query = {
			type = "string",
			description = "Filename, glob pattern, or search term (e.g. 'llm.lua', '*.lua', 'init')",
		},
	},
	required = {},
})

return {}

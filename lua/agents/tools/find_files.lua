-- lua/agents/tools/find_files.lua

local function find_files(args)
	local query = args.query or "*"
	if query == "" then
		query = "**/*"
	end

	local cwd = vim.uv.cwd()
	local files = {}

	-- Use vim.fs.find (more reliable than plenary.scandir for globs)
	for _, file in
		ipairs(vim.fs.find(function(name)
			return vim.fn.match(name, vim.fn.glob2regpat(query)) >= 0
		end, {
			path = cwd,
			limit = 50,
			type = "file",
			hidden = true,
		}))
	do
		-- Return paths relative to cwd for readability
		table.insert(files, vim.fn.fnamemodify(file, ":~:."))
	end

	return { files = files, count = #files }
end

return {
	"find_files",
	find_files,
	"Recursively search for files in the current project.",
	{
		type = "object",
		properties = {
			query = {
				type = "string",
				description = "Glob pattern (e.g. '*.lua', 'init*', '**/*test*')",
			},
		},
		required = {},
	},
}

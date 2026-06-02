-- lua/agents/tools/find_files.lua

local function find_files(args)
	local query = args.query or "**/*"
	if query == "" then
		query = "**/*"
	end

	local cwd = vim.uv.cwd() or "."

	local files = {}

	-- Use vim.fs.find with a better matcher
	for _, file in
		ipairs(vim.fs.find(function(name, path)
			-- name = basename, path = full path
			local full_path = path .. "/" .. name

			-- Convert glob to Lua pattern (more reliable than glob2regpat + match)
			local pattern = vim.fn.glob2regpat(query)
			return vim.fn.match(full_path, pattern) >= 0 or vim.fn.match(name, pattern) >= 0
		end, {
			path = cwd,
			limit = 100, -- increased a bit
			type = "file",
			hidden = true,
		}))
	do
		-- Return relative paths for cleaner output
		local rel_path = vim.fn.fnamemodify(file, ":~:.")
		table.insert(files, rel_path)
	end

	return {
		files = files,
		count = #files,
		cwd = cwd,
	}
end

return {
	name = "find_files",
	fn = find_files,
	desc = "Recursively search for files in the current project.",
	parameters = {
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

-- lua/agents/tools/read_file.lua

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

return {
	name = "read_file",
	fn = read_file,
	desc = "Read the full content of a file on disk given its path.",
	parameters = {
		type = "object",
		properties = {
			path = { type = "string", description = "Full path to the file" },
		},
		required = { "path" },
	},
}

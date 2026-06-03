-- lua/agents/tools/grep.lua

local function grep(args)
	local pattern = args.pattern
	if not pattern then
		return { error = "Missing 'pattern' argument" }
	end

	local path = args.path or vim.uv.cwd() or "."
	local glob = args.glob

	local cmd = { "rg", "--line-number", "--no-heading", "--color=never", pattern, path }
	if glob then
		table.insert(cmd, "--glob")
		table.insert(cmd, glob)
	end

	local ok, result = pcall(vim.fn.systemlist, cmd)
	if not ok or vim.v.shell_error ~= 0 then
		-- Fallback to POSIX grep
		cmd = { "grep", "-rn", pattern, path }
		if glob then
			-- grep --include doesn't support all globs the same way
			table.insert(cmd, "--include=" .. glob)
		end
		ok, result = pcall(vim.fn.systemlist, cmd)
		if not ok then
			return { error = "Grep command failed" }
		end
	end

	local matches = {}
	for _, line in ipairs(result) do
		local file, lnum, text = line:match("^([^:]+):(%d+):(.*)$")
		if file then
			table.insert(matches, { file = file, line = tonumber(lnum), text = text })
		end
	end

	return { matches = matches, count = #matches }
end

return {
	name = "grep",
	fn = grep,
	desc = "Search for a pattern in file contents using ripgrep or grep.",
	parameters = {
		type = "object",
		properties = {
			pattern = { type = "string", description = "Search pattern (regex supported by rg/grep)" },
			path = { type = "string", description = "Directory or file to search (defaults to cwd)" },
			glob = { type = "string", description = "Glob pattern to filter files (e.g. '*.lua')" },
		},
		required = { "pattern" },
	},
}

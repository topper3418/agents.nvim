local M = {}

local db_path = cwd .. "/.nvim/agents/history.db"

-- Ensure directory exists
vim.fn.mkdir(vim.fn.fnamemodify(db_path, ":h"), "p")

local function exec(sql)
	-- Use -batch and -noheader for cleaner output
	local cmd = { "sqlite3", "-batch", db_path, sql }
	local output = vim.fn.system(cmd)

	if vim.v.shell_error ~= 0 then
		error("sqlite3 error: " .. output)
	end

	return vim.trim(output)
end

-- Run multiple statements (useful for CREATE TABLE etc.)
function M.exec(sql)
	return exec(sql)
end

-- Convenience for queries that return rows
function M.query(sql)
	local result = exec(sql)
	if result == "" then
		return {}
	end

	local rows = {}
	for line in vim.gsplit(result, "\n", { plain = true }) do
		table.insert(rows, vim.split(line, "|", { plain = true }))
	end
	return rows
end

return M

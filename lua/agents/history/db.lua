local M = {}

local db_path = cwd .. "/.nvim/agents/history.db"

-- Ensure directory exists
vim.fn.mkdir(vim.fn.fnamemodify(db_path, ":h"), "p")

local function run(sql)
	local cmd = { "sqlite3", "-batch", db_path, sql }
	local output = vim.fn.system(cmd)

	if vim.v.shell_error ~= 0 then
		error("sqlite3 error: " .. output)
	end
	return vim.trim(output)
end

-- For CREATE TABLE, UPDATE, DELETE, etc.
function M.exec(sql)
	run(sql)
end

-- For INSERTs — returns the new row id
function M.insert(sql)
	run(sql)
	local id = run("SELECT last_insert_rowid();")
	return tonumber(id)
end

-- Convenience for queries that return rows
function M.query(sql)
	local result = run(sql)
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

local M = {}

local db_path = vim.fn.getcwd() .. "/.nvim/agents/history.db"

-- Ensure directory exists
vim.fn.mkdir(vim.fn.fnamemodify(db_path, ":h"), "p")

local function interpolate(sql, params)
	if not params then
		return sql
	end

	local i = 0
	return (
		sql:gsub("?", function()
			i = i + 1
			local val = params[i]
			if val == nil then
				return "NULL"
			elseif type(val) == "string" then
				return "'" .. val:gsub("'", "''") .. "'"
			else
				return tostring(val)
			end
		end)
	)
end

local function run(sql, params)
	sql = interpolate(sql, params)
	local cmd = { "sqlite3", "-batch", "-noheader", "-list", db_path, sql }
	local output = vim.fn.system(cmd)

	if vim.v.shell_error ~= 0 then
		error("sqlite3 error: " .. output)
	end
	return vim.trim(output)
end

-- For CREATE TABLE, UPDATE, DELETE, etc.
function M.exec(sql, params)
	run(sql, params)
end

-- For INSERTs — returns the new row id
function M.insert(sql, params)
	sql = sql .. "; SELECT last_insert_rowid();"
	local out = run(sql, params) -- one process
	return tonumber(out)
end

-- Convenience for queries that return rows
function M.query(sql, params)
	local result = run(sql, params)
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

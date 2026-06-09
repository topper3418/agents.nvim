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

local function run(sql, params, as_json)
	as_json = as_json ~= false -- default to true
	sql = interpolate(sql, params)
	local format_flag = as_json and "-json" or "-list"
	local cmd = { "sqlite3", "-batch", "-noheader", format_flag, db_path, sql }
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
	local out = run(sql, params, false) -- one process
	return tonumber(out)
end

-- Convenience for queries that return rows
function M.query(sql, params)
	local result = run(sql, params)
	if result == "" then
		return {}
	end

	local ok, decoded = pcall(vim.json.decode, result)
	if not ok or type(decoded) ~= "table" then
		return {}
	end
	return decoded
end

return M

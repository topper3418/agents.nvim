-- lua/agents/rendering/command.lua
-- responsible for rendering command output in the chat window

local M = {}

function M.render_command_output(buf_lines, output)
	table.insert(buf_lines, "**Command Output:**")
	for _, line in ipairs(output) do
		table.insert(buf_lines, line)
	end
end

return M

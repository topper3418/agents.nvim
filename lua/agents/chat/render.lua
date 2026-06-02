-- lua/agents/chat/render.lua
-- Handles rendering the chat window

local M = {}

-- @param buf buffer to render into
-- @callback callback to set cursor after rendering (input_line, col)
-- @opts additional options for rendering, e.g. command_output to render command output after a tool call
function M.render(buf, callback, opts)
	-- unlock buffer for rendering
	vim.api.nvim_buf_set_option(buf, "modifiable", true)
	local lines = { "# agents.nvim Chat — chatting with Grok (xAI)", "" }

	local renderer = require("agents.rendering")

	-- Add previous messages
	for _, msg in ipairs(require("agents.history").history) do
		renderer.msg.render(lines, msg)
	end

	-- if this is being called after a command output,
	-- add the command output to the buffer
	if opts and opts.command_output then
		renderer.command.render_command_output(lines, opts.command_output)
	end
	table.insert(lines, "")

	-- give input line
	table.insert(lines, "> ")
	-- render
	vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
	vim.api.nvim_buf_set_option(buf, "modified", false)
	vim.api.nvim_buf_set_option(buf, "modifiable", false)

	-- move cursor to the input line
	local input_line = #lines
	callback(input_line, 2)
end

return M

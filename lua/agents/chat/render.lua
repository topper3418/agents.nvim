-- lua/agents/chat/render.lua
-- Handles rendering the chat window

local M = {}

-- @param buf buffer to render into
-- @callback callback to set cursor after rendering (input_line, col)
function M.render(buf, callback)
	-- unlock buffer for rendering
	vim.api.nvim_buf_set_option(buf, "modifiable", true)
	local lines = { "# agents.nvim Chat — chatting with Grok (xAI)", "" }

	-- Add previous messages
	for _, msg in ipairs(require("agents.history").history) do
		require("agents.rendering").msg.render(lines, msg, M.show_tool_results)
	end
	table.insert(lines, "")

	vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
	vim.api.nvim_buf_set_option(buf, "modified", false)
	vim.api.nvim_buf_set_option(buf, "modifiable", false)

	-- give input line and move cursor to it
	table.insert(lines, "> ")
	local input_line = #lines
	callback(input_line, 2)
end

return M

local M = {}

local function step(buf, done)
	require("agents.llm").chat(require("agents.history").history, function(message)
		if not message then
			done()
			return
		end

		if message.tool_calls and #message.tool_calls > 0 then
			-- 1. Store the assistant message that requested the tool calls
			require("agents.history").add_message({
				role = "assistant",
				content = message.content or "",
				tool_calls = message.tool_calls,
			})

			-- 2. Execute tools and append results
			for _, call in ipairs(message.tool_calls) do
				local tool_name = call["function"].name
				local args = vim.json.decode(call["function"].arguments or "{}") or {}

				vim.api.nvim_buf_set_lines(buf, -1, -1, false, { "🛠️ Running: " .. tool_name })
				vim.cmd.redraw()
				local result = require("agents.tools").call(tool_name, args)

				require("agents.history").add_message({
					role = "tool",
					tool_call_id = call.id,
					content = vim.json.encode(result),
					tool_name = tool_name,
				})
			end

			vim.api.nvim_buf_set_lines(buf, -1, -1, false, { "🧠 Thinking (chaining)..." })
			step(buf, done) -- continue the loop
		else
			if message.content then
				require("agents.history").add_message({
					role = "assistant",
					content = message.content,
				})
			end
			done()
		end
	end)
end

function M.loop(buf, done)
	step(buf, function()
		done()
	end)
end

return M

local M = {}

local function step(chat_object, buf, done)
	require("agents.llm").chat(chat_object.history, function(message)
		if not message then
			done()
			return
		end

		if message.tool_calls and #message.tool_calls > 0 then
			-- 1. Store the assistant message that requested the tool calls
			table.insert(chat_object.history, {
				role = "assistant",
				content = message.content or "",
				tool_calls = message.tool_calls,
			})

			-- 2. Execute tools and append results
			for _, call in ipairs(message.tool_calls) do
				local tool_name = call["function"].name
				local args = vim.json.decode(call["function"].arguments or "{}") or {}

				local result = require("agents.tools").call(tool_name, args)

				table.insert(chat_object.history, {
					role = "tool",
					tool_call_id = call.id,
					content = vim.json.encode(result),
					tool_name = tool_name,
				})
			end

			vim.api.nvim_buf_set_lines(buf, -1, -1, false, { "Thinking (chaining)..." })
			step(chat_object, buf, done) -- continue the loop
		else
			if message.content then
				table.insert(chat_object.history, {
					role = "assistant",
					content = message.content,
				})
			end
			done()
		end
	end)
end

function M.loop(chat_object, buf)
	step(chat_object, buf, function()
		chat_object.render(buf) -- call render when fully done
	end)
end

return M

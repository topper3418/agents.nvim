local M = {}

function M.loop(chat_object, buf)
	while true do
		local message = require("agents.llm").chat(chat_object.history)

		if not message then
			break
		end

		if message.tool_calls and #message.tool_calls > 0 then
			-- Grok wants to use one or more tools
			for _, call in ipairs(message.tool_calls) do
				local tool_name = call["function"].name
				local args_str = call["function"].arguments or "{}"
				local ok, args = pcall(vim.json.decode, args_str)
				if not ok then
					args = {}
				end

				-- vim.notify("🛠️ Executing: " .. tool_name, vim.log.levels.INFO)

				local result = require("agents.tools").call(tool_name, args)

				-- Feed the result back to Grok
				table.insert(chat_object.history, {
					role = "tool",
					tool_call_id = call.id,
					content = vim.json.encode(result),
					tool_name = tool_name,
					arguments = args,
					raw_arguments = args_str,
				})
				vim.cmd("redraw")
			end

			-- Continue the loop (Grok gets to see the tool results and decide next step)
			vim.api.nvim_buf_set_lines(buf, -1, -1, false, { "Thinking (chaining)..." })
			-- if there was an agent message associated
			vim.cmd("redraw")
		else
			-- Grok gave a normal text answer → we're done
			if message.content then
				table.insert(chat_object.history, { role = "assistant", content = message.content })
			end
			break
		end
	end
end

return M

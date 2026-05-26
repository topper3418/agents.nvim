-- lua/agents/llm.lua
-- This is where all LLM API calls will live

local curl = require("plenary.curl") -- this is the "openai library" equivalent in Neovim

local M = {}

-- Send a full conversation to xAI and get back the assistant reply (blocking for now)
function M.chat(messages, callback)
	local config = require("agents").config

	if not config.api_key or config.api_key == "" then
		vim.notify("agents.nvim: No XAI_API_KEY set", vim.log.levels.ERROR)
		return nil
	end

	local body = {
		model = "grok-4.3",
		messages = messages, -- full history: { {role="user", content=...}, ... }
		temperature = 0.7,
		-- stream = true  <-- we'll turn this on later for streaming
		timeout = 120000,
		tools = require("agents.tools").get_tool_list(),
		tool_choice = "auto",
	}


	curl.post(config.api_url, {
		headers = {
			["Content-Type"] = "application/json",
			["Authorization"] = "Bearer " .. config.api_key,
		},
		body = vim.json.encode(body),
		callback = function(res)
			-- This runs on a fast event, so we schedule it
			vim.schedule(function()
					if res.status ~= 200 then
							vim.notify("LLM error: " .. (res.body or "unknown"), vim.log.levels.ERROR)
							return callback(nil)
					end

					local ok, data = pcall(vim.json.decode, res.body)
					if not ok or not data.choices or not data.choices[1] then
							vim.notify("Failed to parse response", vim.log.levels.ERROR)
							return callback(nil)
					end

					callback(data.choices[1].message)
			end)
	})
end

return M

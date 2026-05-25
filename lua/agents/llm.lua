-- lua/agents/llm.lua
-- This is where all LLM API calls will live

local curl = require("plenary.curl") -- this is the "openai library" equivalent in Neovim

local M = {}

-- Simple synchronous "hello world" call that asks for a 4-line poem
function M.ask_for_poem()
	-- Get the config safely
	local agents = require("agents")
	local config = agents.config or {}

	if not config.api_key or config.api_key == "" then
		vim.notify("agents.nvim: Please set api_key in your Lazy config!", vim.log.levels.ERROR)
		return
	end

	local body = {
		model = "grok-4.3", -- change if you want a different model
		messages = {
			{
				role = "system",
				content = "You are a helpful assistant.",
			},
			{
				role = "user",
				content = "Write a beautiful four-line poem about coding in Neovim.",
			},
		},
		temperature = 0.7,
	}

	-- This is the actual HTTP call (synchronous for now — super simple)
	local res = curl.post(config.api_url, {
		headers = {
			["Content-Type"] = "application/json",
			["Authorization"] = "Bearer " .. config.api_key,
		},
		body = vim.json.encode(body),
	})

	if res.status ~= 200 then
		vim.notify("LLM call failed: " .. (res.body or "unknown error"), vim.log.levels.ERROR)
		return
	end

	-- Parse the JSON response
	local ok, data = pcall(vim.json.decode, res.body)
	if not ok or not data.choices or not data.choices[1] then
		vim.notify("Failed to parse LLM response", vim.log.levels.ERROR)
		return
	end

	local poem = data.choices[1].message.content

	-- Print the poem nicely
	vim.notify("🪄 Here's your 4-line poem:\n\n" .. poem, vim.log.levels.INFO)
end

-- Send a full conversation to xAI and get back the assistant reply (blocking for now)
function M.chat(messages)
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
	}

	local res = curl.post(config.api_url, {
		headers = {
			["Content-Type"] = "application/json",
			["Authorization"] = "Bearer " .. config.api_key,
		},
		body = vim.json.encode(body),
	})

	if res.status ~= 200 then
		vim.notify("LLM error: " .. (res.body or "unknown"), vim.log.levels.ERROR)
		return nil
	end

	local ok, data = pcall(vim.json.decode, res.body)
	if not ok or not data.choices or not data.choices[1] then
		vim.notify("Failed to parse response", vim.log.levels.ERROR)
		return nil
	end

	return data.choices[1].message.content
end

return M

-- lua/agents/init.lua

local M = {}

-- Default configuration
local defaults = {
	api_key = vim.env.XAI_API_KEY,
	api_url = "https://api.x.ai/v1/chat/completions",
}

M.config = {}
M.chat = require("agents.chat")
M.history = require("agents.history")
M.agent_loop = require("agents.agent_loop")
M.tools = require("agents.tools")
M.commands = require("agents.commands")

function M.setup(opts)
	-- Prefer environment variable
	local api_key = opts.api_key or os.getenv("XAI_API_KEY") or ""

	-- Merge config (env var wins if nothing was passed in opts)
	M.config = vim.tbl_deep_extend("force", defaults, opts, {
		api_key = api_key,
	})

	-- Register chat command
	vim.api.nvim_create_user_command("AgentsChat", function()
		require("agents.chat").open()
	end, { desc = "Open a new agents.nvim chat window" })

	vim.notify("🚀 agents.nvim loaded successfully!", vim.log.levels.DEBUG)

	-- Quick validation so the user knows if they forgot the key
	if M.config.api_key == "" then
		vim.notify("⚠️  agents.nvim: api_key is not set in your Lazy config!", vim.log.levels.WARN)
	end

	M.history.init_db()
end

return M

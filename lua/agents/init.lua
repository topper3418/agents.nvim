-- lua/agents/init.lua

local M = {}

-- Default configuration
local defaults = {
	api_key = vim.env.XAI_API_KEY,
	api_url = "https://api.x.ai/v1/chat/completions",
}

M.config = {}

function M.setup(opts)
	-- Prefer environment variable
	local api_key = opts.api_key or os.getenv("XAI_API_KEY") or ""

	-- Merge config (env var wins if nothing was passed in opts)
	M.config = vim.tbl_deep_extend("force", defaults, opts, {
		api_key = api_key,
	})

	vim.notify("🚀 agents.nvim loaded successfully!", vim.log.levels.INFO)

	-- Quick validation so the user knows if they forgot the key
	if M.config.api_key == "" then
		vim.notify("⚠️  agents.nvim: api_key is not set in your Lazy config!", vim.log.levels.WARN)
	end

	-- Register our first command
	vim.api.nvim_create_user_command("AgentsPoem", function()
		require("agents.llm").ask_for_poem()
	end, { desc = "Ask LLM for a 4-line poem" })
end

return M

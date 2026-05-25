-- plugin/agents.lua
-- This file is automatically sourced by Neovim when the plugin is in your runtimepath.

if vim.g.loaded_agents then
	return
end
vim.g.loaded_agents = true

-- Load our main module and call setup
require("agents")

# Agents

This plugin will do something with agents. idk I'm fucking around. 

## Configuration

Add this to your Lazy.nvim spec:

```lua
{
  dir = "~/Projects/agents.nvim",
  dev = true,
  dependencies = { 
    "nvim-lua/plenary.nvim",
    { "nvim-telescope/telescope.nvim", optional = true },  
  },
  config = function()
    require("agents").setup({
      api_url = "https://api.x.ai/v1/chat/completions",
      -- chat window style
      chat = {
        style = "float",        -- "float" or "split"
        position = "below",     -- for split: "above", "below", "left", "right"
        height = 0.8,           -- percentage of screen (float only)
        width  = 0.8,           -- percentage of screen (float only)
      },
    })
    -- Global keymap: <leader>ct opens the chat window
    vim.keymap.set("n", "<leader>ct", function()
      require("agents.chat").open()
    end, { desc = "Open agents.nvim chat window", silent = true })
  end,
}


## Dev plan

1) [/] set it up as a basic nvim plugin
2) [/] link itin my nvim config
3) [/] get it to do a very basic chat in a popup window or something
  - [/] get it to take config so users can set their variables
  - [/] configure it to use grok, do hello world
  - [/] get it to save chats somewhere and implement the chat feature
4) [ ] make a "read_file" tool for it to call and add files to the context
5) [ ] etc


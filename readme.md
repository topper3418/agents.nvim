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
    })
    -- Global keymap: <leader>ct opens the chat window
    vim.keymap.set("n", "<leader>ct", function()  -- "ct" = "chat"
      require("agents.chat").open({
        style = "float",        -- "float" or "split"
        position = "below",     -- for split: "above", "below", "left", "right"
        height = 0.8,           -- percentage of screen (float only)
        width  = 0.8,           -- percentage of screen (float only)
      })
    end, { desc = "Open agents.nvim chat window", silent = true })
  end,
}
```


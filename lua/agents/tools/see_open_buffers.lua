-- lua/agents/tools/see_open_buffers.lua
-- Tool to list all currently open (loaded) buffers in Neovim.

local function see_open_buffers(args)
	local buffers = {}
	for _, buf in ipairs(vim.api.nvim_list_bufs()) do
		if vim.api.nvim_buf_is_loaded(buf) then
			local name = vim.api.nvim_buf_get_name(buf)
			if name == "" then
				name = "[No Name]"
			end
			-- local modified = vim.api.nvim_buf_get_option(buf, "modified")
			local modified = vim.api.nvim_get_option_value("modified", { buf = buf })
			table.insert(buffers, {
				bufnr = buf,
				name = name,
				modified = modified,
			})
		end
	end
	return { buffers = buffers, count = #buffers }
end

return {
	name = "see_open_buffers",
	fn = see_open_buffers,
	desc = "List all currently open (loaded) buffers in Neovim.",
	parameters = {
		type = "object",
		properties = vim.empty_dict(), -- no parameters needed for this tool
		required = {},
	},
}

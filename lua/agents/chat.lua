-- lua/agents/chat.lua
-- Handles opening the chat window (float or split)

local M = {}

-- Opens a new chat buffer in the configured style
function M.open()
	local config = require("agents").config

	-- Reuse existing chat buffer if it already exists
	local buf = vim.fn.bufnr("agents-chat")
	if buf == -1 then
		buf = vim.api.nvim_create_buf(false, true)
		vim.api.nvim_buf_set_name(buf, "agents-chat")
		vim.api.nvim_buf_set_option(buf, "filetype", "markdown")
		vim.api.nvim_buf_set_option(buf, "buftype", "nofile")
	end

	M.history = M.history or {}

	if not M.system_prompt_added then
		table.insert(M.history, 1, {
			role = "system",
			content = "You are an agentic coding assistant inside Neovim. "
				.. "You have access to tools that allow you to use the application's current context to give better answers"
				.. "IMPORTANT: You can (and should) make MULTIPLE tool calls in sequence. "
				.. "After receiving a tool result, decide if you need to call another tool before giving a final answer to the user. "
				.. "Only give a final answer when you have all the information you need. "
				.. "Never guess file contents. Be concise.",
		})
		M.system_prompt_added = true
	end

	-- Open the window
	if config.chat.style == "float" then
		local width = math.floor(vim.o.columns * config.chat.width)
		local height = math.floor(vim.o.lines * config.chat.height)
		vim.api.nvim_open_win(buf, true, {
			relative = "editor",
			width = width,
			height = height,
			col = math.floor((vim.o.columns - width) / 2),
			row = math.floor((vim.o.lines - height) / 2),
			border = "rounded",
			style = "minimal",
		})
	else
		local cmd = config.chat.position == "above" and "topleft" or "botright"
		if config.chat.position == "left" or config.chat.position == "right" then
			cmd = "vertical " .. cmd
		end
		vim.cmd(cmd .. " split")
		vim.api.nvim_win_set_buf(0, buf)
	end

	-- Render current history + chat cursor
	M.render(buf)

	-- Debug: show available tools in a notification
	local tool_names = vim.tbl_keys(require("agents.tools").available_tools)
	vim.notify("🛠️  Loaded tools: " .. table.concat(tool_names, ", "), vim.log.levels.INFO)

	-- Set up buffer-local keymaps and protections
	M.setup_buffer_keymaps(buf)
end

-- Render history + chat cursor into the buffer
function M.render(buf)
	local lines = { "# agents.nvim Chat — chatting with Grok (xAI)", "" }

	-- Add previous messages
	for _, msg in ipairs(M.history or {}) do
		if msg.role == "user" then
			table.insert(lines, "**You:**")
			for _, line in ipairs(vim.split(msg.content, "\n")) do
				table.insert(lines, line)
			end
		elseif msg.role == "assistant" then
			table.insert(lines, "**Grok:**")
			for _, line in ipairs(vim.split(msg.content, "\n")) do
				table.insert(lines, line)
			end
		elseif msg.role == "tool" then
			table.insert(lines, "**Tool result:**")
			-- Show what Grok asked for (great for debugging)
			local result = vim.json.decode(msg.content) or msg.content
			local pretty = type(result) == "table" and vim.inspect(result) or tostring(result)
			for _, line in ipairs(vim.split(pretty, "\n")) do
				table.insert(lines, line)
			end
		end
	end
	table.insert(lines, "")

	-- Chat cursor / input area
	table.insert(
		lines,
		"─────────────────────────────────────"
	)
	table.insert(lines, "> ") -- user types here

	vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
	vim.api.nvim_buf_set_option(buf, "modifiable", true)

	-- Move cursor to the input line
	local input_line = #lines
	vim.api.nvim_win_set_cursor(0, { input_line, 2 }) -- right after the "> "
end

-- Protect the buffer and set up sending
function M.setup_buffer_keymaps(buf)
	-- Send on <CR> in NORMAL mode
	vim.keymap.set("n", "<CR>", function()
		M.send(buf)
	end, { buffer = buf, silent = true, desc = "Send message to Grok" })

	-- Send on <CR> in INSERT mode
	vim.keymap.set("i", "<CR>", function()
		vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "n", false)
		vim.schedule(function()
			M.send(buf)
		end)
	end, { buffer = buf, silent = true, desc = "Send message to Grok" })

	-- Protection: only enforce when trying to INSERT above the input line
	vim.api.nvim_create_autocmd("InsertEnter", {
		buffer = buf,
		callback = function()
			local cursor = vim.api.nvim_win_get_cursor(0)
			local total_lines = vim.api.nvim_buf_line_count(buf)

			if cursor[1] < total_lines then
				-- Jump to input line and stay in insert mode
				vim.api.nvim_win_set_cursor(0, { total_lines, 2 })
				-- No need to call startinsert again — we're already entering Insert mode
			end
		end,
	})

	-- Quick normal-mode shortcut to jump to input and start typing
	vim.keymap.set("n", "r", function()
		local total_lines = vim.api.nvim_buf_line_count(buf)
		vim.api.nvim_win_set_cursor(0, { total_lines, 2 })
		vim.cmd("startinsert")
	end, { buffer = buf, silent = true, desc = "Reply / jump to input" })

	-- Auto-enter insert mode the first time the window opens
	vim.cmd("startinsert")
end

-- Send the current input and get a reply
function M.send(buf)
	local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
	local input_line = lines[#lines]

	-- Strip the "> " prefix
	local user_msg = input_line:gsub("^>%s*", "")
	if user_msg == "" then
		return
	end

	-- Initialize history if first time
	M.history = M.history or {}

	-- Add user message to history
	table.insert(M.history, { role = "user", content = user_msg })

	-- Show "thinking..." while we wait
	vim.api.nvim_buf_set_lines(buf, -1, -1, false, { "Thinking..." })
	vim.cmd("redraw")

	-- Show that we're calling the LLM
	-- vim.api.nvim_buf_set_lines(buf, -1, -1, false, { "Thinking..." })
	vim.cmd("redraw")

	-- === AGENT LOOP ===
	while true do
		local message = require("agents.llm").chat(M.history)

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

				vim.notify("🛠️ Executing: " .. tool_name, vim.log.levels.INFO)

				local result = require("agents.tools").call(tool_name, args)

				-- Feed the result back to Grok
				table.insert(M.history, {
					role = "tool",
					tool_call_id = call.id,
					content = vim.json.encode(result),
				})
			end

			-- Continue the loop (Grok gets to see the tool results and decide next step)
			vim.api.nvim_buf_set_lines(buf, -1, -1, false, { "Thinking (chaining)..." })
			vim.cmd("redraw")
		else
			-- Grok gave a normal text answer → we're done
			if message.content then
				table.insert(M.history, { role = "assistant", content = message.content })
			end
			break
		end
	end

	M.render(buf)
end

return M

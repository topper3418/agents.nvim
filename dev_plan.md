# agents.nvim Roadmap

## Core Goal
Build a **strong agentic coding assistant** inside Neovim that deeply understands my codebase and can take meaningful actions.

The foundation must be excellent codebase understanding before we add powerful editing capabilities.

---

## Current Status (as of May 25, 2026)
- Basic chat buffer with float/split support
- Working agent loop with tool chaining
- `read_file` and `find_files` tools (with Telescope support) Tool calling working with xAI/Grok
- Basic configuration and keymaps

---

## Phase 1: Polish & Stability (Next)

**Must Fix / Improve:**
- Strong buffer protection (prevent accidental deletion of chat history)
- Better tool result rendering (clean, readable output instead of raw JSON)
- Improve error handling and resilience
- Add proper loading / thinking indicators
- Add `:checkhealth agents` support

**Nice-to-have in this phase:**
- Slash commands (`/clear`, `/help`, `/model`, etc.)
- Basic model selector (hardcoded for Grok)

---

## Phase 2: Core Experience (High Priority)

- **Streaming responses** from Grok
- Local context chat (`<leader>cw`) — opens temporary chat with surrounding code context
- Strong `grep_search` tool
- `read_buffer`, `get_current_file`, `get_file_symbols` tools
- Better chat formatting (clear distinction between messages, tool calls, results)

---

## Phase 3: Agentic Capabilities

- `edit_file` / `propose_edit` with user approval workflow (diff buffer + accept/reject)
- More powerful tools (`run_command`, `diagnostics`, etc.)
- Better code tracing capabilities
- Slash command system expansion

---

## Phase 4: Extensibility & Polish

- Support for user-defined custom tools via config
- Chat persistence (SQLite or file-based)
- Multiple simultaneous chat sessions
- Configuration cleanup (clean `setup()` API, defaults, etc.)
- Testing framework (plenary)

---

## Future / Nice-to-Have Ideas

- Full Treesitter + LSP integration for better code understanding
- Custom tool renderers
- Multi-model support (OpenAI-compatible + Grok)
- Chat memory summarization
- Code graph / semantic indexing
- MCP support (long term)

---

## Guiding Principles

- Prioritize **codebase understanding** before powerful editing
- Keep tool registration simple for now (optional renderers later)
- Favor transparency — user should see tool calls and reasoning
- Make the chat feel like "just another Neovim buffer" (easy to yank from, navigate, etc.)

---

Last Updated: May 25, 2026

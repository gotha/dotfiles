-- MCPHub configuration
require("mcphub").setup({
	-- Path to MCP servers configuration file
	config = vim.fn.expand("~/.config/mcp/mcp.json"),

	-- Port for mcp-hub server
	port = 37373,

	-- Auto-start MCP servers on startup
	auto_start = true,

	-- Auto approve MCP tool calls (set to false for confirmation prompts)
	auto_approve = false,

	-- Allow LLMs to start/stop MCP servers automatically
	auto_toggle_mcp_servers = true,

	-- Chat plugin integrations
	extensions = {
		avante = {
			enabled = true,
			make_slash_commands = true, -- Convert MCP prompts to slash commands
		},
		codecompanion = {
			enabled = true,
		},
		copilotchat = {
			enabled = true,
		},
	},

	-- Workspace configuration for project-local configs
	workspace = {
		enabled = true,
		look_for = { ".mcphub/servers.json", ".vscode/mcp.json", ".cursor/mcp.json" },
		reload_on_dir_changed = true,
	},
})

-- Key mappings for MCPHub
vim.keymap.set("n", "<leader>mh", "<cmd>MCPHub<cr>", { desc = "Open MCPHub" })
vim.keymap.set("n", "<leader>ms", "<cmd>MCPHubServers<cr>", { desc = "MCPHub Servers" })
vim.keymap.set("n", "<leader>mt", "<cmd>MCPHubTools<cr>", { desc = "MCPHub Tools" })
vim.keymap.set("n", "<leader>mr", "<cmd>MCPHubResources<cr>", { desc = "MCPHub Resources" })
vim.keymap.set("n", "<leader>mp", "<cmd>MCPHubPrompts<cr>", { desc = "MCPHub Prompts" })

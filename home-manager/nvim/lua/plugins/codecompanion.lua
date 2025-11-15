-- CodeCompanion configuration
require("codecompanion").setup({
	-- Adapters configuration
	adapters = {
		-- See: https://codecompanion.olimorris.dev/configuration/adapters
		http = {
			ollama = function()
				return require("codecompanion.adapters").extend("ollama", {
					env = { url = "http://127.0.0.1:11434" },
					model = "qwen2.5-coder:7b", -- default model
				})
			end,
		},
	},

	-- Strategies configuration
	strategies = {
		chat = {
			adapter = "ollama", -- Default adapter for chat
		},
		inline = {
			adapter = "ollama", -- Default adapter for inline assistant
		},
		agent = {
			adapter = "ollama", -- Default adapter for agents
		},
	},

	-- Extensions configuration - MCPHub integration
	extensions = {
		mcphub = {
			callback = "mcphub.extensions.codecompanion",
			opts = {
				-- MCP Tools configuration
				make_tools = true, -- Make individual tools (@server__tool) and server groups (@server)
				show_server_tools_in_chat = true, -- Show individual tools in chat completion
				add_mcp_prefix_to_tool_names = false, -- Don't add mcp__ prefix to tool names
				show_result_in_chat = true, -- Show tool results directly in chat buffer

				-- MCP Resources configuration
				make_vars = true, -- Convert MCP resources to #variables for prompts

				-- MCP Prompts configuration
				make_slash_commands = true, -- Add MCP prompts as /slash commands
			},
		},
	},

	-- Display configuration
	display = {
		action_palette = {
			width = 95,
			height = 10,
		},
		chat = {
			window = {
				layout = "vertical", -- vertical, horizontal, float, buffer
				width = 0.45,
				height = 0.4,
				relative = "editor",
				opts = {
					breakindent = true,
					cursorcolumn = false,
					cursorline = false,
					foldcolumn = "0",
					linebreak = true,
					list = false,
					signcolumn = "no",
					spell = false,
					wrap = true,
				},
			},
		},
	},

	-- Prompt library configuration
	prompt_library = {
		["Custom Code Review"] = {
			strategy = "chat",
			description = "Get a code review with suggestions",
			opts = {
				mapping = "<LocalLeader>cr",
				modes = { "v" },
				slash_cmd = "review",
				auto_submit = true,
			},
			prompts = {
				{
					role = "system",
					content = "You are a senior software engineer conducting a code review. Provide constructive feedback, identify potential issues, and suggest improvements.",
				},
				{
					role = "user",
					content = function(context)
						return "Please review this code:\n\n```" .. context.filetype .. "\n" .. context.selection .. "\n```"
					end,
				},
			},
		},
	},
})

-- Key mappings for CodeCompanion
vim.keymap.set("n", "<leader>cc", "<cmd>CodeCompanionChat<cr>", { desc = "CodeCompanion Chat" })
vim.keymap.set("v", "<leader>cc", "<cmd>CodeCompanionChat<cr>", { desc = "CodeCompanion Chat" })
vim.keymap.set("n", "<leader>ca", "<cmd>CodeCompanionActions<cr>", { desc = "CodeCompanion Actions" })
vim.keymap.set("v", "<leader>ca", "<cmd>CodeCompanionActions<cr>", { desc = "CodeCompanion Actions" })
vim.keymap.set("n", "<leader>ct", "<cmd>CodeCompanionChat Toggle<cr>", { desc = "CodeCompanion Toggle" })
vim.keymap.set("n", "<leader>ci", "<cmd>CodeCompanion<cr>", { desc = "CodeCompanion Inline" })
vim.keymap.set("v", "<leader>ci", "<cmd>CodeCompanion<cr>", { desc = "CodeCompanion Inline" })

-- Additional keymaps for quick access
vim.keymap.set("n", "<leader>cq", function()
	vim.ui.input({ prompt = "Quick question: " }, function(input)
		if input and input ~= "" then
			vim.cmd("CodeCompanionChat " .. input)
		end
	end)
end, { desc = "CodeCompanion Quick Question" })

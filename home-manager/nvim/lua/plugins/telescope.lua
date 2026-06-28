require("telescope").setup({
	defaults = {
		-- Disable treesitter previews: telescope 0.1.x calls nvim-treesitter's master-only ft_to_lang (removed in main), which crashes; regex highlighting is fine here.
		preview = {
			treesitter = false,
		},
	},
})

local builtin = require("telescope.builtin")
vim.keymap.set("n", "<leader>tf", builtin.find_files, {})
vim.keymap.set("n", "<leader>tg", builtin.live_grep, {})
vim.keymap.set("n", "<leader>tb", builtin.buffers, {})
vim.keymap.set("n", "<leader>th", builtin.help_tags, {})
vim.keymap.set("n", "<leader>tr", builtin.resume, {})

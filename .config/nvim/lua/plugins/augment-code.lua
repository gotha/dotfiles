-- iUse Ctrl-Y to accept a suggestion
-- inoremap <c-y> <cmd>call augment#Accept()<cr>
vim.api.nvim_set_keymap("i", "<C-y>", "<cmd>call augment#Accept()<cr>", { noremap = true, silent = true })

vim.keymap.set("n", "<leader>cc", "<cmd>Augment chat<cr>")
vim.keymap.set("n", "<leader>cn", "<cmd>Augment new<cr>")
vim.keymap.set("n", "<leader>ct", "<cmd>Augment chat-toggle<cr>")

-- Use enter to accept a suggestion, falling back to a newline if no suggestion
-- is available
-- inoremap <cr> <cmd>call augment#Accept("\n")<cr>

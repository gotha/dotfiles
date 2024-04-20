-- save file on capital W command
-- vim.cmd("command! W write")
vim.api.nvim_create_user_command("W", "write", { nargs = 0 })

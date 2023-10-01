if vim.fn.has("macunix") then
	vim.opt.clipboard = "unnamedplus"
end

if vim.fn.has("unix") then
	vim.opt.clipboard = "unnamed,unnamedplus"
end

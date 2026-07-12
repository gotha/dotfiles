-- markdown-preview.nvim settings.
--
-- Loaded from the plugin spec's `init` (lua/plugins/lazy.lua) rather than
-- `config`, because markdown-preview reads its g:mkdp_* variables when the
-- plugin loads, so they must be set beforehand.

vim.g.mkdp_filetypes = { "markdown" }

-- Keep the browser preview tab open when switching away from the markdown
-- buffer. Default is 1, which closes the tab as soon as the current buffer is
-- no longer the previewed markdown file; close it manually with
-- :MarkdownPreviewStop instead.
vim.g.mkdp_auto_close = 0

-- Stop the browser preview from scrolling in sync with the cursor in nvim.
vim.g.mkdp_preview_options = {
	disable_sync_scroll = 1,
}

-- Echo the preview URL in nvim as a fallback.
vim.g.mkdp_echo_preview_url = 1

-- Linux only: open the browser with a sanitized LD_LIBRARY_PATH. When nvim is
-- launched from a project dev shell (direnv / nix develop), that shell can leak
-- an LD_LIBRARY_PATH containing an older nss than Firefox needs; Firefox then
-- dies with "libnss3.so: version NSS_x not found / Couldn't load XPCOM" when the
-- preview server spawns it. Clearing LD_LIBRARY_PATH lets Firefox load its own
-- bundled libraries.
--
-- macOS has no LD_LIBRARY_PATH (it uses DYLD_*) and isn't affected, so there we
-- leave markdown-preview's default `open`-based browser launch untouched.
if vim.fn.has("linux") == 1 then
	function _G.MkdpOpen(url)
		vim.system({ "firefox", url }, { env = { LD_LIBRARY_PATH = "" } })
	end

	vim.cmd([[
function! MkdpOpenBrowser(url) abort
  call v:lua.MkdpOpen(a:url)
endfunction
]])

	vim.g.mkdp_browserfunc = "MkdpOpenBrowser"
end

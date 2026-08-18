-- Clipboard configuration
--
-- Let Neovim autodetect the provider. It already picks pbcopy/pbpaste on macOS,
-- wl-copy/wl-paste under Wayland, xclip/xsel under X11, and falls back to OSC 52
-- when there is genuinely no local clipboard (real SSH).
--
-- Do NOT branch on $SSH_TTY: tmux does not list it in update-environment, so a
-- tmux server first started over SSH leaks a stale SSH_TTY into every pane
-- forever, and local sessions get misdetected as remote.
vim.opt.clipboard = "unnamedplus"

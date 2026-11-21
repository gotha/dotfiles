-- Ported from ../sway/config.
--
-- hyprland 0.57 dropped hyprlang for Lua: it reads ~/.config/hypr/hyprland.lua
-- and nothing else, so there is no .conf here any more.
--
-- Device names are what `hyprctl devices` prints - lowercased, with spaces,
-- newlines and commas turned into '-' - not sway's vendor:product:name ids.

local mod   = "SUPER"
local term  = "{{TERMINAL}}"
-- -t toggles, so a second $mod+D closes it instead of reopening.
local menu  = "hyprlauncher -t"

-------------------------------------------------------------------------------
-- Plugins
-------------------------------------------------------------------------------
-- hy3 gives back sway's layout tree: tabbed groups, focus-parent, and real
-- splith/splitv. Without it the dwindle layout has no answer for $mod+w,
-- $mod+a or an explicit split direction.
--
-- Loaded first so `general.layout = "hy3"` below resolves.
hl.plugin.load("{{HY3}}")

-- hl.plugin.load only registers the path; the plugin is loaded after this file
-- has been evaluated. Hyprland then re-evaluates it (PluginSystem calls
-- Config::mgr()->reload() once a plugin loads), so this file runs twice: hy3 is
-- nil on the first pass and a table on the second.
--
-- Everything hy3 touches is therefore written with a native fallback. That is
-- not just for the first pass - if hy3 ever fails to load, the fallback is what
-- is left, and the session stays usable instead of losing focus and movement.
local hy3 = hl.plugin.hy3

-------------------------------------------------------------------------------
-- Monitors
-------------------------------------------------------------------------------
hl.monitor({ output = "", mode = "preferred", position = "auto", scale = 1 })

-------------------------------------------------------------------------------
-- Session + autostart
-------------------------------------------------------------------------------
-- Nothing starts graphical-session.target under plain hyprland, and the
-- hypridle unit hangs off it.
hl.on("hyprland.start", function()
    hl.exec_cmd("systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP HYPRLAND_INSTANCE_SIGNATURE")
    hl.exec_cmd("dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP HYPRLAND_INSTANCE_SIGNATURE")
    hl.exec_cmd("systemctl --user start hyprland-session.target")

    hl.exec_cmd("hyprpaper")
    -- Must be running before $mod+D or $mod+N are used. hyprlauncher only
    -- returns a dmenu selection on stdout when it talks to an existing
    -- instance: the client path prints it and exits, while a cold-started
    -- primary instance logs the pick at TRACE and prints nothing at all.
    hl.exec_cmd("hyprlauncher -d")
    -- the bar. `qs` with no arguments runs ~/.config/quickshell/shell.qml,
    -- which ../quickshell writes. This is where sway and the old
    -- hyprland.conf started waybar, which h4kbox no longer installs.
    hl.exec_cmd("qs")
    hl.exec_cmd("swayosd-server")
    hl.exec_cmd("{{POLKIT_AGENT}}")
    hl.exec_cmd("wl-clip-persist --clipboard regular")
    hl.exec_cmd("wl-paste --watch cliphist store")

    hl.exec_cmd("1password")
    hl.exec_cmd(term)
    hl.exec_cmd("firefox")
    hl.exec_cmd("slack")
    hl.exec_cmd("spotify")
    hl.exec_cmd("transmission-gtk")
end)

-------------------------------------------------------------------------------
-- Input
-------------------------------------------------------------------------------
hl.config({
    input = {
        kb_layout  = "us,bg",
        kb_options = "grp:win_space_toggle,caps:escape",

        repeat_delay = 250,
        repeat_rate  = 45,

        touchpad = {
            natural_scroll      = true,
            tap_to_click        = true,
            disable_while_typing = true,
        },
    },
})

-- keyd grabs the physical keyboards and replays them through this one, so
-- where keyd runs it is the only keyboard the compositor sees. altgr-intl
-- keeps Mod5 on AltGr for the dictation bind; no caps:escape, keyd already
-- does that at the evdev level.
hl.device({
    name       = "keyd-virtual-keyboard",
    kb_layout  = "us,bg",
    kb_variant = "altgr-intl,",
    kb_options = "grp:win_space_toggle",
})

-- sway spelled this 1452:834:Apple_Internal_Keyboard_/_Trackpad. It is the one
-- keyboard that toggles the layout on ALT+SPACE, not SUPER+SPACE: the built-in
-- mac keyboard has no key where SUPER is expected.
hl.device({
    name       = "apple-internal-keyboard-/-trackpad",
    kb_layout  = "us,bg",
    kb_options = "grp:alt_space_toggle,caps:escape",
})

hl.device({
    name       = "ducky-ducky-one2-sf-rgb",
    kb_layout  = "ducky-one-2sf,bg",
    kb_options = "grp:win_space_toggle,caps:escape",
})

-- The K6 Pro announces itself under either name depending on how it is paired
-- - bluetooth and the dongle disagree - so sway carried both and so does this.
hl.device({
    name       = "keychron-keychron-k6-pro",
    kb_layout  = "keychron-k6,bg",
    kb_options = "grp:win_space_toggle,caps:escape",
})

hl.device({
    name       = "keychron-k6-pro-keyboard",
    kb_layout  = "keychron-k6,bg",
    kb_options = "grp:win_space_toggle,caps:escape",
})

-------------------------------------------------------------------------------
-- Look
-------------------------------------------------------------------------------
hl.config({
    general = {
        gaps_in     = 4,
        gaps_out    = 8,
        border_size = 2,
        col = {
            active_border   = { colors = { "rgba(88c0d0ee)", "rgba(5e81acee)" }, angle = 45 },
            inactive_border = "rgba(2e3440aa)",
        },
        layout = hy3 and "hy3" or "dwindle",
    },

    decoration = {
        rounding = 8,
        blur   = { enabled = true, size = 6, passes = 2 },
        shadow = { enabled = true, range = 12, render_power = 3, color = "rgba(1a1a1aee)" },
    },

    animations = { enabled = true },

    misc = {
        disable_hyprland_logo   = true,
        disable_splash_rendering = true,
        force_default_wallpaper = 0,
    },
})

hl.curve("smooth", { type = "bezier", points = { { 0.05, 0.9 }, { 0.1, 1.0 } } })

hl.animation({ leaf = "windows",    enabled = true, speed = 5, bezier = "smooth",  style = "popin 80%" })
hl.animation({ leaf = "border",     enabled = true, speed = 8, bezier = "default" })
hl.animation({ leaf = "fade",       enabled = true, speed = 5, bezier = "default" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 4, bezier = "smooth",  style = "slide" })

-- hy3's tab bar. Defaults are bright purple; these follow the nord-ish borders
-- above so a tabbed group does not look like a different desktop. Only valid
-- once hy3 is loaded - on the first pass these keys do not exist yet.
if hy3 then
    hl.config({
        plugin = {
            hy3 = {
                tabs = {
                    height      = 22,
                    padding     = 4,
                    render_text = true,
                    text_center = true,
                    colors = {
                        active   = "rgba(88c0d0ff)",
                        inactive = "rgba(2e3440ff)",
                        urgent   = "rgba(bf616aff)",
                    },
                },
            },
        },
    })
end

hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_THEME", "rose-pine-hyprcursor")
hl.env("HYPRCURSOR_SIZE", "24")

-------------------------------------------------------------------------------
-- Window rules
-------------------------------------------------------------------------------
-- `class` is the app_id for wayland windows and WM_CLASS for xwayland ones;
-- `hyprctl clients` prints what a given window actually reports.
hl.window_rule({ name = "ws2-kitty",        match = { class = "^(kitty)$" },           workspace = "2" })
hl.window_rule({ name = "ws2-alacritty",    match = { class = "^(Alacritty)$" },       workspace = "2" })
hl.window_rule({ name = "ws3-slack",        match = { class = "^(Slack)$" },           workspace = "3" })
hl.window_rule({ name = "ws4-spotify",      match = { class = "^(Spotify)$" },         workspace = "4" })
hl.window_rule({ name = "ws4-1password",    match = { class = "^(1[Pp]assword)$" },    workspace = "4" })
hl.window_rule({ name = "ws4-transmission", match = { class = "^(transmission-gtk)$" }, workspace = "4" })
hl.window_rule({ name = "float-dictation",  match = { title = "^(Dictation)$" },       float = true })

-- The bar draws itself semi-transparent (see ../quickshell/shell.qml); without
-- blur behind it the wallpaper reads straight through as noise.
hl.layer_rule({ name = "blur-bar", match = { namespace = "^quickshell$" }, blur = true, ignore_alpha = 0.1 })

-------------------------------------------------------------------------------
-- Keys
-------------------------------------------------------------------------------
hl.bind(mod .. " + Return",      hl.dsp.exec_cmd(term))
hl.bind(mod .. " + D",           hl.dsp.exec_cmd(menu))
hl.bind(mod .. " + SHIFT + Q",   hy3 and hy3.kill_active() or hl.dsp.window.close())
hl.bind(mod .. " + SHIFT + C",   hl.dsp.reload_config())
hl.bind(mod .. " + SHIFT + E",   hl.dsp.exec_cmd("wlogout"))
hl.bind(mod .. " + F",           hl.dsp.window.fullscreen())
hl.bind(mod .. " + SHIFT + SPACE", hl.dsp.window.float({ action = "toggle" }))
hl.bind(mod .. " + P",           hl.dsp.exec_cmd("hyprshot -m region --clipboard-only"))
hl.bind(mod .. " + N",           hl.dsp.exec_cmd("cliphist list | hyprlauncher -m | cliphist decode | wl-copy"))

-- sway's splith / splitv / tabbed / "layout toggle split" / focus parent.
if hy3 then
    hl.bind(mod .. " + B", hy3.make_group("h"))
    hl.bind(mod .. " + V", hy3.make_group("v"))
    hl.bind(mod .. " + W", hy3.make_group("tab"))
    hl.bind(mod .. " + E", hy3.change_group("opposite"))
    hl.bind(mod .. " + A", hy3.change_focus("raise"))

    -- hy3 has tabbed groups but no stacking, so sway's $mod+s has no exact
    -- counterpart and is aliased onto tabbed rather than left dead. Drop this
    -- line if two keys doing the same thing is worse than losing the habit.
    hl.bind(mod .. " + S", hy3.make_group("tab"))
else
    -- dwindle: one toggle is all there is, and w/s/a have nowhere to go.
    hl.bind(mod .. " + B", hl.dsp.layout("togglesplit"))
    hl.bind(mod .. " + V", hl.dsp.layout("togglesplit"))
    hl.bind(mod .. " + E", hl.dsp.layout("togglesplit"))
end

-- SUPER+SPACE is deliberately unbound: xkb owns it for the layout toggle.
local dirs = { H = "l", J = "d", K = "u", L = "r",
               left = "l", down = "d", up = "u", right = "r" }
for key, dir in pairs(dirs) do
    hl.bind(mod .. " + " .. key,
        hy3 and hy3.move_focus(dir) or hl.dsp.focus({ direction = dir }))
    hl.bind(mod .. " + SHIFT + " .. key,
        hy3 and hy3.move_window(dir) or hl.dsp.window.move({ direction = dir }))
end

for i = 1, 10 do
    local key = i % 10 -- 10 maps to key 0
    hl.bind(mod .. " + " .. key,         hl.dsp.focus({ workspace = i }))
    -- via hy3, so sending a window away takes its tab group with it.
    hl.bind(mod .. " + SHIFT + " .. key,
        hy3 and hy3.move_to_workspace(tostring(i)) or hl.dsp.window.move({ workspace = i }))
end

-- sway's scratchpad
hl.bind(mod .. " + SHIFT + minus", hl.dsp.window.move({ workspace = "special:magic" }))
hl.bind(mod .. " + minus",         hl.dsp.workspace.toggle_special("magic"))

hl.bind(mod .. " + mouse:272", hl.dsp.window.drag(),   { mouse = true })
hl.bind(mod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

-------------------------------------------------------------------------------
-- Resize submap
-------------------------------------------------------------------------------
hl.bind(mod .. " + R", hl.dsp.submap("resize"))

hl.define_submap("resize", function()
    local steps = { H = { -10, 0 }, J = { 0, 10 }, K = { 0, -10 }, L = { 10, 0 },
                    left = { -10, 0 }, down = { 0, 10 }, up = { 0, -10 }, right = { 10, 0 } }
    for key, d in pairs(steps) do
        hl.bind(key, hl.dsp.window.resize({ x = d[1], y = d[2], relative = true }), { repeating = true })
    end

    hl.bind("Return", hl.dsp.submap("reset"))
    hl.bind("Escape", hl.dsp.submap("reset"))
end)

-------------------------------------------------------------------------------
-- Media
-------------------------------------------------------------------------------
-- swayosd draws the on-screen bar sway's config piped into a wob socket that
-- nothing ever read.
hl.bind("XF86AudioRaiseVolume",  hl.dsp.exec_cmd("swayosd-client --output-volume raise"), { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume",  hl.dsp.exec_cmd("swayosd-client --output-volume lower"), { locked = true, repeating = true })
hl.bind("XF86AudioMute",         hl.dsp.exec_cmd("swayosd-client --output-volume mute-toggle"), { locked = true })
hl.bind("XF86AudioMicMute",      hl.dsp.exec_cmd("swayosd-client --input-volume mute-toggle"),  { locked = true })
hl.bind("XF86MonBrightnessUp",   hl.dsp.exec_cmd("swayosd-client --brightness raise"), { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("swayosd-client --brightness lower"), { locked = true, repeating = true })
hl.bind("XF86AudioPlay",         hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioNext",         hl.dsp.exec_cmd("playerctl next"),       { locked = true })
hl.bind("XF86AudioPrev",         hl.dsp.exec_cmd("playerctl previous"),   { locked = true })

-- Dictation. code:31 is `i`: this is what sway spelled --to-code, and it is
-- needed because AltGr turns i into idiaeresis under altgr-intl.
hl.bind("MOD5 + code:31", hl.dsp.exec_cmd("dictate-hotkey"))

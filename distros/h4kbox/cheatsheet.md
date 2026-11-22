# h4kbox keyboard cheatsheet

hyprland with the [hy3](https://github.com/outfoxxed/hy3) layout, bound to match
sway/i3. Generated from `../../home-manager/hyprland/hyprland.lua` — if the two
ever disagree, the Lua wins.

**`$mod` is SUPER** (the Windows / Command key). **CapsLock is Escape** on every
keyboard.

## Launching and windows

| Keys | Does |
| --- | --- |
| `$mod + Return` | Terminal (kitty) |
| `$mod + D` | App launcher (hyprlauncher, toggles) |
| `$mod + N` | Clipboard history picker |
| `$mod + P` | Screenshot a region, straight to the clipboard |
| `$mod + Shift + Q` | Close the focused window |
| `$mod + F` | Fullscreen |
| `$mod + Shift + Space` | Toggle floating |
| `$mod + Shift + C` | Reload the hyprland config |
| `$mod + Shift + E` | Log out / power menu (wlogout) |
| `$mod + Shift + S` | Save the window layout now |
| `$mod + Shift + R` | Restore the saved layout |

## Moving around

| Keys | Does |
| --- | --- |
| `$mod + H/J/K/L` | Focus left / down / up / right |
| `$mod + ←/↓/↑/→` | Same, with arrows |
| `$mod + Shift + H/J/K/L` | Move the window left / down / up / right |
| `$mod + Shift + ←/↓/↑/→` | Same, with arrows |

## Layout — the i3 part

hy3 gives a real container tree, so these behave like sway rather than like
hyprland's default dwindle.

| Keys | Does |
| --- | --- |
| `$mod + B` | Split horizontal — next window opens to the right |
| `$mod + V` | Split vertical — next window opens below |
| `$mod + W` | Tab the current group (i3 "tabbed") |
| `$mod + S` | Also tabs — hy3 has no stacking layout, so this is an alias |
| `$mod + E` | Flip the group's split direction |
| `$mod + A` | Focus the parent container |

Inside a tabbed group, `$mod + H` / `$mod + L` move between tabs.

## Workspaces

| Keys | Does |
| --- | --- |
| `$mod + 1`…`9`, `0` | Go to workspace 1–10 |
| `$mod + Shift + 1`…`9`, `0` | Send the window there (takes its tab group along) |
| `$mod + minus` | Show / hide the scratchpad |
| `$mod + Shift + minus` | Throw the window into the scratchpad |

Some apps are pinned to a workspace on launch: terminals → **2**, Slack → **3**,
Spotify, 1Password and Transmission → **4**.

## Resizing

`$mod + R` enters resize mode, then:

| Keys | Does |
| --- | --- |
| `H/J/K/L` or arrows | Resize (hold to repeat) |
| `Return` or `Escape` | Leave resize mode |

Or skip the mode: `$mod + right-drag` resizes, `$mod + left-drag` moves.

## Keyboard layout (US ⇄ Bulgarian)

| Keys | Where |
| --- | --- |
| `SUPER + Space` | Every keyboard except the MacBook's built-in one |
| `Alt + Space` | The MacBook's built-in keyboard, which has no SUPER where you'd expect |

This is why `SUPER + Space` is deliberately *not* bound to anything in hyprland —
xkb owns it.

## Media and misc

| Keys | Does |
| --- | --- |
| Volume up / down / mute | Output volume, with an on-screen bar |
| Mic mute | Input mute |
| Brightness up / down | Screen brightness |
| Play / Next / Previous | Whatever is playing (playerctl) |
| `AltGr + I` | Dictation — speaks to text, result lands on the clipboard |

Media keys work while the screen is locked.

## Session restore

Nothing is autostarted by name any more. On login, `hypr-layout` reopens the
windows that were open when it last saved — one process per window, so three
terminals on three workspaces come back as three.

A snapshot is taken every two minutes by a systemd user timer, and `$mod +
Shift + S` takes one immediately. The window arrangement inside a workspace is
*not* restored: hypr-layout rebuilds tiling for dwindle and for hyprland's
native groups, and hy3 uses neither, so the replay runs with `--no-arrange
--no-groups`.

| Command | Does |
| --- | --- |
| `hypr-layout show` | Print what is saved |
| `hypr-layout restore --dry-run` | Say what a restore would do, change nothing |
| `hypr-layout layouts` | List saved layouts and how many older saves exist |
| `hypr-layout save --name work` | Keep a second, named layout |
| `hypr-layout restore --history` | Go back to an earlier save |

Saves live in `~/.config/hypr/layout.json`, older ones in
`~/.config/hypr/layout-history/`.

## When something breaks

- **Picked Hyprland at the greeter and bounced back to it?** Pick **sway** instead
  — it is kept installed exactly for this — then look at
  `~/.cache/hyprland/hyprlandCrashReport*.txt` and `journalctl -b -u greetd`.
- **Tabs and `$mod + W` do nothing, windows tile oddly?** hy3 did not load. Check
  `hyprctl plugin list` for it and `hyprctl getoption general:layout`, which
  should say `hy3` and not `dwindle`. The config falls back to hyprland's own
  dispatchers on purpose, so focus and movement keep working either way.
- **No bar?** `pgrep -a quickshell`; start it with `qs` if it died.
- **`$mod + N` pastes nothing?** The hyprlauncher daemon is not running — it only
  returns a dmenu selection when talking to an existing instance. Check
  `pgrep -a hyprlauncher`.
- **Config errors?** `hyprctl configerrors` — empty means clean.

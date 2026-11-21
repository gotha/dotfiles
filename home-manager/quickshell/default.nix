{ pkgs, ... }:
let
  # The glyph font sketchybar uses on the mac: ligatures, so the literal text
  # ":firefox:" renders as the Firefox mark. Ships for linux too, as a plain
  # ttf plus the name->ligature table below.
  appFont = pkgs.sketchybar-app-font;

  # That table is distributed as lua and as a bash case statement, neither of
  # which QML can read. Turn it into a JS module once, at build time, instead
  # of shelling out per window the way ../sketchybar/plugins/aerospace.sh has
  # to. `import "icon_map.js"` resolves next to shell.qml, so both land in the
  # same directory below.
  iconMap =
    pkgs.runCommand "quickshell-icon-map.js"
      {
        nativeBuildInputs = [ pkgs.python3 ];
        src = "${appFont}/lib/sketchybar-app-font/icon_map.lua";
      }
      ''
        python3 - "$src" "$out" <<'PY'
        import json, re, sys

        src = open(sys.argv[1], encoding="utf-8").read()
        # entries look like:  [ [[Activity Monitor]] ] = ":activity_monitor:",
        pairs = re.findall(r"\[ \[\[(.*?)\]\] \] = \"(.*?)\",", src)
        if len(pairs) < 500:
            raise SystemExit(f"icon_map.lua parsed to only {len(pairs)} entries - format changed?")

        table = dict(pairs)
        # hyprland reports window classes, not mac app names: "firefox", not
        # "Firefox". Index lowercased so the lookup can be case-insensitive
        # without rebuilding this on every repaint.
        lower = {k.lower(): v for k, v in table.items()}

        with open(sys.argv[2], "w", encoding="utf-8") as f:
            f.write(".pragma library\n\n")
            f.write("var byName = " + json.dumps(table, ensure_ascii=False, sort_keys=True) + ";\n\n")
            f.write("var byLowerName = " + json.dumps(lower, ensure_ascii=False, sort_keys=True) + ";\n\n")
            f.write('var fallback = ":default:";\n')
        PY
      '';
in
{

  home.packages = with pkgs; [
    pavucontrol # the volume readout's click target
    playerctl # ../hyprland/hyprland.lua binds the media keys to it
    quickshell
    appFont # must be in the profile, or fontconfig cannot find the glyphs
  ];

  # `qs` with no arguments runs ~/.config/quickshell/shell.qml.
  xdg.configFile = {
    "quickshell/shell.qml".source = ./shell.qml;
    "quickshell/icon_map.js".source = iconMap;
  };
}

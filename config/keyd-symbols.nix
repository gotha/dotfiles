# Programming symbol layer for keyd.
#
# Hold Space to activate the `[symbols]` layer; tap Space for a normal space.
# `overloadt2` resolves as the layer the moment another key is tapped while
# Space is held, so symbol entry stays snappy, while a quick lone Space tap
# still emits a space.
#
# Layout while Space is held:
#
#   Q W E R T   Y U I O P      ! @ # $ %   ^ & * ( )   top  = shifted number row
#   A S D F G   H J K L ;      < { [ ( _   = ) ] } >   home = brackets, mirrored
#   Z X C V B   N M , . /      ` ~ " ' |   + - * / \   bot  = quotes + arithmetic
#
# Brackets are mirrored: the left hand opens, the same finger on the right
# closes (index = parens, middle = square, ring = curly, pinky = angle).
#
# If fast typing across word boundaries produces stray symbols, change
# `overloadt2` below to `overloadt` — bulletproof against rolls, at the cost of
# a little latency on the first symbol of each hold.
{
  # Merged into each keyboard's [main] layer.
  mainSpace = "overloadt2(symbols, space, 200)";

  # Extra keyd sections, merged into every keyboard's `settings` with `//`.
  extraSections = {
    # Modifier layers: keep Space usable as part of a chord. Without these the
    # [main] Space overload swallows Space whenever a modifier is held, which
    # breaks Super+Space / Alt+Space (the sway `grp:*_space_toggle` xkb layout
    # switch) and Ctrl+Space (e.g. editor autocomplete). Holding a modifier
    # activates keyd's built-in eponymous layer, so we just re-emit a modified
    # Space there instead of entering the symbol layer.
    meta.space = "M-space";
    alt.space = "A-space";
    control.space = "C-space";

    # The [symbols] layer itself. Non-alpha keys use keyd key names (semicolon,
    # comma, dot, slash) per the NixOS keyd module guidance.
    symbols = {
      # top row -> shifted number row: ! @ # $ % ^ & * ( )
      q = "!";
      w = "@";
      e = "#";
      r = "$";
      t = "%";
      y = "^";
      u = "&";
      i = "*";
      o = "(";
      p = ")";

      # home row -> brackets (open left / close right, mirrored) + _ =
      a = "<";
      s = "{";
      d = "[";
      f = "(";
      g = "_";
      h = "=";
      j = ")";
      k = "]";
      l = "}";
      semicolon = ">";

      # bottom row -> quotes, pipe, arithmetic, backslash
      z = "`";
      x = "~";
      c = "\"";
      v = "'";
      b = "|";
      n = "+";
      m = "-";
      comma = "*";
      dot = "/";
      slash = "\\";
    };
  };
}

{
  lib,
  pkgs,
  ...
}:
let
  # US-keyboard character -> the key (and whether Shift is required) that
  # produces it. Used to translate the `layer` mapping below into Karabiner
  # `to` events.
  charToKey = {
    "!" = {
      key_code = "1";
      shift = true;
    };
    "@" = {
      key_code = "2";
      shift = true;
    };
    "#" = {
      key_code = "3";
      shift = true;
    };
    "$" = {
      key_code = "4";
      shift = true;
    };
    "%" = {
      key_code = "5";
      shift = true;
    };
    "^" = {
      key_code = "6";
      shift = true;
    };
    "&" = {
      key_code = "7";
      shift = true;
    };
    "*" = {
      key_code = "8";
      shift = true;
    };
    "(" = {
      key_code = "9";
      shift = true;
    };
    ")" = {
      key_code = "0";
      shift = true;
    };
    "<" = {
      key_code = "comma";
      shift = true;
    };
    ">" = {
      key_code = "period";
      shift = true;
    };
    "{" = {
      key_code = "open_bracket";
      shift = true;
    };
    "}" = {
      key_code = "close_bracket";
      shift = true;
    };
    "[" = {
      key_code = "open_bracket";
    };
    "]" = {
      key_code = "close_bracket";
    };
    "_" = {
      key_code = "hyphen";
      shift = true;
    };
    "-" = {
      key_code = "hyphen";
    };
    "=" = {
      key_code = "equal_sign";
    };
    "+" = {
      key_code = "equal_sign";
      shift = true;
    };
    "`" = {
      key_code = "grave_accent_and_tilde";
    };
    "~" = {
      key_code = "grave_accent_and_tilde";
      shift = true;
    };
    "\"" = {
      key_code = "quote";
      shift = true;
    };
    "'" = {
      key_code = "quote";
    };
    "|" = {
      key_code = "backslash";
      shift = true;
    };
    "\\" = {
      key_code = "backslash";
    };
    "/" = {
      key_code = "slash";
    };
  };

  # Space layer: while Space is held, each physical key (given as its Karabiner
  # key_code) emits the mapped character instead of its normal letter.
  layer = {
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

    # home row -> brackets (mirrored open/close) + _ = and < >
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

    # bottom row -> backtick/tilde, quotes, pipe, arithmetic, slashes
    z = "`";
    x = "~";
    c = "\"";
    v = "'";
    b = "|";
    n = "+";
    m = "-";
    comma = "*";
    period = "/";
    slash = "\\";
  };

  # Turn a target character into a Karabiner `to` event.
  toChar =
    char:
    let
      k = charToKey.${char};
    in
    {
      key_code = k.key_code;
    }
    // lib.optionalAttrs (k.shift or false) { modifiers = [ "left_shift" ]; };

  # One manipulator per layer key, gated on the `space_layer` variable.
  layerManipulators = lib.mapAttrsToList (fromKey: char: {
    type = "basic";
    from = {
      key_code = fromKey;
      modifiers.optional = [ "any" ];
    };
    to = [ (toChar char) ];
    conditions = [
      {
        type = "variable_if";
        name = "space_layer";
        value = 1;
      }
    ];
  }) layer;

  # Hold Space -> activate the layer; tap Space -> ordinary space.
  spaceLayerToggle = {
    type = "basic";
    from = {
      key_code = "spacebar";
      modifiers.optional = [ "any" ];
    };
    to = [
      {
        set_variable = {
          name = "space_layer";
          value = 1;
        };
      }
    ];
    to_after_key_up = [
      {
        set_variable = {
          name = "space_layer";
          value = 0;
        };
      }
    ];
    to_if_alone = [ { key_code = "spacebar"; } ];
  };
in
{
  config = lib.mkIf pkgs.stdenv.isDarwin {
    # Karabiner-Elements itself is installed via the Homebrew cask in
    # os/darwin/homebrew.nix (it needs a system DriverKit extension + daemon
    # that the nixpkgs package cannot fully provide on Darwin). We only manage
    # its configuration file here.

    # Karabiner-Elements configuration
    home.file.".config/karabiner/karabiner.json".text = builtins.toJSON {
      profiles = [
        {
          name = "Default";
          selected = true;
          complex_modifications = {
            rules = [
              # Disable cmd+h (hide window)
              {
                description = "Disable cmd+h";
                manipulators = [
                  {
                    type = "basic";
                    from = {
                      key_code = "h";
                      modifiers = {
                        mandatory = [ "command" ];
                        optional = [ "any" ];
                      };
                    };
                    to = [ ];
                  }
                ];
              }
              # Disable cmd+tab (app switcher)
              {
                description = "Disable cmd+tab";
                manipulators = [
                  {
                    type = "basic";
                    from = {
                      key_code = "tab";
                      modifiers = {
                        mandatory = [ "command" ];
                        optional = [ "any" ];
                      };
                    };
                    to = [ ];
                  }
                ];
              }
              # Caps Lock: tap = Escape, hold = Control
              {
                description = "Caps Lock to Escape (tap) / Control (hold)";
                manipulators = [
                  {
                    type = "basic";
                    from = {
                      key_code = "caps_lock";
                      modifiers = {
                        optional = [ "any" ];
                      };
                    };
                    to = [ { key_code = "left_control"; } ];
                    to_if_alone = [ { key_code = "escape"; } ];
                  }
                ];
              }
              # Space layer: hold Space to type special characters
              {
                description = "Space layer: hold Space for special characters";
                manipulators = [ spaceLayerToggle ] ++ layerManipulators;
              }
            ];
          };
          simple_modifications = [
            # Swap Control and Globe (Fn) keys globally
            {
              from = {
                key_code = "left_control";
              };
              to = [ { apple_vendor_top_case_key_code = "keyboard_fn"; } ];
            }
            {
              from = {
                apple_vendor_top_case_key_code = "keyboard_fn";
              };
              to = [ { key_code = "left_control"; } ];
            }
          ];
          virtual_hid_keyboard = {
            keyboard_type_v2 = "ansi";
          };
        }
      ];
      global = {
        show_in_menu_bar = true;
      };
    };
  };
}

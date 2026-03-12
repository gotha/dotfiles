{
  config,
  lib,
  pkgs,
  ...
}:
let
  mpc = "${pkgs.mpc}/bin/mpc";
in
{
  config = lib.mkIf pkgs.stdenv.isDarwin {
    home.packages = [ pkgs.karabiner-elements ];

    # Karabiner-Elements configuration
    home.file.".config/karabiner/karabiner.json".text = builtins.toJSON {
      profiles = [
        {
          name = "Default";
          selected = true;
          complex_modifications = {
            rules = [
              # MPD Media Key Controls (using F7/F8/F9 function keys)
              # Press physical Control + F7/F8/F9 (since Fn/Control are swapped)
              {
                description = "F8 controls MPD play/pause";
                manipulators = [
                  {
                    type = "basic";
                    from = {
                      key_code = "f8";
                      modifiers = {
                        optional = [ "any" ];
                      };
                    };
                    to = [
                      { shell_command = "/bin/sh -c '${mpc} toggle'"; }
                    ];
                  }
                ];
              }
              {
                description = "F9 controls MPD next track";
                manipulators = [
                  {
                    type = "basic";
                    from = {
                      key_code = "f9";
                      modifiers = {
                        optional = [ "any" ];
                      };
                    };
                    to = [
                      { shell_command = "/bin/sh -c '${mpc} next'"; }
                    ];
                  }
                ];
              }
              {
                description = "F7 controls MPD previous track";
                manipulators = [
                  {
                    type = "basic";
                    from = {
                      key_code = "f7";
                      modifiers = {
                        optional = [ "any" ];
                      };
                    };
                    to = [
                      { shell_command = "/bin/sh -c '${mpc} prev'"; }
                    ];
                  }
                ];
              }
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
            ];
          };
          simple_modifications = [
            # Caps Lock to Escape
            {
              from = {
                key_code = "caps_lock";
              };
              to = [ { key_code = "escape"; } ];
            }
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

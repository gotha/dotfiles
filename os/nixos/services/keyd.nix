# keyd: caps lock as control/escape on every keyboard, and - when the symbol
# layer is on - the hold-Space programming layer from ../../../config.
#
# The toggle is declared in ../../linux/keyd-symbols.nix, imported here so this
# module stands on its own. Importing it twice is free; the module system keys
# on the path.
{ config, lib, ... }:
let
  keydSymbols = import ../../../config/keyd-symbols.nix;
  symbolLayer = config.services.keyd.custom.symbolLayer.enable;
in
{
  imports = [ ../../linux/keyd-symbols.nix ];

  services.keyd = {
    enable = true;
    keyboards.default = {
      ids = [ "*" ];
      settings = {
        main = {
          capslock = "overload(control, esc)";
        }
        // lib.optionalAttrs symbolLayer { space = keydSymbols.mainSpace; };
      }
      // lib.optionalAttrs symbolLayer keydSymbols.extraSections;
    };
  };
}

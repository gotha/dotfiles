# Toggle for the keyd programming symbol layer.
#
# The layer content lives in config/keyd-symbols.nix; the per-keyboard keyd
# configs (distros/devbox, hosts/*) merge it in only when this option is on.
{ lib, ... }:
{
  options.services.keyd.custom.symbolLayer.enable = lib.mkOption {
    type = lib.types.bool;
    default = true;
    description = ''
      Whether to add the hold-Space programming symbol layer — and the
      modifier passthroughs that keep chords like Super+Space (xkb layout
      toggle) working — to every keyd keyboard. When disabled, keyboards keep
      only their base keyd config (no `[symbols]` layer, no Space overload).
    '';
  };
}

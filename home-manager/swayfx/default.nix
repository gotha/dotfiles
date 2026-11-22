# sway with the eyecandy switched on.
#
# swayfx is sway 1.12 plus rounded corners, blur, shadows and animations. It
# reads the same config and speaks the same IPC, so this module is ../sway with
# two things changed: the package, and a block appended to its config.
{ pkgs, ... }:
{
  imports = [ ../sway ];

  programs.sway.custom = {
    package = pkgs.swayfx;
    extraConfig = builtins.readFile ./eyecandy.conf;
  };
}

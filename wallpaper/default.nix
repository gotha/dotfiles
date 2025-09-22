{ stdenvNoCC }:
stdenvNoCC.mkDerivation {
  pname = "wallpaper";
  version = "1.0";
  src = ./data;
  dontBuild = true;
  installPhase = ''
    mkdir -p "$out"
    cp -av . "$out/"
  '';
  meta.description = "my wallpapers";
}

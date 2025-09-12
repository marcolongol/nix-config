final: prev: let
  overlayFiles =
    builtins.filter
    (name: name != "default.nix" && builtins.match ".*\\.nix$" name != null)
    (builtins.attrNames (builtins.readDir ./.));
in
  builtins.foldl' (acc: file: acc // (import (./. + "/${file}") final prev)) {} overlayFiles

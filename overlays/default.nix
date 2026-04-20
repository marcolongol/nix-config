lib: final: prev: let
  overlayFiles =
    builtins.filter
    (name: name != "default.nix" && builtins.match ".*\\.nix$" name != null)
    (builtins.attrNames (builtins.readDir ./.));

  overlayAttrs = builtins.foldl' (acc: file: acc // (import (./. + "/${file}") final prev)) {} overlayFiles;

  packageAttrs =
    builtins.removeAttrs
    (lib.forAllNixFiles ../packages (path: final.callPackage path {}))
    ["default"];
in
  packageAttrs // overlayAttrs

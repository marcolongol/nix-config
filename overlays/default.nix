# List of overlays: every other .nix here, plus ../packages exposed as pkgs.<name>.
[
  (final: prev: let
    # prev.lib, not final.lib: attr names computed from final recurse forever.
    inherit (prev) lib;
    nixFiles = dir:
      lib.filterAttrs (n: t: t == "regular" && lib.hasSuffix ".nix" n && n != "default.nix") (builtins.readDir dir);
    packages =
      lib.mapAttrs' (n: _: lib.nameValuePair (lib.removeSuffix ".nix" n) (final.callPackage (../packages + "/${n}") {}))
      (nixFiles ../packages);
    overlayAttrs = builtins.foldl' (acc: n: acc // import (./. + "/${n}") final prev) {} (builtins.attrNames (nixFiles ./.));
  in
    packages // overlayAttrs)
]

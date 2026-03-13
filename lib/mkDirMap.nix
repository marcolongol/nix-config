final: _: {
  # Map an attribute set to a list, applying a function to each attribute,
  # filtering out null values and converting back to an attribute set
  mapAttrsMaybe = f: attrs:
    final.pipe attrs [
      (final.mapAttrsToList f)
      (builtins.filter (x: x != null))
      builtins.listToAttrs
    ];

  # Apply a function to all .nix files in a directory, returning an attribute set.
  # Handles both plain .nix files and subdirectories containing a default.nix.
  forAllNixFiles = dir: f:
    if builtins.pathExists dir
    then
      final.pipe dir [
        builtins.readDir
        (final.mapAttrsMaybe (
          fn: type:
            if type == "regular"
            then final.nameValuePair (final.removeSuffix ".nix" fn) (f "${dir}/${fn}")
            else if type == "directory" && builtins.pathExists "${dir}/${fn}/default.nix"
            then final.nameValuePair fn (f "${dir}/${fn}")
            else null
        ))
      ]
    else {};

  # Recursively map all .nix files in a set of directories,
  # returning an attribute set of attribute sets (dir name → file name → path)
  mkDirMap = final.mapAttrs (_: dir: final.forAllNixFiles dir (fn: fn));
}

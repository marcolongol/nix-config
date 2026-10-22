final: _: {
  # Map attrs to a list via f, dropping nulls, back to an attrset.
  mapAttrsMaybe = f: attrs:
    final.pipe attrs [
      (final.mapAttrsToList f)
      (builtins.filter (x: x != null))
      builtins.listToAttrs
    ];

  # Apply f to every .nix file (or dir with default.nix) in a directory.
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

  # mkDirMap over several directories: dir name -> file name -> path.
  mkDirMap = final.mapAttrs (_: dir: final.forAllNixFiles dir (fn: fn));
}

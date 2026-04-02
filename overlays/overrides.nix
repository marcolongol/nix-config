final: prev: {
  # Package overrides go here
  freecad = prev.freecad.overrideAttrs (old: {
    buildInputs =
      map (
        dep:
          if dep.pname or "" == "boost"
          then prev.boost186
          else dep
      )
      old.buildInputs;
  });
}

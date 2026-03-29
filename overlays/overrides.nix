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
  github-copilot-cli = prev.github-copilot-cli.overrideAttrs (_old: {
    postInstall = ''
      # Workaround for https://github.com/github/copilot-cli/issues/1446
      # wrapProgram renames the binary, but it checks its own name and breaks.
      # Use makeWrapper (no rename) instead, preserving the filename "copilot".
      mkdir -p $out/libexec
      mv $out/bin/copilot $out/libexec/copilot
      makeWrapper $out/libexec/copilot $out/bin/copilot \
        --argv0 copilot \
        --prefix PATH : ${prev.bashInteractive}/bin \
        --add-flags "--no-auto-update"
    '';
  });
}

{
  config,
  lib,
  pkgs,
  ...
}: {
  imports = [../session-path.nix];

  options.lang.go.enable = lib.mkEnableOption "Go toolchain";

  config = lib.mkIf config.lang.go.enable {
    programs.go = {
      enable = true;
      env.GOPATH = "${config.home.homeDirectory}/.local/share/go";
      telemetry.mode = "off";
    };

    home.packages = with pkgs; [
      gopls # LSP server
      delve # debugger (dlv)
      (lib.lowPrio gotools) # goimports, etc.; lowPrio so sox wins `play` collision
      go-tools # staticcheck
      golangci-lint # meta-linter
      gomodifytags
      gotests
      impl
    ];

    home.sessionPathAppend = ["${config.home.homeDirectory}/.local/share/go/bin"];

    omninix.persistence.directories = [
      ".local/share/go" # GOPATH: modules, installed bins
      ".cache/go-build" # build cache
    ];
  };
}

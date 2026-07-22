{
  config,
  lib,
  pkgs,
  ...
}: lib.mkIf config.profiles.developer.enable {
  home.packages = with pkgs; [
    go
    gopls # LSP server
    delve # debugger (dlv)
    (lib.lowPrio gotools) # goimports, etc.; lowPrio so sox wins `play` collision
    go-tools # staticcheck
    golangci-lint # meta-linter
    gomodifytags
    gotests
    impl
  ];

  home.sessionVariables = {
    GOPATH = "${config.home.homeDirectory}/.local/share/go";
    GOTELEMETRY = "off";
  };

  home.sessionPath = ["${config.home.homeDirectory}/.local/share/go/bin"];

  persistentFolders = [
    ".local/share/go" # GOPATH: modules, installed bins
    ".cache/go-build" # build cache
  ];
}

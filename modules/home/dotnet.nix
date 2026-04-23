{
  config,
  lib,
  pkgs,
  ...
}: lib.mkIf config.profiles.developer.enable {
  home.packages = with pkgs.dotnetCorePackages; [
    sdk_9_0
  ];

  home.sessionVariables = {
    DOTNET_CLI_TELEMETRY_OPTOUT = "1";
    DOTNET_NOLOGO = "1";
  };

  persistentFolders = [
    ".nuget"
    ".dotnet"
    ".local/share/NuGet"
  ];
}

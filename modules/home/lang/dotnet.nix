{
  config,
  lib,
  pkgs,
  ...
}: {
  options.lang.dotnet.enable = lib.mkEnableOption ".NET SDK";

  config = lib.mkIf config.lang.dotnet.enable {
    home.packages = with pkgs.dotnetCorePackages; [
      sdk_10_0
    ];

    home.sessionVariables = {
      DOTNET_CLI_TELEMETRY_OPTOUT = "1";
      DOTNET_NOLOGO = "1";
    };

    omninix.persistence.directories = [
      ".nuget"
      ".dotnet"
      ".local/share/NuGet"
    ];
  };
}

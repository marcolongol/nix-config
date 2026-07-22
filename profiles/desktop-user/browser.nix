{
  config,
  lib,
  pkgs,
  ...
}:
lib.mkIf config.profiles.desktopUser.enable {
  programs.zen-browser = {
    enable = true;
    profiles.default = {};
    nativeMessagingHosts = [pkgs.firefoxpwa];
    policies = let
      mkExtensionSettings = builtins.mapAttrs (_: pluginId: {
        install_url = "https://addons.mozilla.org/firefox/downloads/latest/${pluginId}/latest.xpi";
        installation_mode = "force_installed";
      });
    in {
      ExtensionSettings = mkExtensionSettings {
        "{d7742d87-e61d-4b78-b8a1-b469842139fa}" = "vimium-ff";
      };
      Homepage = {
        URL = "https://homepage.marcolongo.dev";
        Locked = true;
        StartPage = "homepage";
      };
    };
  };

  stylix.targets.zen-browser.profileNames = ["default"];

  xdg.mimeApps.enable = true;
  xdg.mimeApps.defaultApplications = {
    "text/html" = "zen-beta.desktop";
    "text/xml" = "zen-beta.desktop";
    "application/xhtml+xml" = "zen-beta.desktop";
    "application/vnd.mozilla.xul+xml" = "zen-beta.desktop";
    "x-scheme-handler/http" = "zen-beta.desktop";
    "x-scheme-handler/https" = "zen-beta.desktop";
  };

  persistentFolders = [
    ".config/zen"
  ];
}

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
        "{d7742d87-e61d-4b78-b8a1-b469842139fa}" = "vimium";
      };
    };
  };

  stylix.targets.zen-browser.profileNames = ["default"];

  xdg.mimeApps.defaultApplications = {
    "text/html" = "zen-browser.desktop";
    "text/xml" = "zen-browser.desktop";
    "application/xhtml+xml" = "zen-browser.desktop";
    "application/vnd.mozilla.xul+xml" = "zen-browser.desktop";
    "x-scheme-handler/http" = "zen-browser.desktop";
    "x-scheme-handler/https" = "zen-browser.desktop";
  };

  persistentFolders = [
    ".config/zen"
  ];
}

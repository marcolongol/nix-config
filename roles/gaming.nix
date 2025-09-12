{
  config,
  lib,
  pkgs,
  ...
}:
lib.mkIf (lib.elem "gaming" config.roles) {
  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;
    dedicatedServer.openFirewall = true;
    localNetworkGameTransfers.openFirewall = true;
    gamescopeSession.enable = true;
    protontricks.enable = true;

    extraCompatPackages = with pkgs; [
      proton-ge-bin
    ];
  };

  programs.gamemode = {
    enable = true;
    settings = {
      general = {
        renice = 10;
        ioprio = 7;
        inhibit_screensaver = 1;
        desiredgov = "performance";
        defaultgov = "powersave";
      };
      gpu = {
        apply_gpu_optimisations = "accept-responsibility";
        gpu_device = 0;
        amd_performance_level = "high";
      };
      custom = {
        start = "${pkgs.libnotify}/bin/notify-send 'GameMode started'";
        end = "${pkgs.libnotify}/bin/notify-send 'GameMode ended'";
      };
    };
  };

  # SystemD user service limits (systemd ignores PAM limits by design)
  systemd.user.extraConfig = ''
    DefaultLimitNOFILE=2097152:2097152
  '';
}

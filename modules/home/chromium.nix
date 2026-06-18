{
  config,
  lib,
  ...
}:
lib.mkIf config.profiles.desktopUser.enable {
  programs.chromium = {
    enable = true;
    commandLineArgs = [
      "--no-first-run"
      "--no-default-browser-check"
    ];
  };

  # Systemd user service to run Chromium in background with DevTools enabled
  systemd.user.services.chromium-devtools = {
    Unit = {
      Description = "Chromium with DevTools Protocol";
      After = ["graphical-session-pre.target"];
      PartOf = ["graphical-session.target"];
    };

    Service = {
      Type = "simple";
      # Run Chromium in headless mode with remote debugging enabled
      ExecStart = "${config.programs.chromium.finalPackage}/bin/chromium --headless --disable-gpu --remote-debugging-port=9222";
      Restart = "on-failure";
      RestartSec = 5;
      # Allow time for startup
      StartLimitInterval = 200;
      StartLimitBurst = 5;
    };

    Install = {
      WantedBy = ["graphical-session.target"];
    };
  };

  # Persist Chromium cache and config
  persistentFolders = [
    ".cache/chromium"
    ".config/chromium"
  ];
}

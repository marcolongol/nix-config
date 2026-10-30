{
  config,
  lib,
  ...
}: {
  programs.chromium = {
    enable = true;
    commandLineArgs = [
      "--no-first-run"
      "--no-default-browser-check"
    ];
  };

  systemd.user.services.chromium-devtools = {
    Unit = {
      Description = "Chromium with DevTools Protocol";
      After = ["graphical-session-pre.target"];
      PartOf = ["graphical-session.target"];
    };

    Service = {
      Type = "simple";
      ExecStart = "${config.programs.chromium.finalPackage}/bin/chromium --headless --disable-gpu --remote-debugging-port=9222";
      Restart = "on-failure";
      RestartSec = 5;
      StartLimitInterval = 200;
      StartLimitBurst = 5;
    };

    Install = {
      WantedBy = ["graphical-session.target"];
    };
  };

  persistentFolders = [
    ".cache/chromium"
    ".config/chromium"
  ];
}

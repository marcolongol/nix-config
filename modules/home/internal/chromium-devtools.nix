# Headless chromium with the DevTools Protocol on 127.0.0.1:9222, for local
# agent tooling (chrome-devtools MCP). Any local process can drive it, so it
# stays in this flake. Only where chromium itself is enabled (desktop role).
{
  config,
  lib,
  ...
}: {
  config = lib.mkIf config.programs.chromium.enable {
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
  };
}

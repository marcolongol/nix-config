{
  config,
  lib,
  ...
}: {
  # GPG-smartcard sops needs a PIN prompt, which only exists once the graphical session is up.
  systemd.user.services.sops-nix = lib.mkIf (config.sops.gnupg.home != null) {
    Unit.After = ["graphical-session.target"];
    Install.WantedBy = lib.mkForce ["graphical-session.target"];
  };
}

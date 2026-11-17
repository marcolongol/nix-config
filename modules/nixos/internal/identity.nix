{
  config,
  inputs,
  lib,
  ...
}: {
  # Gated on active users: wsl keeps its upstream defaults.
  config = lib.mkIf (config.omninix.activeUsers != []) {
    users.users = lib.genAttrs config.omninix.activeUsers (userName: {
      openssh.authorizedKeys.keys = let
        pubkeysPath = inputs.self + "/users/${userName}/pubkeys.nix";
      in
        lib.optionals (builtins.pathExists pubkeysPath)
        [(import pubkeysPath).ssh.publicKey];
    });

    # GPG auth subkey on YubiKey via pam_ssh_agent_auth, checked against authorized_keys.d; password is fallback.
    security.pam.sshAgentAuth.enable = true;

    security.pam.services = {
      login.sshAgentAuth = true;
      sudo.sshAgentAuth = true;
      hyprlock.sshAgentAuth = true;
      sddm.sshAgentAuth = true;
    };

    # sudo must run PAM for the touch-to-auth path; roles/common.nix asserts this.
    security.sudo.wheelNeedsPassword = true;
  };
}

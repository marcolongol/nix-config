# Third-party Home Manager modules for every user. Role-specific ones stay with
# their role (zen-browser in roles/desktop/home/browser.nix).
{inputs, ...}: {
  imports = [inputs.nixievim.homeManagerModules.default];
}

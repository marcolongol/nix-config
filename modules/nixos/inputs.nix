# Third-party NixOS modules for every host. Impermanence stays unconditional: the
# omninix HM bridge needs home.persistence, and a skipped import on a wiped root
# loses the host keys sops decrypts with.
{inputs, ...}: {
  imports = [
    inputs.disko.nixosModules.disko
    inputs.impermanence.nixosModules.impermanence
    inputs.stylix.nixosModules.stylix
    inputs.comin.nixosModules.comin
    inputs.nix-index-database.nixosModules.nix-index
  ];
}

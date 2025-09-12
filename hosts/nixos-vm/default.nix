{
  system.stateVersion = "25.11";

  # Example host configuration
  roles = ["common" "nfs-client" "desktop"];
  hostUsers = ["lucas"];

  services.qemuGuest.enable = true;
}

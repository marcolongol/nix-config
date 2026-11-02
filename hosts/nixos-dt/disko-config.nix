# disko configuration for nixos-dt
# Dual-boot with Windows 11. Only nvme0n1p3 is managed here —
# the GPT and Windows partitions are never touched.
#
# Run during install with:
#   sudo disko --mode disko /root/nix-config/hosts/nixos-dt/disko-config.nix
{lib, ...}: {
  disko.devices = {
    disk.nixos-dt = {
      type = "disk";
      device = "/dev/nvme0n1p5";
      content = {
        type = "btrfs";
        extraArgs = ["-f" "-L" "nixos-dt"];
        subvolumes = {
          "/root" = {
            mountpoint = "/";
            mountOptions = ["compress=zstd" "noatime"];
          };
          "/nix" = {
            mountpoint = "/nix";
            mountOptions = ["compress=zstd" "noatime"];
          };
          "/persist" = {
            mountpoint = "/persist";
            mountOptions = ["compress=zstd" "noatime"];
          };
        };
      };
    };
  };

  fileSystems = {
    # Existing Windows EFI partition; disko must not format it.
    "/boot" = {
      device = "/dev/nvme0n1p1";
      fsType = "vfat";
      options = ["fmask=0077" "dmask=0077"];
    };

    # Existing Steam library drive; disko must not format it.
    "/games" = {
      device = "/dev/nvme1n1p1";
      fsType = "ntfs3";
      options = ["defaults" "nofail" "x-systemd.automount" "uid=1000" "gid=1000" "umask=0022" "exec"];
    };
  };

  # Wipe root subvolume on boot; old roots kept 30 days in /old_roots.
}

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
    "/persist".neededForBoot = true;

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
  boot.initrd.systemd.services.rollback-root = {
    description = "Rollback btrfs root subvolume";
    wantedBy = ["initrd.target"];
    requires = ["dev-disk-by\\x2dlabel-nixos\\x2ddt.device"];
    after = ["dev-disk-by\\x2dlabel-nixos\\x2ddt.device"];
    before = ["sysroot.mount"];
    unitConfig.DefaultDependencies = "no";
    serviceConfig.Type = "oneshot";
    script = ''
      mkdir -p /tmp
      mount -t btrfs /dev/disk/by-label/nixos-dt /tmp

      if [[ -e /tmp/root ]]; then
          mkdir -p /tmp/old_roots
          timestamp=$(date --date="@$(stat -c %Y /tmp/root)" "+%Y-%m-%-d_%H:%M:%S")
          mv /tmp/root "/tmp/old_roots/$timestamp"
      fi

      delete_subvolume_recursively() {
          IFS=$'\n'
          for i in $(btrfs subvolume list -o "$1" | cut -f 9- -d ' '); do
              delete_subvolume_recursively "/tmp/$i"
          done
          btrfs subvolume delete "$1"
      }

      for i in $(find /tmp/old_roots/ -maxdepth 1 -mtime +30); do
          delete_subvolume_recursively "$i"
      done

      btrfs subvolume create /tmp/root
      umount /tmp
    '';
  };
}

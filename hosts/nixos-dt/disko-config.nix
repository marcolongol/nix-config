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

    # Mount the existing Windows EFI partition — do NOT let disko format it.
    "/boot" = {
      device = "/dev/nvme0n1p1";
      fsType = "vfat";
      options = ["fmask=0077" "dmask=0077"];
    };

    # Steam library drive — existing filesystem, never formatted by disko.
    "/games" = {
      device = "/dev/nvme1n1p1";
      fsType = "ntfs3";
      options = ["defaults" "nofail" "x-systemd.automount" "uid=1000" "gid=1000" "umask=0022" "exec"];
    };
  };

  # Wipe and recreate the root subvolume on every boot.
  # Old roots are kept for 30 days under /old_roots for recovery.
  boot.initrd.postResumeCommands = lib.mkAfter ''
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
}

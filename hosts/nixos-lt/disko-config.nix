# disko configuration for nixos-lt
# This file defines declarative disk partitioning with impermanence support
{lib, ...}: {
  # Disk partitioning configuration
  disko.devices = {
    disk = {
      main = {
        type = "disk";
        device = "/dev/nvme0n1"; # Adjust this to match your actual disk device
        content = {
          type = "gpt";
          partitions = {
            # ESP boot partition
            ESP = {
              size = "1G";
              type = "EF00";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
                mountOptions = ["defaults" "umask=0077"];
              };
            };

            # Swap partition
            swap = {
              size = "16G"; # 16GB swap for better performance and hibernation support
              content = {type = "swap";};
            };

            # Persistent storage partition
            persist = {
              size = "100%"; # Most space goes to persistent data where it's actually needed
              content = {
                type = "filesystem";
                format = "ext4";
                mountpoint = "/persist";
                mountOptions = ["defaults" "noatime"];
              };
            };

            # Root partition with btrfs for proper impermanence
            root = {
              size = "120G"; # Space for btrfs subvolumes and snapshots
              content = {
                type = "btrfs";
                extraArgs = [
                  "-f"
                  "-L"
                  "nixos"
                ]; # Override existing partition and set label
                subvolumes = {
                  "/root" = {
                    mountpoint = "/";
                    mountOptions = ["compress=zstd" "noatime"];
                  };
                  "/nix" = {
                    mountpoint = "/nix";
                    mountOptions = ["compress=zstd" "noatime"];
                  };
                };
              };
            };
          };
        };
      };
    };
  };

  fileSystems."/persist".neededForBoot = true;

  # Impermanence: Wipe root subvolume on boot
  # This script runs during boot to create a fresh root subvolume
  # while preserving old roots for 30 days for recovery purposes
  boot.initrd.postResumeCommands = lib.mkAfter ''
    mkdir -p /tmp
    mount -t btrfs /dev/disk/by-label/nixos /tmp
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

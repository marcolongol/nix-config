# disko configuration for nixos-lt
{lib, ...}: {
  disko.devices = {
    disk = {
      main = {
        type = "disk";
        device = "/dev/nvme0n1";
        content = {
          type = "gpt";
          partitions = {
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

            swap = {
              size = "16G";
              content = {type = "swap";};
            };

            persist = {
              size = "100%";
              content = {
                type = "filesystem";
                format = "ext4";
                mountpoint = "/persist";
                mountOptions = ["defaults" "noatime"];
              };
            };

            root = {
              size = "120G";
              content = {
                type = "btrfs";
                extraArgs = [
                  "-f"
                  "-L"
                  "nixos"
                ];
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

  # Impermanence: wipe root subvolume on boot, keep old roots 30 days.
  boot.initrd.systemd.services.rollback-root = {
    description = "Rollback btrfs root subvolume";
    wantedBy = ["initrd.target"];
    requires = ["dev-disk-by\\x2dlabel-nixos.device"];
    after = ["dev-disk-by\\x2dlabel-nixos.device"];
    before = ["sysroot.mount"];
    unitConfig.DefaultDependencies = "no";
    serviceConfig.Type = "oneshot";
    script = ''
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
  };
}

# nixos-dt Installation Guide

## Disk layout

| Device        | Size   | Role                              |
|---------------|--------|-----------------------------------|
| nvme0n1p1     | 210 MB | EFI — shared with Windows, **not formatted** |
| nvme0n1p2     | 16 MB  | Microsoft Reserved — **untouched** |
| nvme0n1p3     | 499 GB | Windows data — **untouched**      |
| nvme0n1p4     | 649 MB | Windows recovery — **untouched**  |
| nvme0n1p5     | 500 GB | NixOS — BTRFS, formatted by disko |
| nvme1n1p1     | —      | Steam library — mounted at `/mnt/games`, **not formatted** |

Impermanence pattern: BTRFS subvolumes `/root` (wiped on boot), `/nix`, `/persist`.

---

## Step 1 — Boot from the live CD

Write the ISO to USB with `dd` and boot from it. SSH in or work directly on the machine.

---

## Step 2 — Format the NixOS partition

> Only `nvme0n1p5` is touched. Windows partitions are never modified.

```bash
sudo disko --mode disko /root/nix-config/hosts/nixos-dt/disko-config.nix
```

---

## Step 3 — Generate hardware configuration

```bash
sudo nixos-generate-config --no-filesystems --root /mnt
cp /mnt/etc/nixos/hardware-configuration.nix /root/nix-config/hosts/nixos-dt/hardware-config.nix
```

Open the generated file and verify `boot.initrd.availableKernelModules` and `boot.kernelModules` look sensible for your hardware.

---

## Step 4 — Mount the EFI partition

Disko only mounts what it manages. The EFI partition must be mounted manually before installing the bootloader.

```bash
mkdir -p /mnt/boot
mount /dev/nvme0n1p1 /mnt/boot
```

---

## Step 5 — Commit and install

```bash
cd /root/nix-config
git add -A
git commit -m "chore(nixos-dt): add hardware config"
sudo nixos-install --flake /root/nix-config#nixos-dt
```

---

## Step 6 — Reboot

Remove the USB drive and reboot. The systemd-boot menu will show both NixOS and Windows automatically.

---

## Step 7 — Post-install: wire up sops for nixos-dt

The `.sops.yaml` currently has a placeholder key for nixos-dt. After first boot:

```bash
# On nixos-dt, get the age public key derived from the SSH host key
ssh-to-age < /persist/etc/ssh/ssh_host_ed25519_key.pub
```

1. Copy the output (looks like `age1...`)
2. On your dev machine, edit `.sops.yaml` — replace the placeholder under `&nixos-dt`
3. Re-encrypt the secrets files that now include nixos-dt as a recipient:

```bash
cd ~/nix-config
sops updatekeys secrets/shared.yaml
sops updatekeys secrets/users/lucas.yaml
git add .sops.yaml secrets/
git commit -m "chore(sops): add nixos-dt host key"
git push
```

comin will pick up the changes and reconfigure the system automatically.

---

## Notes

- **Windows bootloader**: systemd-boot auto-detects Windows — no manual entry needed.
- **Steam library path**: add `/mnt/games` as a library location in Steam settings.
- **Persisted state**: the `impermanent` role persists `/etc/ssh`, `/etc/machine-id`,
  NetworkManager connections, logs, and Bluetooth devices under `/persist`.
  Add host-specific paths via `persistentFolders` / `persistentFiles` in `default.nix`.

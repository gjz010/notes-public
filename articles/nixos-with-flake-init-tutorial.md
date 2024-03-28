# Tutorial: github:gjz010/nix-channel\#nixos-with-flake-init

`github:gjz010/nix-channel#nixos-with-flake-init` upgrades `nixos-generate-config` by generating a [Flake](https://nixos.wiki/wiki/Flakes) rather than just `configuration.nix`.

## What is provided by default?

- NixOS installation as Flake output `nixosConfigurations`.
- `home-manager` NixOS-Module support.
- Several quality of life tweaks around Nix experience:
  - Enabling Flake commands by default.
  - Filling in `system.configurationRevision`, enabling `nixos-version --configuration-revision`.
  - Unifying nixpkgs versions by Nix channel, by Flake registry, and the one used by current installation.

## How to installing NixOS using nixos-with-flake-init?

TL;DR: Follow the [official tutorial](https://nixos.org/manual/nixos/stable/#sec-installation-manual-summary) but replace the `nixos-generate-config` line with:

```bash
# You may save your configurations elsewhere as long as they are presisted.
mkdir -p /mnt/etc/nixos
cd /mnt/etc/nixos
# Invoke nixos-with-flake-init here.
nix --experimental-features "nix-command flakes" run github:gjz010/nix-channel#nixos-with-flake-init
```
and replace the `nixos-install` line with:
```bash
# nixos-with-flake-init will require you to enter your hostname, say [YOUR_HOST_NAME].
nixos-install --flake .#[YOUR_HOST_NAME]
```


## Additional notes

Source: https://github.com/gjz010/nix-channel/tree/main/pkgs/nixos-with-flake-init


#nixos #tutorial

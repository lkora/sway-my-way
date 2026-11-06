Switch to Your Custom Operating System
Boot standard Fedora Sway Atomic from a USB drive, open a terminal, and run:

```sh
rpm-ostree rebase ostree-unverified-registry:ghcr.io/lkora/sway-my-way:latest
systemctl reboot
```
Your machine reboots directly into your customized kernel, drivers, Waybar, Foot terminal, and system packages.

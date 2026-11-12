# sway-my-way

Fedora **45 Sway Atomic**, for a physical x86_64 PC with an Intel CPU and integrated Intel graphics.

The image owns host packages, drivers, container engines, and VirtualBox modules.
Fedora supplies the desktop defaults.
[dotfiles](https://github.com/lkora/dotfiles) owns personal configuration, GUI app lists, and development containers.
The image does not clone or apply personal dotfiles.

See [the repository boundary](docs/architecture.md) for ownership and setup order.

## Included

- Sway desktop tools, Foot, Waybar, notifications, screen capture, and locking.
- Zsh, Neovim, chezmoi, Git, and common command-line tools.
- Intel VA-API support through RPM Fusion.
- Twingate and Syncthing binaries.
- Podman, Distrobox, and Docker Engine through Fedora's Moby package.
- VirtualBox and kernel modules built for the image kernel.

## Build

On a native x86_64 Linux container engine:

```sh
docker build --platform linux/amd64 -f Containerfile -t sway-my-way:local .
docker run --rm -i --entrypoint /usr/bin/bash sway-my-way:local < tests/image.sh
```

A local build without signing secrets requires Secure Boot to be disabled for VirtualBox modules.
For Secure Boot and CI publication, use [the signing procedure](docs/virtualbox.md).

CI builds pull requests with a temporary signing key.
Published images require your stable signing secrets.
CI checks module/kernel matching and image contents before publication.
A failed build does not replace the published image.

## Deploy

From an existing Fedora Sway Atomic installation:

```sh
sudo rpm-ostree rebase ostree-unverified-registry:ghcr.io/lkora/sway-my-way:45
systemctl reboot
```

This transport does not check an OCI image signature.
Secure Boot module signatures provide a separate check.

After reboot, initialize your user environment from the dotfiles repository.
Configure Twingate interactively:

```sh
sudo twingate setup
```

For VirtualBox, complete certificate enrollment and the target-PC checks in [the VirtualBox guide](docs/virtualbox.md).

## Update and rollback

```sh
sudo rpm-ostree upgrade
systemctl reboot
```

If an image update fails the target-PC checks, select the previous deployment or run:

```sh
sudo rpm-ostree rollback
systemctl reboot
```

## Change the image

| Change | Location |
|---|---|
| Add a host package | `build_files/packages.txt` |
| Add a system file | `system_files/` |
| Change build operations | `build_files/build.sh` |
| Change VirtualBox integration | `build_files/virtualbox.sh` |
| Add an image check | `tests/image.sh` |

Development compilers and language runtimes belong in the dotfiles development image.
Steam, Discord, and other personal GUI apps belong in its user app list.
The Fedora release remains 45 until an explicit image upgrade.

Twingate's [RPM instructions](https://www.twingate.com/docs/linux) disable package signature checks for its repository.
The build limits the RPM verification exception to its installation transaction.
The final image retains no global exception.

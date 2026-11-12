# Repository boundary

## Current target

The system targets Fedora 45 Sway Atomic on an Intel x86_64 PC with integrated Intel graphics.
VirtualBox runs Windows and Kali guests.
Secure Boot remains an installation option through module signing and certificate enrollment.
Linux is the only implemented dotfiles platform. The current Mac is a development control machine.

## Ownership

| Responsibility | Repository |
|---|---|
| Fedora base, kernel, drivers, system defaults | sway-my-way |
| Twingate and Syncthing binaries | sway-my-way |
| Podman, Distrobox, Docker Engine | sway-my-way |
| VirtualBox binaries and matching kernel modules | sway-my-way |
| Personal Zsh, Neovim, Sway, Waybar, Foot, Mako | dotfiles/home |
| Personal Flatpak app list and native VS Code installer | dotfiles/apps and dotfiles/scripts |
| Development image, asdf, uv, C/C++ tools | dotfiles/dev |
| Project language versions and project Dev Containers | Each project |
| Credentials, device identities, private signing keys | Outside both repositories |

The image boots with Fedora defaults before personal configuration exists.
Chezmoi does not install applications or change the host OS.
Application installation and development-container creation require explicit commands.

## Source layout

The dotfiles root contains `.chezmoiroot`, which selects `home/`.
Only that source directory supplies home-directory targets.
The `swayDesktop` selection controls desktop-specific files.
Unmanaged local files remain intact.

The image keeps its host package list in `build_files/packages.txt`.
System files belong in `system_files/`.
VirtualBox modules compile and receive signatures during the image build.
The private signing key remains outside the final image.

## Workflow

1. Build and check the Fedora image.
2. Boot the image on the target PC.
3. Complete Secure Boot enrollment when enabled.
4. Initialize chezmoi and inspect its diff.
5. Apply personal configuration.
6. Install user apps explicitly.
7. Create the development box explicitly.
8. Run the VirtualBox and development acceptance checks.

Image updates, app updates, and configuration updates remain separate operations.
Additional Linux installers and future macOS support belong in dotfiles.
The Fedora image remains independent of those platform additions.

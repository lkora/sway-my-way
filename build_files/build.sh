#!/bin/bash

set -ouex pipefail


### Install packages

# Packages can be installed from any enabled yum repo on the image.
# List of rpmfusion packages can be found here:
# https://mirrors.rpmfusion.org/mirrorlist?path=free/fedora/updates/43/x86_64/repoview/index.html&protocol=https&redirect=1


echo "==> Importing RPM Fusion GPG signing keys..."
# Fetch and import the RPM Fusion keys into the RPM database
curl -fsSL -o /tmp/RPM-GPG-KEY-rpmfusion-free "https://rpmfusion.org/keys?action=AttachFile&do=get&target=RPM-GPG-KEY-rpmfusion-free-fedora-2020"
curl -fsSL -o /tmp/RPM-GPG-KEY-rpmfusion-nonfree "https://rpmfusion.org/keys?action=AttachFile&do=get&target=RPM-GPG-KEY-rpmfusion-nonfree-fedora-2020"
rpm --import /tmp/RPM-GPG-KEY-rpmfusion-free /tmp/RPM-GPG-KEY-rpmfusion-nonfree
rm -f /tmp/RPM-GPG-KEY-rpmfusion-*


echo "==> Enabling RPM Fusion repositories..."
# RPM Fusion provides proprietary codecs, Nvidia drivers (if needed), and hardware acceleration
rpm-ostree install \
    https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm \
    https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm


echo "==> Adding Twingate repository..."
cat << 'EOF' > /etc/yum.repos.d/twingate.repo
[twingate]
name=Twingate Repository
baseurl=https://packages.twingate.com/rpm/
enabled=1
gpgcheck=0
EOF


echo "==> Installing base host packages..."
# Only install packages here that CANNOT run inside Distrobox/Flatpak
# (e.g. system shells, virtualization, hardware tools, VPNs, sway bars)
rpm-ostree install \
    zsh \
    foot \
    waybar \
    twingate \
    syncthing \
    distrobox \
    podman \
    libva-utils \
    intel-media-driver \
    fastfetch


# this installs a package from fedora repos
# dnf5 install -y tmux

# Use a COPR Example:
#
# dnf5 -y copr enable ublue-os/staging
# dnf5 -y install package
# Disable COPRs so they don't end up enabled on the final image:
# dnf5 -y copr disable ublue-os/staging


echo "==> Installing Nerd Fonts for Waybar..."
# Download JetBrainsMono Nerd Font system-wide
FONT_DIR="/usr/share/fonts/jetbrains-mono-nerd"
mkdir -p "$FONT_DIR"
curl -fLo /tmp/font.zip https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.tar.xz
tar -xf /tmp/font.zip -C "$FONT_DIR"
rm -f /tmp/font.zip
fc-cache -f "$FONT_DIR"


#### Example for enabling a System Unit File

echo "==> Configuring systemd presets..."

systemctl enable podman.socket

echo "==> Base image customizations complete!"

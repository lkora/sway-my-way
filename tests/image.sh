#!/usr/bin/env bash
set -euo pipefail
kernel=$(cat /usr/share/sway-my-way/kernel-version)
[[ "$(rpm -q kernel --qf '%{VERSION}-%{RELEASE}.%{ARCH}')" == "$kernel" ]]
modinfo -k "$kernel" i915 >/dev/null
rpm -q VirtualBox akmod-VirtualBox twingate syncthing podman distrobox moby-engine chezmoi neovim
for module in vboxdrv vboxnetflt vboxnetadp; do
    [[ "$(modinfo -k "$kernel" -F vermagic "$module")" == "$kernel "* ]]
    if [[ -f /usr/share/sway-my-way/module-signing.der ]]; then
        [[ -n "$(modinfo -k "$kernel" -F signer "$module")" ]]
    fi
done
[[ ! -e /etc/pki/akmods/private/private_key.priv ]]
[[ ! -e /etc/rpm/macros.twingate-build ]]
command -v docker
docker compose version
command -v VirtualBox
echo "Image checks passed. Boot and VM checks still require the target PC."

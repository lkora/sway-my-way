#!/usr/bin/env bash
set -euo pipefail
build_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
fedora=$(rpm -E %fedora)
[[ "$fedora" == 45 && "$(rpm -E %_arch)" == x86_64 ]] || {
    echo "This image requires Fedora 45 x86_64." >&2
    exit 1
}

# Bootstrap RPM Fusion from keys distributed by Fedora.
dnf5 -y install distribution-gpg-keys
for repo in free nonfree; do
    for generation in 2020 "$fedora"; do
        key="/usr/share/distribution-gpg-keys/rpmfusion/RPM-GPG-KEY-rpmfusion-$repo-fedora-$generation"
        if [[ -f "$key" ]]; then rpm --import "$key"; fi
    done
done
dnf5 -y --setopt=localpkg_gpgcheck=1 install \
    "https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$fedora.noarch.rpm" \
    "https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$fedora.noarch.rpm"

# akmod's automatic post-install build is inappropriate inside an image build.
# Install its dependencies normally, then build modules explicitly below.
dnf5 -y install akmods kernel-devel-matched VirtualBox-kmodsrc
dnf5 -y --setopt=tsflags=noscripts install akmod-VirtualBox
mapfile -t packages < <(sed -e 's/#.*//' -e '/^[[:space:]]*$/d' "$build_dir/packages.txt")
dnf5 -y install "${packages[@]}"

# The vendor documents unsigned RPMs. Limit the exception to this transaction.
trap 'rm -f /etc/rpm/macros.twingate-build' EXIT
printf '%%_pkgverify_level digest\n' > /etc/rpm/macros.twingate-build
dnf5 -y --enablerepo=twingate install twingate
rm -f /etc/rpm/macros.twingate-build
trap - EXIT

# No service starts inside the build container.
systemctl enable docker.service vboxdrv.service
dnf5 clean all
rm -rf /var/cache/dnf /var/cache/libdnf5 /etc/pki/akmods/private

#!/usr/bin/env bash
set -euo pipefail
if [[ "${REQUIRE_MODULE_SIGNING:-0}" == 1 ]]; then
    [[ -s /run/secrets/module_key && -s /run/secrets/module_cert ]] || {
        echo "Provide module_key and module_cert build secrets. See docs/virtualbox.md." >&2
        exit 1
    }
fi

# kernel-devel-matched chooses a coherent Fedora kernel and development files.
# Remove an older base kernel if that transaction installed a newer one.
kernel=$(rpm -q kernel-devel-matched --qf '%{VERSION}-%{RELEASE}.%{ARCH}\n')
# Keep the complete desktop kernel, not only kernel-core pulled by akmods.
dnf5 -y install "kernel-$kernel"
if rpm -q kernel-modules-extra >/dev/null 2>&1; then
    dnf5 -y install "kernel-modules-extra-$kernel"
fi
mapfile -t old_kernels < <(rpm -qa --qf '%{NAME} %{VERSION}-%{RELEASE}.%{ARCH}\n' |
    awk -v keep="$kernel" '$1 ~ /^kernel(-core|-modules|-modules-core|-modules-extra)?$/ && $2 != keep {print $1 "-" $2}')
if [[ "${#old_kernels[@]}" -gt 0 ]]; then dnf5 -y remove "${old_kernels[@]}"; fi
mapfile -t kernels < <(rpm -q kernel-core --qf '%{VERSION}-%{RELEASE}.%{ARCH}\n')
[[ "${#kernels[@]}" -eq 1 && "${kernels[0]}" == "$kernel" ]] || {
    echo "The image must contain exactly the matched kernel $kernel." >&2
    exit 1
}

key=/run/secrets/module_key
cert=/run/secrets/module_cert
if [[ -s "$key" || -s "$cert" ]]; then
    [[ -s "$key" && -s "$cert" ]] || {
        echo "Both module signing secrets are required." >&2
        exit 1
    }
    if [[ -n "${MODULE_SIGNING_CERT_SHA256:-}" ]]; then
        printf '%s  %s\n' "$MODULE_SIGNING_CERT_SHA256" "$cert" | sha256sum --check -
    fi
    key_hash=$(openssl pkey -in "$key" -pubout -outform DER | sha256sum)
    cert_hash=$(openssl x509 -inform DER -in "$cert" -pubkey -noout |
        openssl pkey -pubin -outform DER | sha256sum)
    [[ "$key_hash" == "$cert_hash" ]] || {
        echo "The module key and certificate do not match." >&2
        exit 1
    }
    install -d /etc/pki/akmods/private /etc/pki/akmods/certs /usr/share/sway-my-way
    ln -sf "$key" /etc/pki/akmods/private/private_key.priv
    install -m 0644 "$cert" /etc/pki/akmods/certs/public_key.der
    install -m 0644 "$cert" /usr/share/sway-my-way/module-signing.der
fi
# Remove generated or linked private keys before this RUN layer is committed.
trap 'rm -rf /etc/pki/akmods/private' EXIT
akmods --rebuild --force --kernels "$kernel" --kmod VirtualBox
depmod -a "$kernel"
for module in vboxdrv vboxnetflt vboxnetadp; do
    [[ "$(modinfo -k "$kernel" -F vermagic "$module")" == "$kernel "* ]] || {
        echo "VirtualBox module $module does not match $kernel." >&2
        find /var/cache/akmods/VirtualBox -name '*.failed.log' -exec tail -n 60 {} \; >&2
        exit 1
    }
    if [[ -s "$cert" ]]; then
        [[ -n "$(modinfo -k "$kernel" -F signer "$module")" ]] || {
            echo "VirtualBox module $module is unsigned." >&2
            exit 1
        }
    fi
done
install -d /usr/share/sway-my-way
printf '%s\n' "$kernel" > /usr/share/sway-my-way/kernel-version
rpm -q VirtualBox akmod-VirtualBox > /usr/share/sway-my-way/virtualbox-version
rm -rf /etc/pki/akmods/private /var/cache/akmods
trap - EXIT

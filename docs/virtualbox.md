# VirtualBox and Secure Boot

The image installs VirtualBox and `akmod-VirtualBox` from RPM Fusion.
The build compiles modules for the installed image kernel, independent of the build runner's kernel.
The image includes `vboxdrv`, `vboxnetflt`, and `vboxnetadp`.
Extension Pack installation remains separate.

## Create a signing identity

Keep the private key in a secure directory outside Git and the container build context.
Create a stable key and DER certificate:

```sh
openssl req -new -x509 -newkey rsa:3072 -nodes -days 3650 \
  -subj "/CN=sway-my-way modules/" \
  -keyout module.key -outform DER -out module.der
chmod 600 module.key
```

Keep this identity across image rebuilds.
Only its public certificate enters the image.
The build mounts the private key as a secret and removes the signing symlink before it commits the image layer.

## Local signed build

```sh
docker build --platform linux/amd64 -f Containerfile \
  --build-arg REQUIRE_MODULE_SIGNING=1 \
  --build-arg MODULE_SIGNING_CERT_SHA256="$(sha256sum /secure/path/module.der | cut -d' ' -f1)" \
  --secret id=module_key,src=/secure/path/module.key \
  --secret id=module_cert,src=/secure/path/module.der \
  -t sway-my-way:signed .
```

The certificate hash invalidates the build cache after a key rotation.

## GitHub Actions

Add these repository Actions secrets:

| Secret | Contents |
|---|---|
| `MODULE_SIGNING_KEY` | Complete PEM private-key file |
| `MODULE_SIGNING_CERT_BASE64` | Base64-encoded DER certificate |

For the second secret, encode the certificate:

```sh
base64 < module.der
```

Pull requests use temporary keys and never publish an image.
Main-branch and scheduled builds require the stable keys.
No private key belongs in a repository file, image layer, or build argument.

## Enroll on the target PC

After you boot the signed image, inspect Secure Boot:

```sh
mokutil --sb-state
```

If Secure Boot is enabled, enroll the image certificate:

```sh
sudo mokutil --import /usr/share/sway-my-way/module-signing.der
systemctl reboot
```

The firmware enrollment screen requires local confirmation.
Use the password from the import step.
This enrollment cannot run through a repository build.

After enrollment:

```sh
sudo mokutil --test-key /usr/share/sway-my-way/module-signing.der
modinfo -F signer vboxdrv
sudo modprobe vboxdrv
VBoxManage --version
```

For user access to VirtualBox devices:

```sh
sudo usermod -aG vboxusers "$USER"
```

Log out and log in.
Enable Intel VT-x in the PC firmware.
Create a small Linux VM and make sure that it starts, stops, and reaches the network.
Then create your Windows or Kali guests.

Repeat the module and VM checks after a kernel update.
If the checks fail, use the previous Atomic deployment while you investigate.
Compilation checks do not replace these checks on the target hardware.

References: [RPM Fusion VirtualBox](https://rpmfusion.org/Howto/VirtualBox),
[RPM Fusion Secure Boot](https://rpmfusion.org/Howto/Secure%20Boot),
and [Oracle's Linux host instructions](https://www.virtualbox.org/manual/ch02.html#installation_linux).

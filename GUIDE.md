# ES8336 jack fix for Huawei MateBook D16 (AMD 4600H)

Build the patched `snd-acp-legacy-mach.ko` for the **running Fedora kernel**.
The commands below use `7.3.3-200.fc44` as the source RPM version; use the
corresponding version if `uname -r` differs. Run the build as your normal user.

## Prerequisites

```sh
export kernel_release=$(uname -r)
export kernel_build=kernel-7.3.3-200.fc44

sudo dnf install rpmdevtools koji gcc make patch openssl mokutil "kernel-devel-$kernel_release"
rpmdev-setuptree
koji download-build --arch=src "$kernel_build"
rpm -Uvh "${kernel_build}.src.rpm"
sudo dnf builddep ~/rpmbuild/SPECS/kernel.spec
```

**TODO**

## Apply the patch

Run this section from the repository root. `%prep` creates a fresh source tree
and applies Fedora's patches without building the kernel. Rerun it if an older
version of this patch is already applied in `~/rpmbuild/BUILD`:

```sh
rpmbuild -bp ~/rpmbuild/SPECS/kernel.spec
```

Apply the patch to the prepared source:

```sh
export repo_dir=$PWD
export kernel_src=$(find ~/rpmbuild/BUILD -type d -name "linux-$(uname -r)" -print -quit)
export driver=sound/soc/amd/acp/acp3x-es83xx/acp3x-es83xx.c

test -n "$kernel_src" || { echo 'Prepared kernel source not found' >&2; exit 1; }
cmp "$kernel_src/$driver" "$repo_dir/sound/soc/amd/acp/acp3x-es83xx/acp3x-es83xx.orig.c" || exit 1
patch --batch -d "$kernel_src" -p1 < "$repo_dir/es8336-jack.patch"
```

The `cmp` check ensures that the patch's original file matches Fedora's
prepared source. Apply the patch only once to a fresh tree.

## Build the module

`acp3x-es83xx.c` is part of `snd-acp-legacy-mach.ko`, so build the complete
module against the matching `kernel-devel` package:

```sh
export kernel_src=$(find ~/rpmbuild/BUILD -type d -name "linux-$(uname -r)" -print -quit)
export src="$kernel_src/sound/soc/amd/acp"
export module_dir=~/mydevel/snd-acp-legacy-mach

test -n "$kernel_src" || { echo 'Prepared kernel source not found' >&2; exit 1; }
mkdir -p "$module_dir/acp3x-es83xx"
cp "$src"/{acp-legacy-mach.c,acp-mach.h,acp_common.h} "$module_dir/"
cp "$src"/acp3x-es83xx/{acp3x-es83xx.c,acp3x-es83xx.h} "$module_dir/acp3x-es83xx/"
cat > "$module_dir/Kbuild" <<'EOF'
obj-m := snd-acp-legacy-mach.o
snd-acp-legacy-mach-y := acp-legacy-mach.o acp3x-es83xx/acp3x-es83xx.o
EOF
make -C "/lib/modules/$(uname -r)/build" M="$module_dir" modules
modinfo -F vermagic "$module_dir/snd-acp-legacy-mach.ko"
```

The `vermagic` output must start with `uname -r`.

## Secure Boot: enroll a key once

Secure Boot is enabled on this laptop. Keep the private key outside the
repository and reuse it to sign later module builds.

```sh
export key_dir=~/mydevel/secureboot

mkdir -p "$key_dir"
chmod 700 "$key_dir"
openssl req -new -x509 -newkey rsa:4096 -nodes -days 3650 \
  -subj '/CN=MateBook ES8336 module/' \
  -keyout "$key_dir/MOK.key" -outform DER -out "$key_dir/MOK.der"
chmod 600 "$key_dir/MOK.key"
sudo mokutil --import "$key_dir/MOK.der"
```

Reboot, select **Enroll MOK** in MOK Manager, and enter the password set by
`mokutil`. Back in Fedora, check that the certificate appears in the enrolled
list. `mokutil --test-key` can report a kernel keyring access error even when
the certificate is enrolled, so do not use its exit code as the signing gate.

## Sign and install

```sh
export key_dir=~/mydevel/secureboot
export module_dir=~/mydevel/snd-acp-legacy-mach

mokutil --list-enrolled | grep -F 'Subject: CN=MateBook ES8336 module'
```

If the certificate is listed, sign the module and check the signer. `sign-file`
prints nothing when it succeeds. These commands stop if signing or installation
fails, and they do not call `exit` on your interactive shell.

```sh
export key_dir=~/mydevel/secureboot
export module_dir=~/mydevel/snd-acp-legacy-mach

"/lib/modules/$(uname -r)/build/scripts/sign-file" sha256 \
  "$key_dir/MOK.key" "$key_dir/MOK.der" "$module_dir/snd-acp-legacy-mach.ko" &&
modinfo -F signer "$module_dir/snd-acp-legacy-mach.ko" &&
sudo install -D -m 0644 "$module_dir/snd-acp-legacy-mach.ko" \
  "/lib/modules/$(uname -r)/updates/snd-acp-legacy-mach.ko" &&
sudo depmod -a "$(uname -r)" &&
sudo reboot
```

After reboot, re-export the running kernel version and check that the module
path points into `updates/`:

```sh
export kernel_release=$(uname -r)

modinfo -n snd-acp-legacy-mach
```

Test jack insertion, removal, playback, and microphone input. Rebuild and
sign the module for each new kernel version.

To restore Fedora's packaged module for the running kernel:

```sh
export kernel_release=$(uname -r)

sudo rm "/lib/modules/$kernel_release/updates/snd-acp-legacy-mach.ko"
sudo depmod -a "$kernel_release"
sudo reboot
```

## References

### Fedora kernel source

- [Building a custom kernel from a source RPM](https://fedoraproject.org/wiki/Building_a_custom_kernel/Source_RPM)
- [Fedora/ARK kernel repository layout](https://cki-project.gitlab.io/kernel-ark/repository-layout.html)

### ES8336 and Huawei audio

- [SOF Linux issue #3249](https://github.com/thesofproject/linux/issues/3249)
- [Huawei MateBook AMD sound support](https://github.com/codepayne/linux-sound-huawei)
- [Huawei MateBook 14 headphone jack fix](https://github.com/Xellanox/Huawei-Matebook-14-Audio)

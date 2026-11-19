# ES8336 headphone jack fix for Huawei MateBook D16

This akmod replaces `snd-acp-legacy-mach` with a version that sets the headphone GPIO polarity for the BOM-WXX9 and HVY-WXX9 M1010. It is based on Fedora kernel 7.3.4 sources. Akmods rebuilds it for installed kernel updates and signs each build with its local key.

## Install (Fedora Workstation)

```sh
sudo dnf install akmods kmodtool mokutil "kernel-devel-$(uname -r)"
sudo kmodgenca -a
sudo mokutil --import /etc/pki/akmods/certs/public_key.der
make install
```

`make install` builds the RPMs, installs them, and builds the module for the running kernel. The package installs `/etc/depmod.d/es8336-jack.conf` with `override snd-acp-legacy-mach * extra/es8336-jack`, which tells depmod to prefer the akmod over Fedora's module for each kernel. Check the selected path before rebooting:

```sh
modinfo -n snd-acp-legacy-mach
modinfo -F signer snd-acp-legacy-mach
```

The path should contain `/extra/es8336-jack/`. Reboot and choose **Enroll MOK** in the firmware's MOK Manager, using the password from `mokutil`. Reboot again to load the signed replacement. The key enrollment is a one-time step; subsequent kernel updates rebuild and sign automatically.

If `akmods` reports a build failure after a future kernel update, inspect `/var/cache/akmods/es8336-jack/` and update the bundled driver sources for that kernel. Akmods cannot guarantee compatibility when Fedora changes the driver or its kernel interfaces.

To remove the replacement, run `make remove`, then reboot. This removes the RPMs and the packaged depmod priority rule.

The original patch is in [es8336-jack.patch](es8336-jack.patch). The four other bundled source files and the original driver file came from Fedora kernel 7.3.4-200.fc44; the patched driver is in `module/acp3x-es83xx/acp3x-es83xx.c`.

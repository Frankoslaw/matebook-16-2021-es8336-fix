# ES8336 headphone jack fix for Huawei MateBook D16

This patch adds a headphone GPIO polarity quirk for the ES8336 audio driver on supported Huawei MateBook models, including the HVY-WXX9 M1010. It aims to fix silent headphone jack output through a replacement `snd-acp-legacy-mach` kernel module for Fedora.

## Automated install

Install the prerequisites in [GUIDE.md](GUIDE.md), then run `make install`.
It fetches source for the running Fedora kernel, builds and signs the module,
requests MOK enrollment if needed, and installs it. Reboot to enroll the key
and load the module. Run `make remove` and reboot to restore Fedora's module.

Available commands: `make check`, `make source`, `make build`, `make sign`,
`make enroll`, `make install` (the default), and `make remove`. The Makefile
reuses existing build files and signing keys. Set a different key directory
with `make KEY_DIR=/path install`.

## Manual build

See [GUIDE.md](GUIDE.md) for the step-by-step build and installation commands.

## Author

Franciszek Łopuszański

## References

### Fedora kernel source

- [Building a custom kernel from a source RPM](https://fedoraproject.org/wiki/Building_a_custom_kernel/Source_RPM)
- [Fedora/ARK kernel repository layout](https://cki-project.gitlab.io/kernel-ark/repository-layout.html)

### ES8336 and Huawei audio

- [SOF Linux issue #3249](https://github.com/thesofproject/linux/issues/3249)
- [Huawei MateBook AMD sound support](https://github.com/codepayne/linux-sound-huawei)
- [Huawei MateBook 14 headphone jack fix](https://github.com/Xellanox/Huawei-Matebook-14-Audio)

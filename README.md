# ES8336 headphone jack fix for Huawei MateBook D16

This patch adds a headphone GPIO polarity quirk for the ES8336 audio driver on supported Huawei MateBook models, including the HVY-WXX9 M1010. It aims to fix silent headphone jack output through a replacement `snd-acp-legacy-mach` kernel module for Fedora.

See [GUIDE.md](GUIDE.md) for build, Secure Boot signing, and installation steps.

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

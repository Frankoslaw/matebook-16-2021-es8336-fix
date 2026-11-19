KERNEL_RELEASE := $(shell uname -r)
KERNEL_NVR := $(shell rpm -q --qf '%{VERSION}-%{RELEASE}' 'kernel-core-$(KERNEL_RELEASE)' 2>/dev/null)
KERNEL_BUILD := kernel-$(KERNEL_NVR)

WORK_DIR := $(CURDIR)/build/$(KERNEL_RELEASE)
RPM_DIR := $(WORK_DIR)/rpmbuild
MODULE_DIR := $(WORK_DIR)/module
SOURCE_RPM := $(WORK_DIR)/$(KERNEL_BUILD).src.rpm
SPEC := $(RPM_DIR)/SPECS/kernel.spec
PATCHED := $(WORK_DIR)/patched
MODULE_SOURCES := $(MODULE_DIR)/.sources
MODULE := $(MODULE_DIR)/snd-acp-legacy-mach.ko
SIGNED := $(WORK_DIR)/snd-acp-legacy-mach.ko
KERNEL_BUILD_DIR := /lib/modules/$(KERNEL_RELEASE)/build
INSTALLED := /lib/modules/$(KERNEL_RELEASE)/updates/snd-acp-legacy-mach.ko

KEY_DIR ?= $(HOME)/mydevel/secureboot
KEY := $(KEY_DIR)/MOK.key
CERT := $(KEY_DIR)/MOK.der

.DEFAULT_GOAL := install
.DELETE_ON_ERROR:
.PHONY: all source build sign enroll install remove check

all: sign
source: $(PATCHED)
build: $(MODULE)
sign: $(SIGNED)

check:
	@test -n '$(KERNEL_NVR)' || { echo 'The running kernel-core RPM is not installed.' >&2; exit 1; }
	@test -d '$(KERNEL_BUILD_DIR)' || { echo 'Install kernel-devel-$(KERNEL_RELEASE) first.' >&2; exit 1; }
	@for tool in koji rpm rpmbuild patch openssl mokutil modinfo; do \
		command -v "$$tool" >/dev/null || { echo "Missing $$tool" >&2; exit 1; }; \
	done

$(SOURCE_RPM): | check
	mkdir -p '$(WORK_DIR)'
	cd '$(WORK_DIR)' && koji download-build --arch=src '$(KERNEL_BUILD)'
	@test -s '$@'

$(SPEC): $(SOURCE_RPM)
	mkdir -p '$(RPM_DIR)'
	rpm --define '_topdir $(RPM_DIR)' -i '$<'
	@test -s '$@'

$(PATCHED): $(SPEC) es8336-jack.patch sound/soc/amd/acp/acp3x-es83xx/acp3x-es83xx.orig.c
	rpmbuild --define '_topdir $(RPM_DIR)' -bp '$(SPEC)'
	@set -e; src=$$(find '$(RPM_DIR)/BUILD' -type d -name 'linux-$(KERNEL_RELEASE)' -print -quit); \
		test -n "$$src" || { echo 'Prepared kernel source not found.' >&2; exit 1; }; \
		file='sound/soc/amd/acp/acp3x-es83xx/acp3x-es83xx.c'; \
		cmp -s "$$src/$$file" 'sound/soc/amd/acp/acp3x-es83xx/acp3x-es83xx.orig.c' || { \
			echo 'Prepared source differs from the expected driver; inspect the patch.' >&2; exit 1; }; \
		patch --batch -d "$$src" -p1 < es8336-jack.patch
	@touch '$@'

$(MODULE_SOURCES): $(PATCHED)
	@set -e; src=$$(find '$(RPM_DIR)/BUILD' -type d -name 'linux-$(KERNEL_RELEASE)' -print -quit)/sound/soc/amd/acp; \
		test -f "$$src/acp-legacy-mach.c" || { echo 'ACP source not found.' >&2; exit 1; }; \
		mkdir -p '$(MODULE_DIR)/acp3x-es83xx'; \
		cp "$$src/acp-legacy-mach.c" "$$src/acp-mach.h" "$$src/acp_common.h" '$(MODULE_DIR)/'; \
		cp "$$src/acp3x-es83xx/acp3x-es83xx.c" "$$src/acp3x-es83xx/acp3x-es83xx.h" '$(MODULE_DIR)/acp3x-es83xx/'
	@printf '%s\n' 'obj-m := snd-acp-legacy-mach.o' 'snd-acp-legacy-mach-y := acp-legacy-mach.o acp3x-es83xx/acp3x-es83xx.o' > '$(MODULE_DIR)/Kbuild'
	@touch '$@'

$(MODULE): $(MODULE_SOURCES) | check
	$(MAKE) -C '$(KERNEL_BUILD_DIR)' M='$(MODULE_DIR)' modules
	@case "$$(modinfo -F vermagic '$@')" in '$(KERNEL_RELEASE)'\ *) ;; *) echo 'Module vermagic does not match $(KERNEL_RELEASE).' >&2; exit 1;; esac

$(KEY) $(CERT) &:
	@mkdir -p '$(KEY_DIR)' && chmod 700 '$(KEY_DIR)'
	@test ! -e '$(KEY)' && test ! -e '$(CERT)' || { echo 'Only one signing key file exists; restore its matching file before continuing.' >&2; exit 1; }
	openssl req -new -x509 -newkey rsa:4096 -nodes -days 3650 -subj '/CN=MateBook ES8336 module/' -keyout '$(KEY)' -outform DER -out '$(CERT)'
	@chmod 600 '$(KEY)'

$(SIGNED): $(MODULE) $(KEY) $(CERT)
	cp '$(MODULE)' '$@'
	'$(KERNEL_BUILD_DIR)/scripts/sign-file' sha256 '$(KEY)' '$(CERT)' '$@'
	@modinfo -F signer '$@'

enroll: $(CERT)
	@fingerprint=$$(openssl x509 -inform DER -in '$(CERT)' -noout -fingerprint -sha1 | cut -d= -f2); \
		if mokutil --list-enrolled | grep -Fqi "SHA1 Fingerprint: $$fingerprint"; then \
			echo 'Signing certificate is enrolled.'; \
		elif mokutil --list-new | grep -Fqi "SHA1 Fingerprint: $$fingerprint"; then \
			echo 'MOK enrollment is pending. Reboot and complete it in MOK Manager.'; \
		else \
			sudo mokutil --import '$(CERT)' && \
			echo 'Reboot and complete enrollment in MOK Manager before loading the module.'; \
		fi

install: $(SIGNED) enroll
	sudo install -D -m 0644 '$(SIGNED)' '$(INSTALLED)'
	sudo depmod -a '$(KERNEL_RELEASE)'
	@echo 'Installed for $(KERNEL_RELEASE). Reboot to load the replacement module.'

remove:
	@if test -e '$(INSTALLED)'; then \
		sudo rm -- '$(INSTALLED)' && sudo depmod -a '$(KERNEL_RELEASE)'; \
		echo 'Removed replacement for $(KERNEL_RELEASE). Reboot to load the packaged module.'; \
	else \
		echo 'No replacement module is installed for $(KERNEL_RELEASE).'; \
	fi

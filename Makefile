NAME := es8336-jack-kmod
VERSION := 7.3.4
TOPDIR := $(CURDIR)/build/rpm
RPMBUILD ?= rpmbuild
RPM_PACKAGES = $(shell rpmspec -q --qf '%{NAME}-%{VERSION}-%{RELEASE}.%{ARCH}\n' '$(NAME).spec')

.PHONY: rpm install remove

rpm:
	mkdir -p '$(TOPDIR)/SOURCES' '$(TOPDIR)/SPECS'
	tar -C module --transform='s,^,$(NAME)-$(VERSION)/,' -czf '$(TOPDIR)/SOURCES/$(NAME)-$(VERSION).tar.gz' Kbuild acp-legacy-mach.c acp-mach.h acp_common.h acp3x-es83xx/acp3x-es83xx.c acp3x-es83xx/acp3x-es83xx.h
	cp README.md '$(TOPDIR)/SOURCES/'
	cp es8336-jack.depmod.conf '$(TOPDIR)/SOURCES/'
	cp '$(NAME).spec' '$(TOPDIR)/SPECS/'
	$(RPMBUILD) --define '_topdir $(TOPDIR)' -bb '$(TOPDIR)/SPECS/$(NAME).spec'

install: rpm
	sudo dnf install $(foreach package,$(filter akmod-es8336-jack-% es8336-jack-kmod-%,$(RPM_PACKAGES)),'$(TOPDIR)/RPMS/x86_64/$(package).rpm')
	sudo akmods --force --kernels '$(shell uname -r)' --akmod es8336-jack
	sudo depmod -a '$(shell uname -r)'

remove:
	sudo dnf remove akmod-es8336-jack es8336-jack-kmod 'kmod-es8336-jack-*'
	sudo depmod -a '$(shell uname -r)'

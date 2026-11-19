%global debug_package %{nil}
%global kmod_name es8336-jack

Name:           es8336-jack-kmod
Version:        7.3.4
Release:        2%{?dist}
Summary:        Huawei MateBook ES8336 headphone jack kernel module fix
License:        GPL-2.0-only AND GPL-2.0-or-later AND (GPL-2.0-only OR BSD-3-Clause)
URL:            https://github.com/frankoslaw/matebook-16-2021-es8336-fix
Source0:        %{name}-%{version}.tar.gz
Source1:        README.md
Source2:        es8336-jack.depmod.conf
ExclusiveArch:  x86_64
BuildRequires:  kmodtool
Provides:       %{name}-common = %{version}-%{release}

%{expand:%(kmodtool --target %{_target_cpu} --kmodname %{kmod_name} %{?kernels:--for-kernels "%{kernels}"}%{!?kernels:--akmod} 2>/dev/null)}

%description
Source and documentation for the ES8336 jack akmod.

%prep
%{?kmodtool_check}
%autosetup
for kernel_version in %{?kernel_versions}; do
    cp -a . "../_kmod_build_${kernel_version%%___*}"
done

%build
for kernel_version in %{?kernel_versions}; do
    make -C "${kernel_version##*___}" M="$PWD/../_kmod_build_${kernel_version%%___*}" modules
done

%install
for kernel_version in %{?kernel_versions}; do
    install -D -m 0644 "../_kmod_build_${kernel_version%%___*}/snd-acp-legacy-mach.ko" \
        "%{buildroot}%{kmodinstdir_prefix}${kernel_version%%___*}%{kmodinstdir_postfix}/snd-acp-legacy-mach.ko"
done
install -D -m 0644 %{SOURCE1} %{buildroot}%{_docdir}/%{name}/README.md
install -D -m 0644 %{SOURCE2} %{buildroot}%{_sysconfdir}/depmod.d/es8336-jack.conf
%{?akmod_install}

%files
%{_docdir}/%{name}/README.md
%config(noreplace) %{_sysconfdir}/depmod.d/es8336-jack.conf

%changelog
* Fri Nov 20 2026 Franciszek Łopuszański - 7.3.4-2
- Prioritize the packaged module with a depmod override

* Thu Nov 19 2026 Franciszek Łopuszański - 7.3.4-1
- Initial akmod package

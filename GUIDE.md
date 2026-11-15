# Audio fix for es8336 on matebok D16 (2021 AMD 4600h)

Install required dependencies along with rpm devtools. Regarding kernel-devel libs fedora will download the correct version automatically as far as I am aware:
```sh
# Install some packages we need badly
sudo dnf install fedpkg fedora-packager rpmdevtools ncurses-devel pesign grubby kernel-devel koji 
# Install some packages we need to run "make xconfig" in PART 2.
sudo dnf install qt5-qtbase-devel libXi-devel gcc-c++
# Install ccache so that subsequent builds may go faster than first build 
sudo dnf install ccache
```

Setup rpm dev tree in the NON-ROOT home directory:
```sh
cd 
rpmdev-setuptree
```

Download kernel rpm source for me it is 7.3.3-200
```sh
# koji download-build --arch=src kernel-<version>.fc44.x86_64
koji download-build --arch=src kernel-7.3.3-200.fc44.x86_64
```

Install kernel-<version>.src.rpm with the following command:
```sh
# rpm -Uvh kernel-<version>.src.rpm 
rpm -Uvh kernel-7.3.3-200.fc44.src.rpm
```
the resulting files in this case the source code as we selected `--arach=src` ealier will endup in SOURCES and SPECS directories under `$HOME/rpmbuild` which is quite common for an rpm package

We also install all of the needed dependencies for the build based of the SPECS
```sh
cd ~/rpmbuild/SPECS
sudo dnf builddep kernel.spec
```

**TODO**

# References:
- https://fedoraproject.org/wiki/Building_a_custom_kernel/Source_RPM
# HyprSupreme-Builder Compatibility Guide

## Supported Operating Systems & Distributions

HyprSupreme-Builder now supports a wide range of operating systems and distributions with varying levels of compatibility.

### 🔥 **Fully Supported** (Native Hyprland packages available)

#### Arch Linux Family
- **Arch Linux** - Full native support ✅
- **EndeavourOS** - Full native support ✅
- **CachyOS** - Full native support ✅
- **Manjaro** - Full native support ✅
- **Garuda Linux** - Full native support ✅
- **ArcoLinux** - Full native support ✅
- **Artix Linux** - Full native support ✅
- **BlackArch** - Full native support ✅

**Features**: AUR support, automatic package management, complete Hyprland ecosystem

### 🟡 **Well Supported** (Some packages may need compilation)

#### Debian Family
- **Ubuntu 22.04+** - Good support ⚠️
- **Debian 11+** - Good support ⚠️
- **Linux Mint** - Good support ⚠️
- **Pop!_OS** - Good support ⚠️
- **Elementary OS** - Good support ⚠️
- **Zorin OS** - Good support ⚠️
- **Kali Linux** - Good support ⚠️
- **Parrot OS** - Good support ⚠️
- **Raspberry Pi OS** - Basic support ⚠️

**Notes**: Some Hyprland components may need compilation from source. PPAs available for newer versions.

#### Red Hat Family
- **Fedora 39+** - Good support ⚠️
- **Fedora 38** - Good support ⚠️
- **RHEL 9.3+** - Limited support ⚠️
- **RHEL 8.8+** - Limited support ⚠️
- **CentOS Stream 9** - Limited support ⚠️
- **Rocky Linux 9.3+** - Limited support ⚠️
- **AlmaLinux 9.3+** - Limited support ⚠️
- **Oracle Linux 9.3+** - Limited support ⚠️
- **Nobara 39+** - Good support ⚠️

**Notes**: COPR repositories needed for some packages. Wayland support varies by version.

#### SUSE Family
- **openSUSE Tumbleweed** - Good support ⚠️
- **openSUSE Leap** - Limited support ⚠️
- **SUSE Linux Enterprise** - Limited support ⚠️

**Notes**: Additional repositories (Packman) may be required.

### 🟠 **Experimental Support** (Advanced users)

#### Independent Distributions
- **Void Linux** - Experimental support 🧪
- **Gentoo Linux** - Experimental support 🧪
- **Funtoo** - Experimental support 🧪
- **Alpine Linux** - Experimental support 🧪
- **Solus** - Limited support 🧪

**Notes**: Manual configuration often required. Compilation times may be significant.

#### NixOS
- **NixOS** - Special support 🔧

**Requirements**: 
- Flakes enabled (recommended)
- Home Manager (recommended)
- Manual configuration.nix modifications needed

### 🔄 **BSD Support** (Experimental)

#### FreeBSD
- **FreeBSD 13+** - Experimental 🧪

**Notes**: 
- Hyprland support experimental on FreeBSD
- LinuxBSD compatibility layer recommended
- Some components may not work

#### OpenBSD
- **OpenBSD** - Not supported ❌

**Alternatives**: dwm, i3, bspwm

#### NetBSD
- **NetBSD** - Not supported ❌

**Alternatives**: pkgsrc window managers

### 🍎 **macOS Support**

- **macOS** - Not supported ❌

**Reason**: Hyprland is a Wayland compositor, not available on macOS

**Alternatives**: 
- Yabai (tiling window manager)
- Rectangle (window manager)
- Amethyst (tiling window manager)

## Package Manager Compatibility

### Native Package Managers

| OS Family | Package Manager | Support Level | AUR Equivalent |
|-----------|----------------|---------------|----------------|
| Arch | pacman | ✅ Full | AUR (yay/paru) |
| Debian | apt | ⚠️ Good | PPAs |
| Red Hat | dnf/yum | ⚠️ Good | COPR |
| SUSE | zypper | ⚠️ Good | OBS |
| Void | xbps | 🧪 Experimental | xbps-src |
| Gentoo | portage | 🧪 Experimental | Overlays |
| Alpine | apk | 🧪 Experimental | Edge repos |
| NixOS | nix | 🔧 Special | Flakes |
| FreeBSD | pkg | 🧪 Experimental | Ports |

### Alternative Package Managers

- **Flatpak**: Supported on most distributions
- **Snap**: Limited support (Ubuntu-focused)
- **AppImage**: Manual installation only

## Hardware Compatibility

### GPU Support

#### NVIDIA
- **RTX Series** - Full support ✅
- **GTX 1000+** - Full support ✅
- **Older Cards** - Limited support ⚠️

**Requirements**:
- NVIDIA drivers 470+
- nvidia-utils
- GBM support

#### AMD
- **RDNA/RDNA2/RDNA3** - Full support ✅
- **GCN 3.0+** - Full support ✅
- **Older Cards** - Limited support ⚠️

**Requirements**:
- Mesa drivers
- AMDGPU kernel module

#### Intel
- **Arc Series** - Full support ✅
- **Iris Xe** - Full support ✅
- **HD Graphics** - Good support ✅

**Requirements**:
- Mesa drivers
- Intel kernel modules

### CPU Architecture

- **x86_64** - Full support ✅
- **ARM64** - Experimental support 🧪
- **ARM32** - Not supported ❌

## Desktop Environment Compatibility

### Wayland Compositors
- **Hyprland** - Primary target ✅
- **Sway** - Compatible ✅
- **River** - Compatible ✅
- **Wayfire** - Partial compatibility ⚠️

### X11 Window Managers
- **i3** - Fallback option ⚠️
- **bspwm** - Fallback option ⚠️
- **dwm** - Fallback option ⚠️

**Note**: X11 support is limited and not recommended.

## Installation Methods by Distribution

### Arch-based (Recommended)
```bash
# Standard installation
./install.sh

# With AUR helper
yay -S hyprland-git
./install.sh --preset gaming
```

### Debian-based
```bash
# Enable additional repositories
sudo apt update
sudo apt install build-essential

# Manual compilation may be needed
./install.sh --preset minimal
```

### Fedora
```bash
# Enable COPR repositories
sudo dnf copr enable solopasha/hyprland

# Install dependencies
sudo dnf install @development-tools
./install.sh
```

### NixOS
```nix
# configuration.nix
{
  programs.hyprland.enable = true;
  programs.hyprland.package = inputs.hyprland.packages.${pkgs.system}.hyprland;
}
```

### FreeBSD
```bash
# Install from ports (experimental)
sudo pkg install hyprland
./install.sh --preset minimal
```

## Known Limitations

### By Distribution

#### Debian/Ubuntu
- Older package versions
- Manual compilation often required
- Limited Wayland support in older releases

#### RHEL/CentOS
- SELinux compatibility issues
- Limited repository availability
- Enterprise focus conflicts with bleeding-edge packages

#### Alpine
- musl libc compatibility issues
- Limited package availability
- Primarily container-focused

#### NixOS
- Requires system configuration changes
- Immutable filesystem complications
- Steep learning curve

### By Hardware

#### Older GPUs
- Limited Wayland support
- Performance issues with effects
- Driver compatibility problems

#### ARM Devices
- Limited testing
- Performance constraints
- Driver availability issues

## Troubleshooting by Platform

### Arch Linux Issues
```bash
# Update keyring
sudo pacman -S archlinux-keyring

# Clear package cache
sudo pacman -Scc

# Force refresh
sudo pacman -Syyu
```

### Debian Issues
```bash
# Enable backports
echo "deb http://deb.debian.org/debian bullseye-backports main" | sudo tee -a /etc/apt/sources.list

# Install build dependencies
sudo apt build-dep hyprland
```

### Fedora Issues
```bash
# Enable RPM Fusion
sudo dnf install https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm

# Update system
sudo dnf update --refresh
```

### NixOS Issues
```bash
# Rebuild system
sudo nixos-rebuild switch

# Update flakes
nix flake update

# Garbage collect
nix-collect-garbage -d
```

## Support Matrix

| Feature | Arch | Debian | Fedora | SUSE | Void | Gentoo | Alpine | NixOS | FreeBSD |
|---------|------|--------|--------|------|------|--------|--------|-------|---------|
| Auto Install | ✅ | ⚠️ | ⚠️ | ⚠️ | 🧪 | 🧪 | 🧪 | 🔧 | 🧪 |
| Package Mgmt | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | 🔧 | ✅ |
| Hyprland | ✅ | ⚠️ | ⚠️ | ⚠️ | ⚠️ | ⚠️ | 🧪 | ✅ | 🧪 |
| Waybar | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ⚠️ | ✅ | 🧪 |
| Rofi | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| AGS | ✅ | ⚠️ | ⚠️ | ⚠️ | 🧪 | 🧪 | 🧪 | ⚠️ | ❌ |
| Themes | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ⚠️ |
| GPU Switch | ✅ | ⚠️ | ⚠️ | ⚠️ | ⚠️ | ⚠️ | 🧪 | ⚠️ | 🧪 |

**Legend:**
- ✅ Full Support
- ⚠️ Partial/Limited Support  
- 🧪 Experimental
- 🔧 Special Configuration Required
- ❌ Not Supported

## Performance Benchmarks & Recommendations

### Recommended System Requirements

#### Minimum Requirements
- **CPU**: Dual-core 2.0GHz (x86_64)
- **RAM**: 4GB (8GB recommended)
- **GPU**: Integrated graphics with OpenGL 3.3+
- **Storage**: 2GB free space
- **Display**: 1920x1080 minimum

#### Recommended Requirements
- **CPU**: Quad-core 3.0GHz+ (x86_64)
- **RAM**: 16GB+
- **GPU**: Dedicated GPU with Vulkan support
- **Storage**: 8GB+ free space (SSD recommended)
- **Display**: 2560x1440 or higher

#### Optimal Requirements
- **CPU**: 8+ cores, 4.0GHz+ (x86_64)
- **RAM**: 32GB+
- **GPU**: RTX 3060+ / RX 6600 XT+ / Arc A750+
- **Storage**: 16GB+ free space (NVMe SSD)
- **Display**: 4K or ultrawide with high refresh rate

### Performance by Hardware

#### GPU Performance Rankings

**Excellent Performance (60+ FPS @ 4K)**
- RTX 4090, 4080, 4070 Ti
- RTX 3080 Ti, 3080, 3070 Ti
- RX 7900 XTX, 7900 XT, 7800 XT
- RX 6900 XT, 6800 XT
- Intel Arc A770, A750

**Good Performance (60+ FPS @ 1440p)**
- RTX 4060 Ti, 4060
- RTX 3070, 3060 Ti
- RX 7700 XT, 7600 XT, 7600
- RX 6700 XT, 6600 XT
- Intel Arc A580, A380

**Acceptable Performance (60+ FPS @ 1080p)**
- RTX 3060, 3050
- RX 6600, 6500 XT
- GTX 1070+, RX 580+
- Intel Iris Xe (with reduced effects)

#### CPU Performance Impact

**Animation & Effects Processing**
- **Intel**: 12th gen+ recommended
- **AMD**: Ryzen 5000+ recommended
- **Older CPUs**: Reduce animation complexity

**Compilation Times** (for source builds)
- **High-end (16+ cores)**: 5-10 minutes
- **Mid-range (8-12 cores)**: 15-25 minutes
- **Budget (4-6 cores)**: 30-45 minutes
- **Low-end (2-4 cores)**: 60+ minutes

### Performance Optimization by Distribution

#### Arch Linux
```bash
# Enable multilib for better performance
sudo pacman -S lib32-mesa lib32-vulkan-radeon lib32-nvidia-utils

# Install performance tools
sudo pacman -S gamemode mangohud

# Optimize kernel parameters
echo 'vm.max_map_count=2147483642' | sudo tee -a /etc/sysctl.conf
```

#### Debian/Ubuntu
```bash
# Enable hardware acceleration
sudo apt install va-driver-all vdpau-driver-all

# Install performance monitoring
sudo apt install htop iotop intel-gpu-tools

# Optimize for gaming
sudo apt install gamemode
```

#### Fedora
```bash
# Enable RPM Fusion for multimedia
sudo dnf install @multimedia

# Install performance tools
sudo dnf install gamemode mangohud

# SELinux optimizations
sudo setsebool -P use_virtualbox 1
```

## Mobile & Embedded Device Support

### ARM64 Support Status

#### Raspberry Pi
- **Pi 5 (8GB)**: Experimental support 🧪
- **Pi 4 (8GB)**: Limited support ⚠️
- **Pi 4 (4GB)**: Basic support ⚠️
- **Pi 3 & older**: Not recommended ❌

**Setup for Raspberry Pi:**
```bash
# Increase GPU memory split
echo 'gpu_mem=128' | sudo tee -a /boot/config.txt

# Enable KMS driver
echo 'dtoverlay=vc4-kms-v3d' | sudo tee -a /boot/config.txt

# Install with minimal preset
./install.sh --preset minimal --arm64
```

#### ARM Chromebooks
- **Recent Chromebooks**: Experimental support 🧪
- **Linux apps enabled**: Required
- **Developer mode**: Recommended

**Supported Models:**
- Lenovo Duet 5 Chromebook
- ASUS Chromebook Flip CM5
- HP Chromebook x2 11

#### Pine64 Devices
- **PineBook Pro**: Basic support ⚠️
- **Pine64 ROCKPro64**: Basic support ⚠️
- **PinePhone**: Not supported ❌

#### Other ARM64 Devices
- **NVIDIA Jetson**: Experimental support 🧪
- **Apple Silicon (M1/M2)**: Not supported ❌
- **Qualcomm Snapdragon**: Not supported ❌

### Performance Expectations (ARM64)

#### Raspberry Pi 5
- **1080p**: 30-45 FPS with minimal effects
- **1440p**: 15-25 FPS (not recommended)
- **Animations**: Reduced complexity required
- **Memory usage**: 2-3GB typical

#### Raspberry Pi 4
- **1080p**: 20-30 FPS with basic effects
- **Higher resolutions**: Not recommended
- **Animations**: Minimal only
- **Memory usage**: 1.5-2.5GB typical

### Mobile-Specific Optimizations

```bash
# Reduce memory usage
export HYPR_MOBILE_OPTIMIZATIONS=1

# Disable heavy effects
export HYPR_REDUCE_ANIMATIONS=1

# Lower rendering quality
export HYPR_LOW_QUALITY_MODE=1

# Install with mobile preset
./install.sh --preset mobile
```

## Container & Virtualization Support

### Docker Support

#### Host Requirements
- Docker with GPU passthrough
- X11 or Wayland forwarding
- Privileged container mode

```bash
# Build container
docker build -t hyprsupreme-builder .

# Run with GPU support (NVIDIA)
docker run --runtime=nvidia --gpus all \
  -v /tmp/.X11-unix:/tmp/.X11-unix \
  -e DISPLAY=$DISPLAY \
  hyprsupreme-builder

# Run with GPU support (AMD)
docker run --device=/dev/dri \
  -v /tmp/.X11-unix:/tmp/.X11-unix \
  -e DISPLAY=$DISPLAY \
  hyprsupreme-builder
```

### Virtual Machine Support

#### VMware
- **VMware Workstation Pro**: Limited support ⚠️
- **VMware Player**: Limited support ⚠️
- **3D acceleration**: Required
- **Memory**: 8GB+ recommended

#### VirtualBox
- **VirtualBox 7.0+**: Basic support ⚠️
- **Guest Additions**: Required
- **3D acceleration**: Enable
- **Memory**: 6GB+ recommended

#### QEMU/KVM
- **QEMU 7.0+**: Good support ✅
- **GPU passthrough**: Recommended
- **virtio-gpu**: Supported
- **Memory**: 8GB+ recommended

```bash
# QEMU with GPU passthrough
qemu-system-x86_64 \
  -enable-kvm \
  -cpu host \
  -m 8192 \
  -device virtio-gpu-pci \
  -display gtk,gl=on \
  -device vfio-pci,host=01:00.0
```

#### Hyper-V
- **Windows 11**: Basic support ⚠️
- **Enhanced Session**: Required
- **GPU virtualization**: Limited
- **Performance**: Reduced

### Cloud/Remote Support

#### AWS EC2
- **G4 instances**: Good support ✅
- **G3 instances**: Limited support ⚠️
- **NICE DCV**: Recommended
- **GPU instances**: Required for full experience

#### Google Cloud
- **N1 with GPUs**: Good support ✅
- **Remote desktop**: Required
- **Preemptible instances**: Cost-effective testing

#### Azure
- **NC/NV series**: Good support ✅
- **Remote desktop**: Required
- **GPU optimization**: Manual setup needed

### Limitations in Virtual Environments

#### Performance Impact
- 20-40% performance reduction typical
- GPU passthrough recommended
- Memory overhead significant
- Storage I/O bottlenecks common

#### Feature Limitations
- Hardware-specific features unavailable
- Some GPU effects may not work
- Audio/video sync issues possible
- Multi-monitor support limited

## Specific Hardware Model Support

### Laptop Compatibility

#### Gaming Laptops
**Excellent Support:**
- ASUS ROG series (2020+)
- MSI Gaming series (2020+)
- Acer Predator series (2020+)
- Alienware (2020+)
- Razer Blade (2020+)

**Good Support:**
- Lenovo Legion series
- HP Omen series
- Dell G-series
- ASUS TUF series

#### Business Laptops
**Good Support:**
- ThinkPad T/X/P series (2019+)
- Dell Latitude (2019+)
- HP EliteBook (2019+)
- Surface Laptop (2020+)

**Limited Support:**
- MacBook Pro (Intel) - Boot Camp only
- Older business laptops (<2019)
- Chromebooks (varies by model)

### Desktop Compatibility

#### Pre-built Systems
**Excellent Support:**
- Custom gaming PCs
- Workstations with discrete GPUs
- Mini-ITX gaming systems

**Good Support:**
- Dell OptiPlex (recent)
- HP EliteDesk (recent)
- Lenovo ThinkCentre (recent)

**Limited Support:**
- All-in-one PCs
- Older office computers
- Systems with integrated-only graphics

### Graphics Card Specific Notes

#### NVIDIA Specific
**RTX 4000 Series:**
- Full feature support
- Excellent performance
- Ray tracing effects available
- DLSS in supported applications

**RTX 3000 Series:**
- Full feature support
- Excellent performance
- Some ray tracing effects
- DLSS support

**GTX 1000 Series:**
- Good basic support
- Limited advanced effects
- No ray tracing
- No DLSS

#### AMD Specific
**RDNA3 (RX 7000):**
- Excellent support
- Full feature set
- FSR support
- AV1 encoding

**RDNA2 (RX 6000):**
- Excellent support
- Most features available
- FSR support
- Good performance

**RDNA1 (RX 5000):**
- Good support
- Some newer features limited
- Solid performance

#### Intel Arc Specific
**Arc A-Series:**
- Growing support
- Good performance in newer games
- XeSS support
- Some compatibility issues with older software

### Monitor Compatibility

#### High Refresh Rate
- **144Hz+**: Full support ✅
- **240Hz+**: Full support ✅
- **360Hz+**: Full support ✅
- **Variable refresh**: G-Sync/FreeSync supported

#### Resolution Support
- **1080p**: Excellent ✅
- **1440p**: Excellent ✅
- **4K**: Excellent ✅
- **8K**: Limited (hardware dependent) ⚠️
- **Ultrawide**: Excellent ✅
- **Multi-monitor**: Excellent ✅

#### HDR Support
- **HDR10**: Good support ✅
- **HDR10+**: Limited support ⚠️
- **Dolby Vision**: Limited support ⚠️
- **Auto HDR**: Varies by application

## Getting Help

### Documentation
- [Arch Wiki - Hyprland](https://wiki.archlinux.org/title/Hyprland)
- [Hyprland Official Docs](https://hyprland.org)
- [Wayland Documentation](https://wayland.freedesktop.org)

### Community Support
- [GitHub Issues](https://github.com/GeneticxCln/HyprSupreme-Builder/issues)
- [Discord Server](https://discord.gg/hyprland)
- [Reddit r/hyprland](https://reddit.com/r/hyprland)

### Distribution-Specific Help
- **Arch**: [Arch Forums](https://bbs.archlinux.org)
- **Debian**: [Debian User Forums](https://forums.debian.net)
- **Fedora**: [Fedora Discussion](https://discussion.fedoraproject.org)
- **NixOS**: [NixOS Discourse](https://discourse.nixos.org)

## Contributing Compatibility

Help us improve compatibility by:

1. Testing on your distribution
2. Reporting issues with logs
3. Submitting package mappings
4. Contributing distribution-specific fixes
5. Updating documentation

See [CONTRIBUTING.md](CONTRIBUTING.md) for details.


# 🚀 HyprSupreme-Builder

## Ultimate Hyprland Configuration Builder

**HyprSupreme-Builder** combines the best features from the most popular Hyprland configurations into one powerful, modular installation system.

<div align="center">

![GitHub Repo stars](https://img.shields.io/github/stars/GeneticxCln/HyprSupreme-Builder?style=for-the-badge&color=cba6f7) 
![GitHub last commit](https://img.shields.io/github/last-commit/GeneticxCln/HyprSupreme-Builder?style=for-the-badge&color=b4befe) 
![GitHub repo size](https://img.shields.io/github/repo-size/GeneticxCln/HyprSupreme-Builder?style=for-the-badge&color=cba6f7)

</div>

## 🎯 What Makes HyprSupreme Special?

This project merges the **best features** from these legendary Hyprland configurations:

- 🎨 **[JaKooLit](https://github.com/JaKooLit/Arch-Hyprland)** - Comprehensive package management & AGS integration
- 🌟 **[ML4W](https://github.com/mylinuxforwork/dotfiles)** - Professional workflows & ML4W scripts
- 🔥 **[HyDE](https://github.com/prasanthrangan/hyprdots)** - Dynamic theming system & Hyde CLI
- ⚡ **[End-4](https://github.com/end-4/dots-hyprland)** - Modern widgets & advanced animations
- 🎪 **[Prasanta](https://github.com/prasanthrangan/hyprdots)** - Beautiful themes & smooth transitions

## ✨ Key Features

### 🎛️ **Modular Configuration System**
- Choose individual components from different configs
- Mix and match features as you prefer
- Easy enable/disable of specific modules

### 🎨 **Advanced Theming Engine**
- **HyDE's dynamic theming** with wallpaper-based color schemes
- **End-4's modern widgets** and smooth animations
- **JaKooLit's comprehensive themes** collection
- **ML4W's professional layouts** for productivity

### 🚀 **Smart Installation**
- Automatic dependency resolution
- Intelligent package management
- Rollback system for safety
- Multi-distro support (Arch, EndeavourOS, CachyOS, Manjaro)

### 🔧 **Professional Workflows**
- **ML4W's productivity tools** and shortcuts
- **HyDE's CLI management** system
- **End-4's modern workspace** organization
- **JaKooLit's comprehensive keybinds**

### 🎯 **Advanced Components**
- **AGS v2.0+ support** with modern widgets
- **Waybar configurations** from all major configs
- **Rofi/Wofi menus** with unified styling
- **SDDM themes** collection
- **GTK themes** harmonization

## 🛠️ Installation

### Quick Install (Recommended)
```bash
curl -fsSL https://raw.githubusercontent.com/GeneticxCln/HyprSupreme-Builder/main/install.sh | bash
```

### Manual Installation
```bash
git clone https://github.com/GeneticxCln/HyprSupreme-Builder.git
cd HyprSupreme-Builder
chmod +x install.sh
./install.sh
```

### With Preset Configuration
```bash
./install.sh --preset gaming    # Gaming-optimized setup
./install.sh --preset work      # Professional workflow
./install.sh --preset minimal   # Lightweight setup
./install.sh --preset showcase  # Eye-candy focused
```

## 🎮 Available Presets

| Preset | Description | Best For |
|--------|-------------|----------|
| `showcase` | Maximum eye-candy, all animations | Screenshots, demos |
| `gaming` | Performance-optimized, minimal effects | Gaming, streaming |
| `work` | Productivity-focused, ML4W workflows | Development, productivity |
| `minimal` | Lightweight, essential features only | Older hardware, simplicity |
| `hybrid` | Balanced mix of all configs | Daily driving |

## 🎨 Component Matrix

| Feature | JaKooLit | ML4W | HyDE | End-4 | Prasanta | HyprSupreme |
|---------|----------|------|------|-------|----------|-------------|
| AGS Widgets | ✅ v1.9 | ❌ | ❌ | ✅ v2.0+ | ❌ | ✅ **Best of Both** |
| Dynamic Themes | ❌ | ❌ | ✅ | ❌ | ✅ | ✅ **Enhanced** |
| ML4W Scripts | ❌ | ✅ | ❌ | ❌ | ❌ | ✅ **Integrated** |
| Hyde CLI | ❌ | ❌ | ✅ | ❌ | ✅ | ✅ **Improved** |
| Modern Animations | ❌ | ❌ | ❌ | ✅ | ❌ | ✅ **Optimized** |
| Package Management | ✅ | ✅ | ✅ | ❌ | ✅ | ✅ **Supreme** |

## 🗂️ Project Structure

```
HyprSupreme-Builder/
├── 📁 configs/              # Configuration modules
│   ├── 📁 jakoolit/         # JaKooLit components
│   ├── 📁 ml4w/             # ML4W components  
│   ├── 📁 hyde/             # HyDE components
│   ├── 📁 end4/             # End-4 components
│   └── 📁 prasanta/         # Prasanta components
├── 📁 modules/              # Installation modules
│   ├── 📁 core/             # Core Hyprland setup
│   ├── 📁 themes/           # Theming system
│   ├── 📁 widgets/          # AGS/Widget modules
│   └── 📁 scripts/          # Utility scripts
├── 📁 presets/              # Preset configurations
├── 📁 tools/                # Management tools
└── 📄 install.sh            # Main installer
```

## 🎯 Roadmap

### Phase 1 - Foundation ✅
- [x] Project structure setup
- [x] Basic installer framework
- [x] Configuration parser

### Phase 2 - Core Integration 🔄
- [ ] JaKooLit modules integration
- [ ] ML4W scripts adaptation
- [ ] HyDE theming system
- [ ] End-4 widgets port
- [ ] Prasanta components

### Phase 3 - Enhancement 📋
- [ ] Unified theme engine
- [ ] Advanced preset system
- [ ] GUI installer (optional)
- [ ] Auto-update mechanism

### Phase 4 - Advanced Features 📋
- [ ] Cloud config sync
- [ ] Community theme sharing
- [ ] Performance optimization
- [ ] Multi-monitor optimization

## 🤝 Contributing

We welcome contributions! Please see our [Contributing Guide](CONTRIBUTING.md) for details.

### How to Contribute:
1. Fork this repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📸 Gallery

*Coming soon - Screenshots from all integrated configurations*

## 🙏 Credits & Acknowledgments

Huge thanks to the original creators:
- **[JaKooLit](https://github.com/JaKooLit)** - For the comprehensive Arch-Hyprland setup
- **[ML4W](https://github.com/mylinuxforwork)** - For professional workflow tools
- **[HyDE Team](https://github.com/prasanthrangan)** - For dynamic theming innovation
- **[End-4](https://github.com/end-4)** - For modern widget development
- **[Prasanta](https://github.com/prasanthrangan)** - For beautiful theme designs

## 📄 License

This project is licensed under the GPL-3.0 License - see the [LICENSE](LICENSE) file for details.

## 💖 Support

If you find this project helpful:
- ⭐ Star this repository
- 🐛 Report issues
- 💡 Suggest features
- 🤝 Contribute code

---

<div align="center">

**Made with ❤️ by the Hyprland Community**

*Combining the best of all worlds into one supreme experience*

</div>


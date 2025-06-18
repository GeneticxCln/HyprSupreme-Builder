# 🚀 HyprSupreme Community Platform - Quick Commands

## 🌐 Web Interface

### Start Web Server:
```bash
# Method 1: Simple launcher
./launch_web.sh

# Method 2: Manual
cd community && ../community_venv/bin/python web_interface.py

# Method 3: Interactive startup
./start_community.sh
```

**Then visit:** http://localhost:5000

---

## 💻 CLI Commands

### Core Platform Test:
```bash
./community_venv/bin/python community/community_platform.py
```

### Discover Themes:
```bash
./community_venv/bin/python tools/hyprsupreme-community.py discover
```

### Search Themes:
```bash
./community_venv/bin/python tools/hyprsupreme-community.py search "minimal"
```

### Community Stats:
```bash
./community_venv/bin/python tools/hyprsupreme-community.py stats --global
```

### Share Theme:
```bash
./community_venv/bin/python tools/hyprsupreme-community.py share catppuccin-supreme --message "Amazing theme!"
```

---

## 🔧 Testing & Verification

### Test Keybindings:
```bash
./test_keybindings.sh
```

### Verify Setup:
```bash
./verify_community_setup.sh
```

### Test Connectivity:
```bash
./test_community_connectivity.sh
```

---

## 📁 File Locations

- **Web Interface:** `community/web_interface.py`
- **Core Platform:** `community/community_platform.py`
- **CLI Tools:** `tools/hyprsupreme-community.py`
- **Virtual Environment:** `community_venv/`
- **Templates:** `community/templates/`

---

## 🐛 Troubleshooting

### "File not found" errors:
- Ensure you're in the `/home/alex/HyprSupreme-Builder` directory
- Use the provided launcher scripts
- Check file paths with: `find . -name "*.py" | grep -E "(web_interface|community_platform)"`

### Virtual environment issues:
- Recreate: `rm -rf community_venv && python3 -m venv community_venv`
- Install packages: `./community_venv/bin/pip install flask werkzeug requests jinja2`

### Import errors:
- Ensure you're using the virtual environment Python: `./community_venv/bin/python`
- Check installed packages: `./community_venv/bin/pip list`

---

## 🎯 Quick Start Guide

1. **Verify setup:**
   ```bash
   ./verify_community_setup.sh
   ```

2. **Launch web interface:**
   ```bash
   ./launch_web.sh
   ```

3. **Open browser:**
   Visit http://localhost:5000

4. **Test CLI:**
   ```bash
   ./community_venv/bin/python tools/hyprsupreme-community.py discover
   ```

---

*Run from HyprSupreme-Builder root directory: `/home/alex/HyprSupreme-Builder`*


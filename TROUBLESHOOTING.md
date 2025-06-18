# 🔧 HyprSupreme-Builder Troubleshooting Guide

## 🚨 Common Issues and Solutions

### Installation Issues

#### Issue: Permission Denied During Installation
**Symptoms:**
```bash
./install.sh: Permission denied
```

**Solution:**
```bash
chmod +x install.sh
./install.sh
```

#### Issue: Missing Dependencies
**Symptoms:**
```
Package 'hyprland' not found
Package 'waybar' not found
```

**Solutions:**
1. **Arch Linux:**
   ```bash
   sudo pacman -S hyprland waybar rofi kitty
   ```

2. **Ubuntu/Debian:**
   ```bash
   # Add required repositories first
   sudo add-apt-repository ppa:hyprland/hyprland
   sudo apt update
   sudo apt install hyprland waybar rofi kitty
   ```

3. **Fedora:**
   ```bash
   sudo dnf copr enable solopasha/hyprland
   sudo dnf install hyprland waybar rofi kitty
   ```

#### Issue: AUR Helper Required
**Symptoms:**
```
No AUR helper found. Please install yay or paru
```

**Solution:**
```bash
# Install yay
git clone https://aur.archlinux.org/yay.git
cd yay
makepkg -si

# Or install paru
git clone https://aur.archlinux.org/paru.git
cd paru
makepkg -si
```

---

### Configuration Issues

#### Issue: Hyprland Won't Start
**Symptoms:**
- Black screen after login
- Hyprland crashes immediately
- Error messages in logs

**Diagnostics:**
```bash
# Check Hyprland logs
journalctl -u display-manager --no-pager
cat ~/.cache/hyprland/hyprland.log

# Test Hyprland configuration
hyprctl reload
```

**Solutions:**
1. **Backup and reset configuration:**
   ```bash
   cp ~/.config/hypr/hyprland.conf ~/.config/hypr/hyprland.conf.backup
   ./hyprsupreme --reset-config
   ```

2. **Check GPU drivers:**
   ```bash
   # For NVIDIA
   nvidia-smi
   
   # For AMD
   lspci | grep VGA
   ```

#### Issue: Waybar Not Appearing
**Symptoms:**
- No status bar visible
- Waybar process not running

**Diagnostics:**
```bash
# Check if Waybar is running
pgrep waybar

# Test Waybar configuration
waybar --config ~/.config/waybar/config --style ~/.config/waybar/style.css
```

**Solutions:**
1. **Restart Waybar:**
   ```bash
   pkill waybar
   waybar &
   ```

2. **Check configuration syntax:**
   ```bash
   # Validate JSON configuration
   python3 -m json.tool ~/.config/waybar/config
   ```

#### Issue: Keybindings Not Working
**Symptoms:**
- Keyboard shortcuts don't respond
- Some keys work, others don't

**Diagnostics:**
```bash
# Test keybindings
./test_keybindings.sh

# Check Hyprland keybind configuration
hyprctl binds
```

**Solutions:**
1. **Reload Hyprland configuration:**
   ```bash
   hyprctl reload
   ```

2. **Reset keybindings:**
   ```bash
   ./hyprsupreme --reset-keybindings
   ```

---

### Community Platform Issues

#### Issue: Web Interface Won't Start
**Symptoms:**
```
Error: Address already in use
Failed to start web server
```

**Diagnostics:**
```bash
# Check what's using port 5000
sudo netstat -tulpn | grep :5000
sudo lsof -i :5000
```

**Solutions:**
1. **Kill process using port:**
   ```bash
   sudo pkill -f "python.*5000"
   # Or change port
   export FLASK_PORT=5001
   ./launch_web.sh
   ```

2. **Use different port:**
   ```bash
   ./launch_web.sh --port 8080
   ```

#### Issue: Database Connection Error
**Symptoms:**
```
sqlite3.OperationalError: database is locked
PermissionError: [Errno 13] Permission denied
```

**Solutions:**
1. **Fix permissions:**
   ```bash
   chmod 755 ~/.config/hyprsupreme
   chmod 644 ~/.config/hyprsupreme/community.db
   ```

2. **Reset database:**
   ```bash
   ./hyprsupreme --reset-database
   ```

#### Issue: Themes Not Loading
**Symptoms:**
- Empty theme list
- Download errors
- Corrupted themes

**Diagnostics:**
```bash
# Check theme directory
ls -la ~/.config/hyprsupreme/themes/

# Test community connectivity
./test_community_connectivity.sh
```

**Solutions:**
1. **Refresh theme cache:**
   ```bash
   ./hyprsupreme --refresh-themes
   ```

2. **Clear theme cache:**
   ```bash
   rm -rf ~/.cache/hyprsupreme/themes/
   ./hyprsupreme --update-themes
   ```

---

### Performance Issues

#### Issue: High CPU Usage
**Symptoms:**
- System feels sluggish
- High CPU usage by Hyprland/Waybar

**Diagnostics:**
```bash
# Monitor CPU usage
htop
# Check specific processes
ps aux | grep -E "(hyprland|waybar|rofi)"
```

**Solutions:**
1. **Disable animations temporarily:**
   ```bash
   echo "animations {
       enabled = false
   }" >> ~/.config/hypr/hyprland.conf
   hyprctl reload
   ```

2. **Reduce Waybar update frequency:**
   ```json
   {
       "cpu": {
           "interval": 10
       },
       "memory": {
           "interval": 30
       }
   }
   ```

#### Issue: High Memory Usage
**Symptoms:**
- System running out of RAM
- Swap usage increasing

**Diagnostics:**
```bash
# Check memory usage
free -h
# Check process memory usage
ps aux --sort=-%mem | head -10
```

**Solutions:**
1. **Restart resource-heavy processes:**
   ```bash
   pkill waybar && waybar &
   hyprctl reload
   ```

2. **Clear caches:**
   ```bash
   ./hyprsupreme --clear-cache
   ```

---

### Theme Issues

#### Issue: Theme Installation Fails
**Symptoms:**
```
Error: Theme validation failed
Error: Missing required files
```

**Diagnostics:**
```bash
# Validate theme structure
./hyprsupreme --validate-theme theme-name

# Check theme requirements
cat ~/.config/hyprsupreme/themes/theme-name/requirements.json
```

**Solutions:**
1. **Install missing dependencies:**
   ```bash
   ./hyprsupreme --install-theme-deps theme-name
   ```

2. **Download fresh copy:**
   ```bash
   ./hyprsupreme --redownload-theme theme-name
   ```

#### Issue: Theme Looks Broken
**Symptoms:**
- Missing icons
- Wrong colors
- Layout issues

**Solutions:**
1. **Install required fonts:**
   ```bash
   # Install Nerd Fonts
   sudo pacman -S ttf-nerd-fonts-symbols-2048-em
   # Or manually
   ./hyprsupreme --install-fonts
   ```

2. **Reset theme to defaults:**
   ```bash
   ./hyprsupreme --reset-theme
   ```

---

### Docker Issues

#### Issue: Container Won't Start
**Symptoms:**
```
docker: Error response from daemon
Container exits immediately
```

**Diagnostics:**
```bash
# Check Docker logs
docker logs hyprsupreme-web

# Check container status
docker ps -a
```

**Solutions:**
1. **Rebuild container:**
   ```bash
   docker-compose down
   docker-compose build --no-cache
   docker-compose up
   ```

2. **Check permissions:**
   ```bash
   # Fix volume permissions
   sudo chown -R 1000:1000 ./data ./config ./logs
   ```

#### Issue: Port Conflicts
**Symptoms:**
```
Port 5000 is already allocated
```

**Solutions:**
1. **Change port in docker-compose.yml:**
   ```yaml
   ports:
     - '8080:5000'  # Change from 5000:5000
   ```

2. **Stop conflicting services:**
   ```bash
   sudo lsof -i :5000
   sudo kill <PID>
   ```

---

### Development Issues

#### Issue: Pre-commit Hooks Failing
**Symptoms:**
```
pre-commit hook failed
flake8 errors
black formatting issues
```

**Solutions:**
1. **Fix formatting:**
   ```bash
   # Auto-fix common issues
   black .
   isort .
   
   # Run pre-commit manually
   pre-commit run --all-files
   ```

2. **Update pre-commit:**
   ```bash
   pre-commit autoupdate
   pre-commit install
   ```

#### Issue: Tests Failing
**Symptoms:**
```
pytest failures
BATS test errors
Import errors
```

**Diagnostics:**
```bash
# Run specific tests
pytest tests/unit/ -v
pytest tests/integration/ -v
bats tests/test_*.bats

# Check Python path
python3 -c "import sys; print('\n'.join(sys.path))"
```

**Solutions:**
1. **Install development dependencies:**
   ```bash
   ./setup-dev.sh
   source venv/bin/activate
   pip install -e ".[dev,test]"
   ```

2. **Fix Python path:**
   ```bash
   export PYTHONPATH="${PYTHONPATH}:$(pwd)"
   ```

---

## 🔍 Diagnostic Commands

### System Information
```bash
# Get system info
./hyprsupreme --system-info

# Check Hyprland version
hyprctl version

# Check all dependencies
./hyprsupreme --check-deps
```

### Log Analysis
```bash
# Application logs
tail -f logs/hyprsupreme.log

# System logs
journalctl -f -u display-manager

# Hyprland logs
tail -f ~/.cache/hyprland/hyprland.log
```

### Configuration Validation
```bash
# Validate all configurations
./hyprsupreme --validate-config

# Test keybindings
./test_keybindings.sh

# Test community connectivity
./test_community_connectivity.sh
```

---

## 📞 Getting Help

### Before Seeking Help
1. **Check logs** for error messages
2. **Run diagnostic commands** listed above
3. **Try suggested solutions** for your issue
4. **Search existing issues** on GitHub

### Creating a Bug Report
Include the following information:

```bash
# System information
./hyprsupreme --system-info > system-info.txt

# Configuration
./hyprsupreme --export-config > config-export.txt

# Logs (last 50 lines)
tail -50 logs/hyprsupreme.log > recent-logs.txt
```

### Support Channels
- **GitHub Issues**: https://github.com/GeneticxCln/HyprSupreme-Builder/issues
- **Discussions**: https://github.com/GeneticxCln/HyprSupreme-Builder/discussions
- **Documentation**: Check all `.md` files in the project

---

## 🛠️ Advanced Troubleshooting

### Complete Reset
```bash
# Backup current configuration
./hyprsupreme --backup-all

# Complete reset (use with caution)
./hyprsupreme --factory-reset

# Restore from backup if needed
./hyprsupreme --restore-backup backup-id
```

### Debug Mode
```bash
# Enable debug logging
export HYPRSUPREME_DEBUG=1
./hyprsupreme --debug

# Verbose mode
./hyprsupreme -vvv
```

### Manual Recovery
```bash
# Restore original configs
cp ~/.config/hypr/hyprland.conf.backup ~/.config/hypr/hyprland.conf
cp ~/.config/waybar/config.backup ~/.config/waybar/config

# Reset to default theme
./hyprsupreme --theme default
```

---

*Keep this guide updated as new issues are discovered and resolved.*


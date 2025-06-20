# 🔧 HyprSupreme-Builder Troubleshooting Guide

> **📘 Note:** This guide has been updated for v2.2.0 with new error codes and troubleshooting procedures.

## 🚨 Common Issues and Solutions

### v2.2.0 Error Codes

#### Error: INSTALLATION_STATE_CORRUPTED
**Symptoms:**
```
Error: Installation state is corrupted or incomplete (code: E_STATE_CORRUPTED)
Unable to determine installation status
```

**Solutions:**
```bash
# Repair installation state
./hyprsupreme --repair-state

# If repair fails, reset state and verify installation
./hyprsupreme --reset-state
./hyprsupreme --verify-install
```

#### Error: NETWORK_CONFIGURATION_FAILED
**Symptoms:**
```
Error: Failed to configure network management (code: E_NETWORK)
NetworkManager service not responding
```

**Solutions:**
```bash
# Skip network configuration temporarily
./install.sh --skip-network

# Manual network setup after installation
./modules/core/install_network.sh configure

# Reset NetworkManager configuration
sudo systemctl restart NetworkManager
./modules/core/install_network.sh configure
```

#### Error: AUDIO_BACKEND_CONFLICT
**Symptoms:**
```
Error: Audio backend conflict detected (code: E_AUDIO_CONFLICT)
Multiple audio servers running: PipeWire and PulseAudio
```

**Solutions:**
```bash
# Choose PipeWire (recommended)
./hyprsupreme --audio-backend=pipewire

# OR choose PulseAudio
./hyprsupreme --audio-backend=pulseaudio

# Reset audio configuration
./hyprsupreme --reset-audio
```

#### Error: HARDWARE_DETECTION_FAILED
**Symptoms:**
```
Error: Hardware detection failed (code: E_HARDWARE)
Unable to detect GPU type or features
```

**Solutions:**
```bash
# Run hardware detection manually
./tools/gpu_diagnostics.sh --verbose

# Force specific GPU type
./hyprsupreme --set-gpu=nvidia
./hyprsupreme --set-gpu=amd
./hyprsupreme --set-gpu=intel

# Disable hardware acceleration temporarily
./hyprsupreme --disable-acceleration
```

#### Error: DEPENDENCY_VERSION_MISMATCH
**Symptoms:**
```
Error: Dependency version mismatch (code: E_DEPENDENCY)
Python version 3.7.9 is below minimum requirement (3.9.0)
```

**Solutions:**
```bash
# Run dependency validator with fix option
./modules/core/dependency_validator.sh fix

# Manually install required version
sudo pacman -S python39   # Arch-based
sudo apt install python3.9   # Debian-based
sudo dnf install python39   # Fedora

# Use custom Python path
export HYPRSUPREME_PYTHON_PATH=/path/to/python3.9
./install.sh
```

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

#### Issue: Installation Interrupted
**Symptoms:**
```
Installation was interrupted and did not complete
Some components are missing or misconfigured
```

**Solutions:**
```bash
# Resume installation (new in v2.2.0)
./install.sh --resume

# If resume fails, use repair option
./install.sh --repair

# For clean restart with state preservation
./install.sh --clean --preserve-config
```

#### Issue: Validation Errors During Installation
**Symptoms:**
```
Validation failed: 3 components did not pass integrity check
ERROR: Component 'network' failed validation
```

**Solutions:**
```bash
# Run targeted repair for specific components
./hyprsupreme --repair-component network
./hyprsupreme --repair-component audio

# Run full validation with detailed output
./hyprsupreme --validate-all --verbose

# Force installation to continue despite validation errors
./install.sh --force-continue
```

---

### Network Management Issues (New in v2.2.0)

#### Issue: WiFi Not Detected
**Symptoms:**
```
No WiFi interfaces found
NetworkManager doesn't show wireless connections
```

**Diagnostics:**
```bash
# Check WiFi hardware
./modules/core/install_network.sh test
nmcli radio wifi
rfkill list wifi
```

**Solutions:**
```bash
# Enable WiFi if disabled
rfkill unblock wifi
nmcli radio wifi on

# Reinstall WiFi drivers
./hyprsupreme --reinstall-wifi-drivers

# For specific hardware issues
./tools/wifi_troubleshooter.sh --detect-hardware
```

#### Issue: NetworkManager Service Failures
**Symptoms:**
```
Failed to connect to NetworkManager
D-Bus error: Service not available
```

**Solutions:**
```bash
# Restart NetworkManager service
sudo systemctl restart NetworkManager

# Check service status
systemctl status NetworkManager

# Recreate NetworkManager configuration
./modules/core/install_network.sh configure --force
```

#### Issue: Network Connectivity Issues
**Symptoms:**
```
Connected to WiFi but no internet
DNS resolution failing
```

**Diagnostics:**
```bash
# Test connectivity
./modules/core/install_network.sh connectivity
ping -c 3 8.8.8.8
nslookup google.com
```

**Solutions:**
```bash
# Reset DNS configuration
./hyprsupreme --reset-dns

# Set custom DNS servers
./hyprsupreme --set-dns-servers 1.1.1.1,8.8.8.8

# Flush DNS cache
sudo systemd-resolve --flush-caches
```

### Audio System Issues (New in v2.2.0)

#### Issue: No Audio Output
**Symptoms:**
```
No sound from any application
Audio devices appear in settings but don't work
```

**Diagnostics:**
```bash
# Check audio system
./modules/core/install_audio.sh test
pactl info
```

**Solutions:**
```bash
# Restart audio services
./hyprsupreme --restart-audio

# Reset audio configuration
./hyprsupreme --reset-audio

# Force reconfiguration
./modules/core/install_audio.sh configure --force
```

#### Issue: Audio Device Switching Problems
**Symptoms:**
```
Can't switch between headphones and speakers
New audio devices not detected
```

**Solutions:**
```bash
# Update device database
./hyprsupreme --update-audio-devices

# Manual device selection
./hyprsupreme --set-default-sink "alsa_output.pci-0000_00_1f.3"

# Test specific device
./modules/core/install_audio.sh test --device "alsa_output.pci-0000_00_1f.3"
```

#### Issue: PipeWire/PulseAudio Conflicts
**Symptoms:**
```
Multiple audio servers running
Audio cutting out or glitching
```

**Solutions:**
```bash
# Switch to PipeWire (recommended)
./hyprsupreme --switch-to-pipewire

# Clean audio state
./hyprsupreme --clean-audio-state

# Manual backend selection
./hyprsupreme --audio-backend=pipewire --restart
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

#### Issue: Configuration Changes Not Applied
**Symptoms:**
```
Changes to configuration files don't take effect
Settings revert after restart
```

**Solutions:**
```bash
# Verify configuration is valid
./hyprsupreme --validate-config

# Force configuration reload
./hyprsupreme --reload-config --force

# Reset to known good configuration
./hyprsupreme --reset-config --keep-backups
```

#### Issue: State Management Problems (New in v2.2.0)
**Symptoms:**
```
Error: Failed to save state (code: E_STATE_SAVE)
Error: State file is corrupted or inaccessible
```

**Diagnostics:**
```bash
# Check state files
ls -la ~/.config/hyprsupreme/state/
./hyprsupreme --state-info
```

**Solutions:**
```bash
# Repair state system
./hyprsupreme --repair-state

# Clear corrupted states but keep backups
./hyprsupreme --clean-states --preserve-backups

# Reset to factory defaults
./hyprsupreme --factory-reset
```

---

### Hardware Detection Issues (New in v2.2.0)

#### Issue: Incorrect GPU Detection
**Symptoms:**
```
GPU incorrectly identified
Wrong drivers being used
Graphics performance issues
```

**Diagnostics:**
```bash
# Run detailed hardware detection
./tools/gpu_diagnostics.sh --verbose
./hyprsupreme --hardware-info
```

**Solutions:**
```bash
# Force specific GPU type
./hyprsupreme --set-gpu=nvidia
./hyprsupreme --set-gpu=amd
./hyprsupreme --set-gpu=intel

# Reinstall correct drivers
./hyprsupreme --reinstall-gpu-drivers

# For hybrid graphics (NVIDIA + Intel)
./hyprsupreme --setup-hybrid-graphics
```

#### Issue: Multi-Monitor Setup Problems
**Symptoms:**
```
Displays have wrong resolution or refresh rate
Secondary monitors not detected
Scaling issues on HiDPI displays
```

**Solutions:**
```bash
# Run display configuration wizard
./hyprsupreme --display-setup

# Manual per-monitor configuration
./tools/resolution_manager.sh --refresh-rate primary=144 secondary=60
./tools/resolution_manager.sh --scale primary=1.0 secondary=1.5

# Reset display configuration
./hyprsupreme --reset-displays
```

#### Issue: Hardware Optimization Failures
**Symptoms:**
```
Performance optimization failed
Error applying optimizations to GPU
```

**Solutions:**
```bash
# Run manual optimization with different profile
./hyprsupreme --optimize-hardware --profile=balanced

# Check for driver issues
./tools/gpu_diagnostics.sh --check-drivers

# Reset to default performance settings
./hyprsupreme --reset-performance
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

#### Issue: Animation Stuttering with New Hardware
**Symptoms:**
- Animations stutter despite powerful hardware
- High CPU/GPU usage during transitions
- Frame drops during workspace switching

**Diagnostics:**
```bash
# Check performance stats
./hyprsupreme --performance-monitor

# Monitor GPU usage
./tools/gpu_monitor.sh --real-time
```

**Solutions:**
```bash
# Update GPU drivers to latest version
./hyprsupreme --update-gpu-drivers

# Optimize animations for your hardware
./hyprsupreme --optimize-animations

# For NVIDIA GPUs
./hyprsupreme --nvidia-fix-animations

# For very high refresh rate displays (144Hz+)
./hyprsupreme --config animations.high_refresh_mode=true
```

---

### Installation Recovery Procedures (New in v2.2.0)

#### Complete Installation Recovery
**When to use:** Installation is severely broken or interrupted

```bash
# Step 1: Back up your current configuration
./hyprsupreme --backup-all --name "pre-recovery"

# Step 2: Run installation recovery
./install.sh --recovery-mode

# Step 3: Verify recovery was successful
./hyprsupreme --verify-install

# If recovery fails, try clean installation with config preservation
./install.sh --clean --preserve-user-config
```

#### Component-Specific Recovery
**When to use:** Specific components (network, audio, etc.) not working

```bash
# For network issues
./modules/core/install_network.sh repair

# For audio issues
./modules/core/install_audio.sh repair

# For GPU driver issues
./tools/gpu_diagnostics.sh --repair

# For configuration issues
./hyprsupreme --repair-config
```

#### State System Recovery
**When to use:** State tracking system corrupted or failing

```bash
# Check state system integrity
./hyprsupreme --verify-state

# Repair state tracking system
./hyprsupreme --repair-state

# Reset state system while preserving configurations
./hyprsupreme --reset-state --preserve-config
```

#### Installation Rollback
**When to use:** Need to revert to previous version

```bash
# List available restore points
./hyprsupreme --list-restore-points

# Rollback to specific version
./hyprsupreme --rollback v2.1.1

# Create new restore point before continuing
./hyprsupreme --create-restore-point "pre-update-$(date +%Y%m%d)"
```

## 🔍 Diagnostic Commands

### System Information
```bash
# Get system info (enhanced in v2.2.0)
./hyprsupreme --system-info --detailed

# Check Hyprland version
hyprctl version

# Check all dependencies with detailed validation
./hyprsupreme --check-deps --validate-versions

# New v2.2.0 system diagnostics
./hyprsupreme --diagnostics --generate-report
./hyprsupreme --health-check
```

### Log Analysis
```bash
# Application logs (enhanced in v2.2.0)
./hyprsupreme --show-logs --level=debug
tail -f logs/hyprsupreme.log

# System logs
journalctl -f -u display-manager

# Hyprland logs
tail -f ~/.cache/hyprland/hyprland.log

# Network diagnostic logs (new in v2.2.0)
./modules/core/install_network.sh logs
tail -f ~/.cache/hyprsupreme/logs/network.log

# Audio diagnostic logs (new in v2.2.0)
./modules/core/install_audio.sh logs
tail -f ~/.cache/hyprsupreme/logs/audio.log

# Installation state logs (new in v2.2.0)
./hyprsupreme --state-logs
tail -f ~/.cache/hyprsupreme/logs/state.log
```

### Configuration Validation
```bash
# Validate all configurations
./hyprsupreme --validate-config

# Test keybindings (enhanced in v2.2.0)
./test_keybindings.sh --interactive
./test_keybindings.sh --detect-conflicts

# Test community connectivity
./test_community_connectivity.sh

# New v2.2.0 validation tools
./hyprsupreme --validate-installation   # Complete installation validation
./hyprsupreme --validate-hardware       # Hardware compatibility check
./hyprsupreme --validate-network        # Network configuration test
./hyprsupreme --validate-audio          # Audio system test
```

---

### Advanced Diagnostics (New in v2.2.0)

```bash
# Generate complete system report
./hyprsupreme --system-report > system-report.txt

# Performance profiling
./hyprsupreme --performance-profile --duration=60

# Hardware compatibility check
./hyprsupreme --hardware-compatibility-check

# Installation integrity verification
./hyprsupreme --verify-integrity --detailed

# Configuration analysis
./hyprsupreme --analyze-config --suggest-optimizations

# Debug mode with verbose output
./hyprsupreme --debug-mode --log-level=trace
```

### New Debugging Tools in v2.2.0

```bash
# Network debugging
./tools/network_debugger.sh --packet-capture
./tools/network_debugger.sh --connection-test
./tools/network_debugger.sh --dns-diagnosis

# Audio debugging
./tools/audio_debugger.sh --list-devices
./tools/audio_debugger.sh --test-playback
./tools/audio_debugger.sh --backend-status

# GPU debugging
./tools/gpu_debugger.sh --performance-test
./tools/gpu_debugger.sh --driver-info
./tools/gpu_debugger.sh --benchmark

# Installation state debugging
./tools/state_debugger.sh --analyze
./tools/state_debugger.sh --repair
./tools/state_debugger.sh --history
```

## 📞 Getting Help

### Before Seeking Help
1. **Check logs** for error messages
2. **Run diagnostic commands** listed above
3. **Try suggested solutions** for your issue
4. **Search existing issues** on GitHub
5. **Generate a system report** using `./hyprsupreme --system-report` (new in v2.2.0)

### Creating a Bug Report
Include the following information:

```bash
# Enhanced system report (new in v2.2.0)
./hyprsupreme --system-report > system-report.txt

# Configuration export
./hyprsupreme --export-config > config-export.txt

# Logs (comprehensive - new in v2.2.0)
./hyprsupreme --export-logs --days=3 > logs-export.txt

# Installation state (new in v2.2.0)
./hyprsupreme --state-info --json > state-info.json

# Error history (new in v2.2.0)
./hyprsupreme --error-history > error-history.txt
```

### Support Channels
- **GitHub Issues**: https://github.com/GeneticxCln/HyprSupreme-Builder/issues
- **Discussions**: https://github.com/GeneticxCln/HyprSupreme-Builder/discussions
- **Documentation**: Check all `.md` files in the project

---

## 🛠️ Advanced Troubleshooting

### Complete Reset
```bash
# Backup current configuration (enhanced in v2.2.0)
./hyprsupreme --backup-all --with-state --compression=high

# Complete reset (use with caution)
./hyprsupreme --factory-reset

# Restore from backup if needed (enhanced in v2.2.0)
./hyprsupreme --restore-backup backup-id --selective="config,themes,keybindings"
```

### Debug Mode
```bash
# Enable debug logging (enhanced in v2.2.0)
export HYPRSUPREME_DEBUG=1
export HYPRSUPREME_LOG_LEVEL=trace
./hyprsupreme --debug

# Verbose mode with component filtering (new in v2.2.0)
./hyprsupreme -vvv --component=network,audio,gpu

# Remote debugging (new in v2.2.0)
./hyprsupreme --remote-debug --port=8080

# Performance debugging (new in v2.2.0)
./hyprsupreme --debug --profile --timeline
```

### Manual Recovery
```bash
# Restore original configs
cp ~/.config/hypr/hyprland.conf.backup ~/.config/hypr/hyprland.conf
cp ~/.config/waybar/config.backup ~/.config/waybar/config

# Reset to default theme
./hyprsupreme --theme default

# Component-specific recovery (new in v2.2.0)
./hyprsupreme --recover-network --from-backup
./hyprsupreme --recover-audio --factory-defaults
./hyprsupreme --recover-display-config --auto-detect

# Time-based recovery (new in v2.2.0)
./hyprsupreme --restore-point --timestamp="2025-06-15T14:30:00"
```

### Emergency Recovery Tools (New in v2.2.0)

```bash
# Rescue mode - minimal environment to fix critical issues
./hyprsupreme --rescue-mode

# Safe mode - load with minimal configuration
./hyprsupreme --safe-mode

# Offline recovery - fix without network dependency
./hyprsupreme --offline-recovery

# Last known good configuration
./hyprsupreme --last-known-good

# Live system state dump (for expert analysis)
./hyprsupreme --dump-state --format=json > system_state_dump.json
```

---

### Common Error Code Reference (v2.2.0)

| Error Code | Description | Common Solution |
|------------|-------------|-----------------|
| `E_STATE_CORRUPTED` | Installation state corruption | `./hyprsupreme --repair-state` |
| `E_NETWORK` | Network configuration failure | `./modules/core/install_network.sh repair` |
| `E_AUDIO_CONFLICT` | Audio backend conflict | `./hyprsupreme --audio-backend=pipewire` |
| `E_HARDWARE` | Hardware detection failure | `./tools/gpu_diagnostics.sh --verbose` |
| `E_DEPENDENCY` | Dependency version mismatch | `./modules/core/dependency_validator.sh fix` |
| `E_PERMISSION` | Permission denied | `chmod +x [script]` or check sudo permissions |
| `E_SERVICE` | Service start/stop failure | `systemctl --user restart [service]` |
| `E_CONFIG` | Configuration file error | `./hyprsupreme --repair-config` |
| `E_INSTALL_INTERRUPTED` | Installation interrupted | `./install.sh --resume` |
| `E_VALIDATION_FAILED` | Installation validation failed | `./hyprsupreme --verify-install --fix` |
| `E_STATE_SAVE` | Failed to save state | `./hyprsupreme --repair-state` |
| `E_STATE_RESTORE` | Failed to restore state | `./hyprsupreme --reset-state` |
| `E_GPU_DRIVER` | GPU driver issue | `./hyprsupreme --reinstall-gpu-drivers` |
| `E_DISPLAY_CONFIG` | Display configuration error | `./hyprsupreme --reset-displays` |
| `E_NETWORK_CONNECT` | Network connection failure | `./modules/core/install_network.sh configure` |
| `E_AUDIO_DEVICE` | Audio device error | `./modules/core/install_audio.sh configure` |

*Keep this guide updated as new issues are discovered and resolved.*


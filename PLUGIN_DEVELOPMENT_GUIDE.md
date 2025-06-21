# 🔧 HyprSupreme-Builder Plugin Development Guide

## 📖 **Complete Plugin Development Documentation**

This comprehensive guide covers everything you need to know to create, test, and distribute plugins for HyprSupreme-Builder.

---

## 🎯 **Plugin System Overview**

HyprSupreme-Builder features a powerful plugin architecture that allows developers to:

- **Extend Core Functionality**: Add new features without modifying core code
- **Hook into Events**: React to theme changes, configuration updates, and system events
- **Create Custom Commands**: Add CLI commands and automation scripts
- **Manage Dependencies**: Automatic dependency resolution and installation
- **Share with Community**: Upload to the community marketplace

---

## 🏗️ **Plugin Architecture**

### **Core Components**

1. **Plugin Manifest** (`manifest.toml` or `manifest.json`)
2. **Hook Scripts** (executable files for event handling)
3. **Command Scripts** (executable files for CLI commands)
4. **Configuration Schema** (optional, for plugin settings)
5. **Assets** (themes, icons, resources)

### **Plugin Lifecycle**

```
Discovery → Loading → Validation → Installation → Activation → Execution
```

---

## 📝 **Creating Your First Plugin**

### **Step 1: Plugin Structure**

Create a directory with the following structure:

```
my-awesome-plugin/
├── manifest.toml              # Plugin metadata
├── scripts/                   # Executable scripts
│   ├── startup.sh            # Startup hook
│   ├── theme_changed.sh      # Theme change hook
│   └── my_command.py         # Custom command
├── config/                   # Configuration files
│   └── schema.json          # Config schema (optional)
├── assets/                   # Plugin assets
│   ├── themes/              # Custom themes
│   └── icons/               # Plugin icons
└── README.md                # Plugin documentation
```

### **Step 2: Create the Manifest**

**`manifest.toml`**:
```toml
[plugin]
name = "my-awesome-plugin"
display_name = "My Awesome Plugin"
version = "1.0.0"
author = "Your Name <your.email@example.com>"
description = "A plugin that does awesome things for Hyprland"
license = "MIT"
repository = "https://github.com/username/my-awesome-plugin"

[requirements]
hyprsupreme_version = ">=2.0.0"
hyprland_version = ">=0.35.0"

[dependencies]
# Other plugins this plugin depends on
required = []
optional = ["workspace-manager"]

[[hooks]]
name = "startup"
description = "Execute when HyprSupreme starts"
script = "scripts/startup.sh"
priority = 10

[[hooks]]
name = "theme_changed"
description = "Execute when theme changes"
script = "scripts/theme_changed.sh"
priority = 5

[[commands]]
name = "my-command"
description = "My custom command"
script = "scripts/my_command.py"
help = "Usage: hyprsupreme plugin exec my-awesome-plugin my-command [args]"

[config]
schema_file = "config/schema.json"
```

### **Step 3: Implement Hook Scripts**

**`scripts/startup.sh`**:
```bash
#!/bin/bash

# Startup hook - runs when HyprSupreme starts
echo "My Awesome Plugin: Starting up!"

# Get current theme
CURRENT_THEME=$(hyprsupreme theme current)
echo "Current theme: $CURRENT_THEME"

# Initialize plugin state
mkdir -p ~/.cache/my-awesome-plugin
echo "initialized" > ~/.cache/my-awesome-plugin/state

# Exit successfully
exit 0
```

**`scripts/theme_changed.sh`**:
```bash
#!/bin/bash

# Theme changed hook - runs when theme changes
NEW_THEME="$1"
OLD_THEME="$2"

echo "My Awesome Plugin: Theme changed from $OLD_THEME to $NEW_THEME"

# Update plugin configuration based on new theme
case "$NEW_THEME" in
    "tokyo-night")
        echo "Applying Tokyo Night optimizations..."
        # Plugin-specific logic here
        ;;
    "catppuccin-mocha")
        echo "Applying Catppuccin optimizations..."
        # Plugin-specific logic here
        ;;
    *)
        echo "Applying default optimizations..."
        ;;
esac

exit 0
```

**`scripts/my_command.py`**:
```python
#!/usr/bin/env python3
"""
Custom command for my-awesome-plugin
"""

import sys
import argparse
import json

def main():
    parser = argparse.ArgumentParser(description='My Awesome Plugin Command')
    parser.add_argument('--status', action='store_true', help='Show plugin status')
    parser.add_argument('--config', help='Update plugin configuration')
    
    args = parser.parse_args()
    
    if args.status:
        print("Plugin Status: Active")
        print("Version: 1.0.0")
        return 0
    
    if args.config:
        try:
            config = json.loads(args.config)
            print(f"Updated configuration: {config}")
            return 0
        except json.JSONDecodeError:
            print("Error: Invalid JSON configuration", file=sys.stderr)
            return 1
    
    print("My Awesome Plugin is working!")
    return 0

if __name__ == '__main__':
    sys.exit(main())
```

---

## 🔧 **Advanced Plugin Features**

### **Configuration Schema**

Create `config/schema.json` for plugin settings:

```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "title": "My Awesome Plugin Configuration",
  "type": "object",
  "properties": {
    "enabled": {
      "type": "boolean",
      "default": true,
      "description": "Enable/disable the plugin"
    },
    "auto_optimize": {
      "type": "boolean",
      "default": true,
      "description": "Automatically optimize settings for new themes"
    },
    "optimization_level": {
      "type": "string",
      "enum": ["low", "medium", "high"],
      "default": "medium",
      "description": "Optimization intensity level"
    },
    "custom_rules": {
      "type": "array",
      "items": {
        "type": "object",
        "properties": {
          "theme": {"type": "string"},
          "action": {"type": "string"}
        }
      },
      "description": "Custom optimization rules"
    }
  },
  "required": ["enabled"]
}
```

### **Dependency Management**

Specify dependencies in your manifest:

```toml
[dependencies]
# Required plugins (installation will fail without these)
required = ["workspace-manager", "theme-switcher"]

# Optional plugins (features may be limited without these)
optional = ["notification-center"]

# Version constraints
[dependencies.versions]
"workspace-manager" = ">=1.0.0"
"theme-switcher" = "~1.2.0"  # Compatible with 1.2.x
```

### **Event System**

Available hooks and their parameters:

| Hook Name | Parameters | Description |
|-----------|------------|-------------|
| `startup` | None | Plugin initialization |
| `shutdown` | None | Plugin cleanup |
| `theme_changed` | `$1=new_theme, $2=old_theme` | Theme switching |
| `config_updated` | `$1=config_file` | Configuration changes |
| `plugin_enabled` | `$1=plugin_name` | Another plugin enabled |
| `plugin_disabled` | `$1=plugin_name` | Another plugin disabled |
| `workspace_changed` | `$1=workspace_id` | Workspace switching |
| `window_opened` | `$1=window_class, $2=window_title` | New window |
| `window_closed` | `$1=window_class, $2=window_title` | Window closed |

---

## 🧪 **Testing Your Plugin**

### **Local Testing**

1. **Install in Development Mode**:
```bash
# Install plugin for testing
hyprsupreme plugin install --dev ./my-awesome-plugin

# Enable plugin
hyprsupreme plugin enable my-awesome-plugin

# Test plugin command
hyprsupreme plugin exec my-awesome-plugin my-command --status
```

2. **Test Hooks**:
```bash
# Trigger theme change to test hook
hyprsupreme theme apply tokyo-night

# Check plugin logs
tail -f ~/.cache/hyprsupreme/logs/plugins/my-awesome-plugin.log
```

3. **Debug Mode**:
```bash
# Enable debug logging
hyprsupreme plugin debug my-awesome-plugin

# Run with verbose output
hyprsupreme --verbose plugin exec my-awesome-plugin my-command
```

### **Automated Testing**

Create `tests/test_plugin.py`:

```python
#!/usr/bin/env python3
"""
Test suite for my-awesome-plugin
"""

import unittest
import subprocess
import tempfile
import os

class TestMyAwesomePlugin(unittest.TestCase):
    
    def setUp(self):
        """Set up test environment."""
        self.temp_dir = tempfile.mkdtemp()
        
    def test_plugin_installation(self):
        """Test plugin can be installed."""
        result = subprocess.run([
            'hyprsupreme', 'plugin', 'install', '--dev', '.'
        ], capture_output=True, text=True)
        
        self.assertEqual(result.returncode, 0)
        self.assertIn('installed successfully', result.stdout)
    
    def test_plugin_command(self):
        """Test plugin command execution."""
        result = subprocess.run([
            'hyprsupreme', 'plugin', 'exec', 'my-awesome-plugin', 
            'my-command', '--status'
        ], capture_output=True, text=True)
        
        self.assertEqual(result.returncode, 0)
        self.assertIn('Plugin Status: Active', result.stdout)
    
    def test_theme_change_hook(self):
        """Test theme change hook."""
        # Apply a theme to trigger hook
        subprocess.run(['hyprsupreme', 'theme', 'apply', 'tokyo-night'])
        
        # Check if hook was executed
        log_file = os.path.expanduser('~/.cache/hyprsupreme/logs/plugins/my-awesome-plugin.log')
        with open(log_file, 'r') as f:
            log_content = f.read()
        
        self.assertIn('Theme changed', log_content)

if __name__ == '__main__':
    unittest.main()
```

Run tests:
```bash
cd my-awesome-plugin
python tests/test_plugin.py
```

---

## 📦 **Plugin Distribution**

### **Packaging for Distribution**

1. **Create Release Archive**:
```bash
# Create distribution package
tar -czf my-awesome-plugin-v1.0.0.tar.gz \
    --exclude='*.pyc' \
    --exclude='__pycache__' \
    --exclude='.git' \
    my-awesome-plugin/
```

2. **Validate Package**:
```bash
# Validate plugin package
hyprsupreme plugin validate my-awesome-plugin-v1.0.0.tar.gz
```

### **Publishing to Community Platform**

1. **Upload via CLI**:
```bash
# Upload to community platform
hyprsupreme community upload my-awesome-plugin-v1.0.0.tar.gz
```

2. **Upload via Web Interface**:
- Visit `http://localhost:5000/upload`
- Fill in plugin details
- Upload package file
- Submit for review

3. **Plugin Manifest for Community**:
```toml
[community]
category = "productivity"  # productivity, theming, system, gaming
tags = ["automation", "themes", "workspace"]
screenshots = ["screenshot1.png", "screenshot2.png"]
compatible_themes = ["tokyo-night", "catppuccin-mocha"]
```

---

## 🔒 **Security Best Practices**

### **Script Security**

1. **Input Validation**:
```bash
#!/bin/bash
# Always validate input parameters
if [ $# -lt 1 ]; then
    echo "Error: Missing required parameter" >&2
    exit 1
fi

THEME_NAME="$1"
# Validate theme name (alphanumeric and hyphens only)
if [[ ! "$THEME_NAME" =~ ^[a-zA-Z0-9-]+$ ]]; then
    echo "Error: Invalid theme name" >&2
    exit 1
fi
```

2. **Safe File Operations**:
```bash
# Use safe temporary files
TEMP_FILE=$(mktemp)
trap "rm -f $TEMP_FILE" EXIT

# Avoid shell injection
SAFE_PATH="/home/user/.config/hyprsupreme/plugins"
CONFIG_FILE="$SAFE_PATH/$(basename "$PLUGIN_NAME").conf"
```

3. **Permission Checks**:
```python
import os
import stat

def ensure_executable(script_path):
    """Ensure script is executable but not world-writable."""
    current_mode = os.stat(script_path).st_mode
    
    # Should be executable by owner
    if not (current_mode & stat.S_IXUSR):
        os.chmod(script_path, current_mode | stat.S_IXUSR)
    
    # Should not be world-writable
    if current_mode & stat.S_IWOTH:
        raise SecurityError("Script should not be world-writable")
```

---

## 🚀 **Performance Optimization**

### **Efficient Hook Implementation**

```bash
#!/bin/bash
# Fast hook execution

# Cache expensive operations
CACHE_FILE="$HOME/.cache/my-plugin/theme-cache"
CURRENT_THEME="$1"

# Check if we already processed this theme
if [ -f "$CACHE_FILE" ] && grep -q "$CURRENT_THEME" "$CACHE_FILE"; then
    echo "Theme $CURRENT_THEME already optimized"
    exit 0
fi

# Perform optimization
echo "Optimizing for theme: $CURRENT_THEME"
# ... optimization logic ...

# Update cache
echo "$CURRENT_THEME" > "$CACHE_FILE"
```

### **Async Operations**

```python
import asyncio
import subprocess

async def async_command(cmd):
    """Run command asynchronously."""
    process = await asyncio.create_subprocess_exec(
        *cmd,
        stdout=asyncio.subprocess.PIPE,
        stderr=asyncio.subprocess.PIPE
    )
    
    stdout, stderr = await process.communicate()
    return process.returncode, stdout.decode(), stderr.decode()

async def main():
    # Run multiple operations concurrently
    tasks = [
        async_command(['hyprctl', 'reload']),
        async_command(['pkill', '-SIGUSR1', 'waybar']),
        async_command(['notify-send', 'Theme applied'])
    ]
    
    results = await asyncio.gather(*tasks)
    return all(code == 0 for code, _, _ in results)
```

---

## 🐛 **Debugging and Troubleshooting**

### **Logging Best Practices**

```bash
#!/bin/bash
# Plugin logging setup

PLUGIN_NAME="my-awesome-plugin"
LOG_DIR="$HOME/.cache/hyprsupreme/logs/plugins"
LOG_FILE="$LOG_DIR/$PLUGIN_NAME.log"

# Ensure log directory exists
mkdir -p "$LOG_DIR"

# Logging function
log() {
    local level="$1"
    shift
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [$level] $PLUGIN_NAME: $*" >> "$LOG_FILE"
}

# Usage
log "INFO" "Plugin started"
log "ERROR" "Failed to connect to service"
log "DEBUG" "Configuration: $CONFIG_VALUE"
```

### **Common Issues and Solutions**

| Issue | Solution |
|-------|----------|
| Hook not executing | Check script permissions and shebang |
| Command not found | Verify script path in manifest |
| Dependencies not loading | Check dependency versions and availability |
| Permission denied | Ensure scripts are executable |
| Plugin not loading | Validate manifest syntax |

### **Debug Commands**

```bash
# Check plugin status
hyprsupreme plugin status my-awesome-plugin

# View plugin logs
hyprsupreme plugin logs my-awesome-plugin

# Test plugin in isolation
hyprsupreme plugin test my-awesome-plugin

# Validate plugin configuration
hyprsupreme plugin validate my-awesome-plugin
```

---

## 📚 **API Reference**

### **HyprSupreme CLI API**

Available commands plugins can use:

```bash
# Theme operations
hyprsupreme theme current              # Get current theme
hyprsupreme theme list                 # List available themes
hyprsupreme theme apply THEME_NAME     # Apply theme

# Configuration operations
hyprsupreme config get KEY             # Get config value
hyprsupreme config set KEY VALUE       # Set config value
hyprsupreme config reload              # Reload configuration

# Plugin operations
hyprsupreme plugin list                # List all plugins
hyprsupreme plugin status PLUGIN_NAME  # Get plugin status
hyprsupreme plugin config PLUGIN_NAME  # Get plugin config

# System operations
hyprsupreme system reload              # Reload Hyprland config
hyprsupreme system notify MESSAGE      # Send notification
hyprsupreme system workspace current   # Get current workspace
```

### **Python API**

```python
from hyprsupreme import api

# Theme operations
current_theme = api.theme.get_current()
api.theme.apply('tokyo-night')

# Configuration operations
value = api.config.get('general.border_size')
api.config.set('general.border_size', 2)

# Plugin operations
plugins = api.plugin.list_enabled()
api.plugin.execute('my-plugin', 'my-command', ['arg1', 'arg2'])

# Event system
@api.event.on('theme_changed')
def handle_theme_change(old_theme, new_theme):
    print(f"Theme changed: {old_theme} -> {new_theme}")
```

---

## 🎉 **Example Plugins**

### **Workspace Manager Plugin**

A complete example plugin that manages workspace layouts:

- **Repository**: [workspace-manager-plugin](https://github.com/hyprsupreme/workspace-manager)
- **Features**: Automatic workspace setup, per-theme layouts
- **Commands**: `save-layout`, `load-layout`, `auto-setup`

### **Notification Center Plugin**

Advanced notification management:

- **Repository**: [notification-center-plugin](https://github.com/hyprsupreme/notification-center)
- **Features**: Notification history, theme-aware styling
- **Commands**: `show-history`, `clear-all`, `toggle-dnd`

---

## 📞 **Support and Community**

### **Getting Help**

- **Documentation**: This guide and [API Reference](API_REFERENCE.md)
- **Community Forum**: [GitHub Discussions](https://github.com/hyprsupreme/hyprsupreme-builder/discussions)
- **Discord Server**: [HyprSupreme Community](https://discord.gg/hyprsupreme)
- **Issue Tracker**: [GitHub Issues](https://github.com/hyprsupreme/hyprsupreme-builder/issues)

### **Contributing**

1. **Plugin Templates**: Use official templates for quick start
2. **Best Practices**: Follow the guidelines in this document
3. **Code Review**: Submit plugins for community review
4. **Documentation**: Contribute to plugin documentation

---

**This guide provides everything needed to create professional-grade plugins for HyprSupreme-Builder. Start building and share your creations with the community!**

---

*Last updated: 2025-06-21*
*Version: 2.0.0*

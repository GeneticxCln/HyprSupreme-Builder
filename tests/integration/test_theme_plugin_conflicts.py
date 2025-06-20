#!/usr/bin/env python3
"""
Advanced integration tests for HyprSupreme-Builder focusing on edge cases,
conflict scenarios, and configuration migrations between themes and plugins.
"""

import os
import sys
import time
import json
import pytest
import shutil
import tempfile
import subprocess
from pathlib import Path
from unittest.mock import patch

# Add project root to path
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '../../')))

# Constants
TEST_THEMES = ["tokyo-night", "catppuccin-mocha", "minimal"]
TEST_PLUGINS = ["auto-theme-switcher", "workspace-manager"]
CONFIG_DIR = Path(os.path.expanduser("~/.config/hyprsupreme"))
BACKUP_DIR = Path(os.path.expanduser("~/.local/share/hyprsupreme/backups"))


class TestThemePluginConflicts:
    """Test suite for edge cases and conflict scenarios in theme and plugin interactions."""
    
    def setup_method(self):
        """Set up test environment."""
        # Create temporary directory for test configs
        self.temp_dir = tempfile.mkdtemp()
        self.test_config_dir = Path(self.temp_dir) / "config"
        self.test_config_dir.mkdir(parents=True)
        
        # Save original config state if it exists
        self.has_original_config = CONFIG_DIR.exists()
        if self.has_original_config:
            self.original_config_backup = Path(self.temp_dir) / "original_config"
            shutil.copytree(CONFIG_DIR, self.original_config_backup)
    
    def teardown_method(self):
        """Clean up after tests."""
        # Restore original config if it existed
        if self.has_original_config and self.original_config_backup.exists():
            shutil.rmtree(CONFIG_DIR, ignore_errors=True)
            shutil.copytree(self.original_config_backup, CONFIG_DIR)
        
        # Clean up temp directory
        shutil.rmtree(self.temp_dir, ignore_errors=True)
    
    def run_hyprsupreme_command(self, *args):
        """Run hyprsupreme command and return output."""
        cmd = ["hyprsupreme"] + list(args)
        return subprocess.run(cmd, check=True, capture_output=True, text=True)
    
    def create_conflicting_config(self, theme_name, plugin_name):
        """Create deliberately conflicting configurations between theme and plugin."""
        # Create theme config with specific settings
        theme_config = CONFIG_DIR / "themes" / theme_name / "config.json"
        theme_config.parent.mkdir(parents=True, exist_ok=True)
        
        theme_data = {
            "name": theme_name,
            "variables": {
                "background": "#1a1b26",
                "foreground": "#c0caf5",
                "accent": "#7aa2f7"
            },
            "keybinds": {
                "SUPER+SHIFT+q": "exit"
            },
            "window_rules": [
                "opacity 0.95 override 0.95 override,class:^(kitty)$",
                "float,class:^(pavucontrol)$"
            ]
        }
        
        with open(theme_config, "w") as f:
            json.dump(theme_data, f, indent=2)
        
        # Create plugin config with conflicting settings
        plugin_config = CONFIG_DIR / "plugins" / plugin_name / "config.json"
        plugin_config.parent.mkdir(parents=True, exist_ok=True)
        
        plugin_data = {
            "name": plugin_name,
            "enabled": True,
            "keybinds": {
                "SUPER+SHIFT+q": "killactive" # Conflicts with theme
            },
            "window_rules": [
                "opacity 0.8 override 0.8 override,class:^(kitty)$", # Conflicts with theme
                "float,class:^(pavucontrol)$"
            ]
        }
        
        with open(plugin_config, "w") as f:
            json.dump(plugin_data, f, indent=2)
        
        return theme_config, plugin_config
    
    @pytest.mark.edge_case
    def test_theme_plugin_keybind_conflict(self):
        """Test handling of conflicting keybinds between theme and plugin."""
        theme_name = "tokyo-night"
        plugin_name = "workspace-manager"
        
        # Create conflicting configs
        theme_config, plugin_config = self.create_conflicting_config(theme_name, plugin_name)
        
        # Enable plugin
        self.run_hyprsupreme_command("plugin", "enable", plugin_name)
        
        # Apply theme and check for conflict detection
        result = self.run_hyprsupreme_command("theme", "apply", theme_name, "--verbose")
        
        # Check if conflict was detected and logged
        assert "CONFLICT" in result.stderr or "CONFLICT" in result.stdout
        assert "SUPER+SHIFT+q" in result.stderr or "SUPER+SHIFT+q" in result.stdout
        
        # Check final config to see which binding was applied (should use plugin binding)
        hypr_config = CONFIG_DIR / "hyprland.conf"
        config_text = hypr_config.read_text()
        
        # Plugin binding should take precedence
        assert "bind = SUPER+SHIFT+q, killactive," in config_text
        assert "bind = SUPER+SHIFT+q, exit," not in config_text
    
    @pytest.mark.edge_case
    def test_theme_plugin_window_rule_conflict(self):
        """Test handling of conflicting window rules between theme and plugin."""
        theme_name = "catppuccin-mocha"
        plugin_name = "auto-theme-switcher"
        
        # Create conflicting configs
        theme_config, plugin_config = self.create_conflicting_config(theme_name, plugin_name)
        
        # Enable plugin
        self.run_hyprsupreme_command("plugin", "enable", plugin_name)
        
        # Apply theme and check for conflict detection
        result = self.run_hyprsupreme_command("theme", "apply", theme_name, "--verbose")
        
        # Check if conflict was detected and logged
        assert "CONFLICT" in result.stderr or "CONFLICT" in result.stdout
        assert "kitty" in result.stderr or "kitty" in result.stdout
        
        # Check final config to see which rule was applied (should use plugin rule)
        hypr_config = CONFIG_DIR / "hyprland.conf"
        config_text = hypr_config.read_text()
        
        # Plugin window rule should take precedence
        assert "opacity 0.8" in config_text
        assert "opacity 0.95" not in config_text
    
    @pytest.mark.edge_case
    def test_rapid_theme_switching(self):
        """Test system stability during rapid theme switching."""
        # Enable a plugin to test interaction during rapid switching
        self.run_hyprsupreme_command("plugin", "enable", "auto-theme-switcher")
        
        # Start with one theme
        self.run_hyprsupreme_command("theme", "apply", "tokyo-night")
        
        # Perform rapid theme switches
        start_time = time.time()
        switch_count = 0
        error_count = 0
        
        # Rapid switching for 5 seconds
        while time.time() - start_time < 5:
            theme_name = TEST_THEMES[switch_count % len(TEST_THEMES)]
            try:
                self.run_hyprsupreme_command("theme", "apply", theme_name)
                switch_count += 1
            except subprocess.CalledProcessError:
                error_count += 1
        
        # Assert stability
        assert error_count == 0, f"Encountered {error_count} errors during rapid theme switching"
        assert switch_count > 3, f"Should have performed at least 3 theme switches"
        
        # Check if the final theme was applied correctly
        result = self.run_hyprsupreme_command("theme", "status")
        final_theme = TEST_THEMES[(switch_count - 1) % len(TEST_THEMES)]
        assert final_theme in result.stdout
    
    @pytest.mark.edge_case
    def test_plugin_conflict_resolution_priority(self):
        """Test plugin priority system for conflict resolution."""
        # Create three plugins with conflicting settings but different priorities
        plugins = ["auto-theme-switcher", "workspace-manager", "focus-enhancer"]
        priorities = [10, 50, 30]  # Higher number = higher priority
        
        # Create config directory structure
        for i, plugin in enumerate(plugins):
            plugin_dir = CONFIG_DIR / "plugins" / plugin
            plugin_dir.mkdir(parents=True, exist_ok=True)
            
            # Create manifest with priority
            manifest = {
                "name": plugin,
                "version": "1.0.0",
                "priority": priorities[i],
                "keybinds": {
                    "SUPER+c": f"exec {plugin}"  # Same keybind for all plugins
                }
            }
            
            with open(plugin_dir / "manifest.json", "w") as f:
                json.dump(manifest, f, indent=2)
            
            # Enable the plugin
            self.run_hyprsupreme_command("plugin", "enable", plugin)
        
        # Apply a theme to trigger config generation
        self.run_hyprsupreme_command("theme", "apply", "tokyo-night")
        
        # Check that the highest priority plugin won the conflict
        hypr_config = CONFIG_DIR / "hyprland.conf"
        config_text = hypr_config.read_text()
        
        # workspace-manager (priority 50) should take precedence
        assert "bind = SUPER+c, exec workspace-manager," in config_text
    
    @pytest.mark.edge_case
    def test_configuration_migration(self):
        """Test configuration migration when switching between themes."""
        # Setup custom user preferences
        user_prefs_file = CONFIG_DIR / "user_preferences.json"
        user_prefs = {
            "preserveSettings": [
                "input:sensitivity",
                "decoration:rounding",
                "general:gaps_in"
            ],
            "monitor": {
                "resolution": "1920x1080",
                "refresh": "60"
            }
        }
        
        with open(user_prefs_file, "w") as f:
            json.dump(user_prefs, f, indent=2)
        
        # Apply first theme
        self.run_hyprsupreme_command("theme", "apply", "tokyo-night")
        
        # Modify configuration with custom values
        hypr_config = CONFIG_DIR / "hyprland.conf"
        with open(hypr_config, "a") as f:
            f.write("\n# Custom user settings\n")
            f.write("input {\n")
            f.write("    sensitivity = 0.8\n")
            f.write("}\n")
            f.write("decoration {\n")
            f.write("    rounding = 10\n")
            f.write("}\n")
            f.write("general {\n")
            f.write("    gaps_in = 5\n")
            f.write("}\n")
        
        # Apply second theme and check if preserved settings migrated
        self.run_hyprsupreme_command("theme", "apply", "catppuccin-mocha")
        
        # Read new config
        new_config_text = hypr_config.read_text()
        
        # Check if preserved settings were migrated
        assert "sensitivity = 0.8" in new_config_text
        assert "rounding = 10" in new_config_text
        assert "gaps_in = 5" in new_config_text
    
    @pytest.mark.edge_case
    def test_plugin_dependency_resolution(self):
        """Test plugin dependency resolution and circular dependency detection."""
        # Create plugins with dependencies
        plugins = {
            "plugin-a": ["plugin-b"],
            "plugin-b": ["plugin-c"],
            "plugin-c": ["plugin-d"],
            "plugin-d": [],
            "plugin-circular-1": ["plugin-circular-2"],
            "plugin-circular-2": ["plugin-circular-1"]
        }
        
        # Create plugin configurations
        for plugin, dependencies in plugins.items():
            plugin_dir = CONFIG_DIR / "plugins" / plugin
            plugin_dir.mkdir(parents=True, exist_ok=True)
            
            manifest = {
                "name": plugin,
                "version": "1.0.0",
                "dependencies": dependencies,
                "enabled": False
            }
            
            with open(plugin_dir / "manifest.json", "w") as f:
                json.dump(manifest, f, indent=2)
            
            # Create empty script
            with open(plugin_dir / f"{plugin}.sh", "w") as f:
                f.write("#!/bin/bash\necho 'Plugin activated'\n")
            
            os.chmod(plugin_dir / f"{plugin}.sh", 0o755)
        
        # Test successful dependency chain
        result = self.run_hyprsupreme_command("plugin", "enable", "plugin-a")
        
        # All dependencies should be enabled
        for plugin in ["plugin-a", "plugin-b", "plugin-c", "plugin-d"]:
            plugin_status = self.run_hyprsupreme_command("plugin", "status", plugin)
            assert "enabled" in plugin_status.stdout.lower()
        
        # Test circular dependency detection
        with pytest.raises(subprocess.CalledProcessError):
            result = self.run_hyprsupreme_command("plugin", "enable", "plugin-circular-1")
            assert "circular dependency" in result.stderr.lower()
    
    @pytest.mark.edge_case
    def test_theme_compatibility_check(self):
        """Test theme compatibility check with system components."""
        # Create themes with different compatibility requirements
        themes = {
            "compatible-theme": {
                "requirements": {
                    "hyprland_version": ">=0.1.0",
                    "hyprsupreme_version": ">=1.0.0"
                }
            },
            "incompatible-theme": {
                "requirements": {
                    "hyprland_version": ">=99.0.0",  # Impossibly high version
                    "hyprsupreme_version": ">=99.0.0"
                }
            }
        }
        
        # Create theme configurations
        for theme, config in themes.items():
            theme_dir = CONFIG_DIR / "themes" / theme
            theme_dir.mkdir(parents=True, exist_ok=True)
            
            manifest = {
                "name": theme,
                "version": "1.0.0",
                "requirements": config["requirements"]
            }
            
            with open(theme_dir / "manifest.json", "w") as f:
                json.dump(manifest, f, indent=2)
        
        # Test compatible theme
        result = self.run_hyprsupreme_command("theme", "apply", "compatible-theme")
        assert "applied" in result.stdout.lower()
        
        # Test incompatible theme
        with pytest.raises(subprocess.CalledProcessError):
            result = self.run_hyprsupreme_command("theme", "apply", "incompatible-theme")
            assert "compatibility" in result.stderr.lower()
    
    @pytest.mark.edge_case
    def test_backup_and_restore_during_failure(self):
        """Test backup and restore functionality during theme application failure."""
        # Apply a known good theme first
        self.run_hyprsupreme_command("theme", "apply", "tokyo-night")
        
        # Get the current config
        original_config = (CONFIG_DIR / "hyprland.conf").read_text()
        
        # Create a theme that will fail during application
        failing_theme_dir = CONFIG_DIR / "themes" / "failing-theme"
        failing_theme_dir.mkdir(parents=True, exist_ok=True)
        
        # Create corrupt theme file
        with open(failing_theme_dir / "hyprland.conf", "w") as f:
            f.write("# This is an intentionally broken theme config\n")
            f.write("monitor = SYNTAX ERROR\n")
            f.write("decoration invalid_block {\n")
            f.write("}\n")
        
        # Create manifest
        with open(failing_theme_dir / "manifest.json", "w") as f:
            json.dump({
                "name": "failing-theme",
                "version": "1.0.0"
            }, f, indent=2)
        
        # Try to apply the failing theme - should trigger backup and restore
        with pytest.raises(subprocess.CalledProcessError):
            self.run_hyprsupreme_command("theme", "apply", "failing-theme")
        
        # Check that the system was restored to the previous theme
        restored_config = (CONFIG_DIR / "hyprland.conf").read_text()
        assert restored_config == original_config
        
        # Check that a backup was created
        backup_files = list(BACKUP_DIR.glob("*"))
        assert len(backup_files) > 0


if __name__ == "__main__":
    pytest.main(["-xvs", __file__])

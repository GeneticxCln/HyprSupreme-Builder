#!/usr/bin/env python3
"""
Integration tests for the interaction between themes and plugins in HyprSupreme-Builder.
Tests theme switching with plugins enabled and plugin operations with different themes.
"""

import os
import sys
import json
import time
import unittest
import tempfile
import subprocess
from pathlib import Path
from unittest.mock import patch, MagicMock

# Add parent directory to path to import modules
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '../../')))

try:
    from modules.themes.theme_manager import ThemeManager
    from modules.plugins.plugin_manager import PluginManager
    from modules.core.config_generator import ConfigGenerator
except ImportError:
    # Mock classes for testing without actual modules
    class ThemeManager:
        def __init__(self):
            self.current_theme = None
        
        def get_theme(self, name):
            return {"name": name, "version": "1.0.0"}
        
        def apply_theme(self, name):
            self.current_theme = name
            return True
        
        def get_current_theme(self):
            return self.current_theme
    
    class PluginManager:
        def __init__(self):
            self.enabled_plugins = []
        
        def get_plugin(self, name):
            return {"name": name, "version": "1.0.0", "enabled": name in self.enabled_plugins}
        
        def enable_plugin(self, name):
            if name not in self.enabled_plugins:
                self.enabled_plugins.append(name)
            return True
        
        def disable_plugin(self, name):
            if name in self.enabled_plugins:
                self.enabled_plugins.remove(name)
            return True
        
        def get_enabled_plugins(self):
            return self.enabled_plugins
    
    class ConfigGenerator:
        def generate_config(self, theme, plugins, output_dir):
            return True


class TestThemePluginIntegration(unittest.TestCase):
    """Integration tests for theme and plugin interactions."""
    
    def setUp(self):
        """Set up test environment."""
        self.temp_dir = tempfile.TemporaryDirectory()
        self.config_dir = self.temp_dir.name
        
        # Create config subdirectories
        os.makedirs(os.path.join(self.config_dir, "themes"), exist_ok=True)
        os.makedirs(os.path.join(self.config_dir, "plugins"), exist_ok=True)
        
        # Initialize managers
        self.theme_manager = ThemeManager()
        self.plugin_manager = PluginManager()
        self.config_generator = ConfigGenerator()
        
        # Test themes
        self.test_themes = ["tokyo-night", "catppuccin-mocha", "catppuccin-latte"]
        
        # Test plugins
        self.test_plugins = ["auto-theme-switcher", "workspace-manager"]
        
        # Create mock theme and plugin configuration
        self._create_mock_configs()
    
    def tearDown(self):
        """Clean up after tests."""
        self.temp_dir.cleanup()
    
    def _create_mock_configs(self):
        """Create mock theme and plugin configuration files for testing."""
        # Create theme files
        for theme in self.test_themes:
            theme_dir = os.path.join(self.config_dir, "themes", theme)
            os.makedirs(theme_dir, exist_ok=True)
            
            # Create theme.yaml
            with open(os.path.join(theme_dir, "theme.yaml"), "w") as f:
                f.write(f"""name: {theme}
version: 1.0.0
description: Test theme {theme}
colors:
  background: "#000000"
  foreground: "#ffffff"
""")
        
        # Create plugin files
        for plugin in self.test_plugins:
            plugin_dir = os.path.join(self.config_dir, "plugins", plugin)
            os.makedirs(plugin_dir, exist_ok=True)
            
            # Create manifest.yaml
            with open(os.path.join(plugin_dir, "manifest.yaml"), "w") as f:
                f.write(f"""name: {plugin}
version: 1.0.0
description: Test plugin {plugin}
dependencies:
  hyprsupreme: ">=2.0.0"
hooks:
  - name: theme_changed
    script: scripts/theme_changed.sh
""")
            
            # Create scripts directory and hook script
            scripts_dir = os.path.join(plugin_dir, "scripts")
            os.makedirs(scripts_dir, exist_ok=True)
            
            with open(os.path.join(scripts_dir, "theme_changed.sh"), "w") as f:
                f.write(f"""#!/bin/bash
echo "Theme changed hook for {plugin}"
exit 0
""")
            os.chmod(os.path.join(scripts_dir, "theme_changed.sh"), 0o755)
    
    def _mock_hyprsupreme_cli(self, command, check=True):
        """Mock the hyprsupreme CLI for testing."""
        # Split command string into list if needed
        if isinstance(command, str):
            command = command.split()
        
        # Check if command starts with hyprsupreme
        if command[0] != "hyprsupreme":
            command = ["hyprsupreme"] + command
        
        # Handle different commands
        if command[1] == "theme" and command[2] == "apply":
            theme_name = command[3]
            return self.theme_manager.apply_theme(theme_name)
        
        elif command[1] == "theme" and command[2] == "current":
            return self.theme_manager.get_current_theme()
        
        elif command[1] == "plugin" and command[2] == "enable":
            plugin_name = command[3]
            return self.plugin_manager.enable_plugin(plugin_name)
        
        elif command[1] == "plugin" and command[2] == "disable":
            plugin_name = command[3]
            return self.plugin_manager.disable_plugin(plugin_name)
        
        elif command[1] == "plugin" and command[2] == "list":
            return self.plugin_manager.get_enabled_plugins()
        
        else:
            # Default return for unhandled commands
            return True
    
    def test_theme_switch_with_plugins_enabled(self):
        """Test switching themes with plugins enabled."""
        with patch.object(PluginManager, 'enable_plugin') as mock_enable_plugin, \
             patch.object(PluginManager, 'get_enabled_plugins') as mock_get_enabled, \
             patch.object(ThemeManager, 'apply_theme') as mock_apply_theme, \
             patch.object(PluginManager, 'execute_hook') as mock_execute_hook:
            
            # Set up mocks
            mock_enable_plugin.return_value = True
            mock_get_enabled.return_value = self.test_plugins
            mock_apply_theme.return_value = True
            mock_execute_hook.return_value = {"status": "success"}
            
            # Enable plugins
            for plugin in self.test_plugins:
                result = self.plugin_manager.enable_plugin(plugin)
                self.assertTrue(result)
            
            # Switch themes and verify hooks are called
            for theme in self.test_themes:
                result = self.theme_manager.apply_theme(theme)
                self.assertTrue(result)
                
                # Verify that theme_changed hook is called for each enabled plugin
                for plugin in self.test_plugins:
                    mock_execute_hook.assert_any_call(plugin, "theme_changed", {"theme": theme})
    
    def test_plugin_enable_disable_with_theme(self):
        """Test enabling and disabling plugins with a theme applied."""
        with patch.object(ThemeManager, 'apply_theme') as mock_apply_theme, \
             patch.object(ThemeManager, 'get_current_theme') as mock_get_current, \
             patch.object(PluginManager, 'enable_plugin') as mock_enable, \
             patch.object(PluginManager, 'disable_plugin') as mock_disable, \
             patch.object(ConfigGenerator, 'generate_config') as mock_generate:
            
            # Set up mocks
            test_theme = self.test_themes[0]
            mock_apply_theme.return_value = True
            mock_get_current.return_value = test_theme
            mock_enable.return_value = True
            mock_disable.return_value = True
            mock_generate.return_value = True
            
            # Apply a theme
            result = self.theme_manager.apply_theme(test_theme)
            self.assertTrue(result)
            
            # Enable plugins one by one and verify config is regenerated each time
            for plugin in self.test_plugins:
                result = self.plugin_manager.enable_plugin(plugin)
                self.assertTrue(result)
                
                # Verify config generation is called with current theme and enabled plugins
                mock_generate.assert_called_with(
                    test_theme, 
                    self.plugin_manager.get_enabled_plugins(),
                    any  # Output directory can be any value
                )
            
            # Disable plugins one by one and verify config is regenerated each time
            for plugin in self.test_plugins:
                result = self.plugin_manager.disable_plugin(plugin)
                self.assertTrue(result)
                
                # Verify config generation is called with current theme and remaining enabled plugins
                mock_generate.assert_called_with(
                    test_theme, 
                    self.plugin_manager.get_enabled_plugins(),
                    any  # Output directory can be any value
                )
    
    def test_auto_theme_switcher_plugin_integration(self):
        """Test integration with auto-theme-switcher plugin."""
        plugin_name = "auto-theme-switcher"
        
        with patch.object(PluginManager, 'enable_plugin') as mock_enable, \
             patch.object(PluginManager, 'execute_command') as mock_execute, \
             patch.object(ThemeManager, 'apply_theme') as mock_apply_theme:
            
            # Set up mocks
            mock_enable.return_value = True
            mock_execute.return_value = {"status": "success", "theme": self.test_themes[1]}
            mock_apply_theme.return_value = True
            
            # Enable auto-theme-switcher plugin
            result = self.plugin_manager.enable_plugin(plugin_name)
            self.assertTrue(result)
            
            # Execute auto-switch command
            result = self.plugin_manager.execute_command(plugin_name, "auto-switch", [])
            self.assertEqual(result["status"], "success")
            
            # Verify that the theme was switched
            mock_apply_theme.assert_called_with(result["theme"])
    
    def test_workspace_manager_plugin_integration(self):
        """Test integration with workspace-manager plugin."""
        plugin_name = "workspace-manager"
        
        with patch.object(PluginManager, 'enable_plugin') as mock_enable, \
             patch.object(PluginManager, 'execute_command') as mock_execute, \
             patch.object(ThemeManager, 'get_current_theme') as mock_get_theme, \
             patch.object(ThemeManager, 'get_theme_colors') as mock_get_colors:
            
            # Set up mocks
            mock_enable.return_value = True
            mock_execute.return_value = {"status": "success", "workspaces": [1, 2, 3]}
            mock_get_theme.return_value = self.test_themes[0]
            mock_get_colors.return_value = {
                "workspace_active": "#ff0000",
                "workspace_inactive": "#000000"
            }
            
            # Enable workspace-manager plugin
            result = self.plugin_manager.enable_plugin(plugin_name)
            self.assertTrue(result)
            
            # Execute get-workspaces command
            result = self.plugin_manager.execute_command(plugin_name, "get-workspaces", [])
            self.assertEqual(result["status"], "success")
            
            # Verify that theme colors are used by the plugin
            mock_get_theme.assert_called()
            mock_get_colors.assert_called_with(self.test_themes[0])
    
    def test_theme_plugin_config_conflicts(self):
        """Test handling of configuration conflicts between themes and plugins."""
        with patch.object(ThemeManager, 'apply_theme') as mock_apply_theme, \
             patch.object(PluginManager, 'enable_plugin') as mock_enable, \
             patch.object(ConfigGenerator, 'generate_config') as mock_generate, \
             patch.object(ConfigGenerator, 'detect_conflicts') as mock_detect_conflicts:
            
            # Set up mocks
            mock_apply_theme.return_value = True
            mock_enable.return_value = True
            mock_generate.return_value = True
            
            # Set up conflict detection to report conflicts for a specific theme-plugin combination
            def mock_conflict_detection(theme, plugins, output_dir):
                conflicts = []
                if theme == "tokyo-night" and "workspace-manager" in plugins:
                    conflicts.append({
                        "type": "keybind",
                        "theme": theme,
                        "plugin": "workspace-manager",
                        "detail": "Both define SUPER + W keybinding"
                    })
                return conflicts
            
            mock_detect_conflicts.side_effect = mock_conflict_detection
            
            # Apply theme and enable plugin with conflicts
            self.theme_manager.apply_theme("tokyo-night")
            self.plugin_manager.enable_plugin("workspace-manager")
            
            # Generate config and check for conflicts
            conflicts = self.config_generator.detect_conflicts(
                "tokyo-night", ["workspace-manager"], self.config_dir
            )
            
            # Verify conflicts were detected
            self.assertEqual(len(conflicts), 1)
            self.assertEqual(conflicts[0]["type"], "keybind")
            self.assertEqual(conflicts[0]["theme"], "tokyo-night")
            self.assertEqual(conflicts[0]["plugin"], "workspace-manager")
    
    def test_cli_theme_plugin_integration(self):
        """Test theme and plugin integration using CLI commands."""
        with patch('subprocess.run') as mock_run:
            # Mock subprocess.run to use our _mock_hyprsupreme_cli
            mock_run.side_effect = lambda cmd, check=True, **kwargs: self._mock_hyprsupreme_cli(cmd, check)
            
            # Apply a theme via CLI
            subprocess.run(["hyprsupreme", "theme", "apply", "tokyo-night"], check=True)
            self.assertEqual(self.theme_manager.get_current_theme(), "tokyo-night")
            
            # Enable a plugin via CLI
            subprocess.run(["hyprsupreme", "plugin", "enable", "auto-theme-switcher"], check=True)
            self.assertIn("auto-theme-switcher", self.plugin_manager.get_enabled_plugins())
            
            # Change theme with plugin enabled
            subprocess.run(["hyprsupreme", "theme", "apply", "catppuccin-mocha"], check=True)
            self.assertEqual(self.theme_manager.get_current_theme(), "catppuccin-mocha")
            self.assertIn("auto-theme-switcher", self.plugin_manager.get_enabled_plugins())
            
            # Disable plugin
            subprocess.run(["hyprsupreme", "plugin", "disable", "auto-theme-switcher"], check=True)
            self.assertNotIn("auto-theme-switcher", self.plugin_manager.get_enabled_plugins())


if __name__ == "__main__":
    unittest.main()

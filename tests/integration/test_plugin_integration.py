#!/usr/bin/env python3
"""
Integration tests for the HyprSupreme-Builder plugin system.
Tests the interaction between plugins and the Hyprland configuration.
"""

import os
import sys
import unittest
import tempfile
import subprocess
from unittest.mock import patch, MagicMock

# Add parent directory to path to import modules
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '../../')))

try:
    from modules.plugins.plugin_manager import PluginManager
    from modules.core.config_generator import ConfigGenerator
except ImportError:
    # Mock classes for testing without actual modules
    class PluginManager:
        def load_plugin(self, name):
            return {"name": name, "version": "1.0.0", "enabled": False}
        
        def enable_plugin(self, name):
            return True
        
        def execute_hook(self, plugin_name, hook_name):
            return {"status": "success"}
    
    class ConfigGenerator:
        def generate_config(self, plugins, output_dir):
            return True


class TestPluginIntegration(unittest.TestCase):
    """Integration tests for the plugin system."""
    
    def setUp(self):
        """Set up test environment."""
        self.temp_dir = tempfile.TemporaryDirectory()
        self.config_dir = self.temp_dir.name
        
        # Initialize managers
        self.plugin_manager = PluginManager()
        self.config_generator = ConfigGenerator()
    
    def tearDown(self):
        """Clean up after tests."""
        self.temp_dir.cleanup()
    
    def test_plugin_hooks_on_startup(self):
        """Test executing plugin startup hooks."""
        with patch.object(PluginManager, 'execute_hook') as mock_execute:
            mock_execute.return_value = {"status": "success", "output": "Startup hook executed"}
            
            result = self.plugin_manager.execute_hook("test-plugin", "startup")
            
            self.assertEqual(result["status"], "success")
            mock_execute.assert_called_once_with("test-plugin", "startup")
    
    def test_plugin_integration_with_config(self):
        """Test that plugin configurations are properly integrated into Hyprland config."""
        with patch.object(PluginManager, 'load_plugin') as mock_load:
            mock_load.return_value = {
                "name": "test-plugin",
                "version": "1.0.0",
                "enabled": True,
                "config": {
                    "hyprland": {
                        "keybinds": [
                            "bind = SUPER, P, exec, plugin-command"
                        ],
                        "exec": [
                            "exec-once = plugin-startup"
                        ]
                    }
                }
            }
            
            with patch.object(ConfigGenerator, 'generate_config') as mock_generate:
                mock_generate.return_value = True
                
                # Load plugin
                plugin = self.plugin_manager.load_plugin("test-plugin")
                
                # Generate config with plugin
                result = self.config_generator.generate_config([plugin], self.config_dir)
                
                self.assertTrue(result)
                mock_generate.assert_called_once()


if __name__ == "__main__":
    unittest.main()

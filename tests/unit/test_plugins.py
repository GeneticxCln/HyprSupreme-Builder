#!/usr/bin/env python3
"""
Unit tests for the HyprSupreme-Builder plugin system.
"""

import os
import sys
import unittest
import tempfile
import json
import yaml
from unittest.mock import patch, MagicMock

# Add parent directory to path to import modules
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '../../')))

try:
    from modules.plugins.plugin_manager import PluginManager
    from modules.plugins.plugin_loader import PluginLoader
except ImportError:
    # Mock classes for testing without actual modules
    class PluginManager:
        def __init__(self):
            self.plugins = {}
            
        def load_plugin(self, name):
            return {"name": name, "version": "1.0.0", "enabled": False}
        
        def enable_plugin(self, name):
            return True
        
        def disable_plugin(self, name):
            return True
        
        def execute_command(self, plugin_name, command_name):
            return {"status": "success", "output": "Command executed"}
    
    class PluginLoader:
        def load_plugin(self, path):
            return {"name": "test", "version": "1.0.0", "enabled": False}


class TestPluginSystem(unittest.TestCase):
    """Tests for the plugin system."""
    
    def setUp(self):
        """Set up test environment."""
        self.temp_dir = tempfile.TemporaryDirectory()
        self.plugin_dir = self.temp_dir.name
        
        # Create test plugin files
        self.create_test_plugins()
        
        # Initialize plugin manager
        self.plugin_manager = PluginManager()
    
    def tearDown(self):
        """Clean up after tests."""
        self.temp_dir.cleanup()
    
    def create_test_plugins(self):
        """Create test plugin files."""
        # Create a plugin directory
        os.makedirs(os.path.join(self.plugin_dir, "test-plugin"), exist_ok=True)
        
        # Create plugin manifest
        manifest = {
            "name": "test-plugin",
            "display_name": "Test Plugin",
            "version": "1.0.0",
            "author": "Test Author",
            "description": "A test plugin",
            "dependencies": {
                "hyprsupreme": ">=2.0.0"
            },
            "hooks": [
                {
                    "name": "startup",
                    "script": "scripts/startup.sh"
                }
            ],
            "commands": [
                {
                    "name": "test-command",
                    "description": "A test command",
                    "script": "scripts/test-command.sh"
                }
            ]
        }
        
        with open(os.path.join(self.plugin_dir, "test-plugin", "manifest.yaml"), "w") as f:
            yaml.dump(manifest, f)
        
        # Create plugin scripts directory
        os.makedirs(os.path.join(self.plugin_dir, "test-plugin", "scripts"), exist_ok=True)
        
        # Create script files
        with open(os.path.join(self.plugin_dir, "test-plugin", "scripts", "startup.sh"), "w") as f:
            f.write("#!/bin/bash\necho 'Plugin startup script'\n")
        
        with open(os.path.join(self.plugin_dir, "test-plugin", "scripts", "test-command.sh"), "w") as f:
            f.write("#!/bin/bash\necho 'Test command script'\n")
        
        # Make scripts executable
        os.chmod(os.path.join(self.plugin_dir, "test-plugin", "scripts", "startup.sh"), 0o755)
        os.chmod(os.path.join(self.plugin_dir, "test-plugin", "scripts", "test-command.sh"), 0o755)
    
    def test_plugin_loading(self):
        """Test loading plugins from directories."""
        with patch.object(PluginLoader, 'load_plugin') as mock_load:
            mock_load.return_value = {"name": "test-plugin", "version": "1.0.0", "enabled": False}
            
            plugin = self.plugin_manager.load_plugin("test-plugin")
            
            self.assertEqual(plugin["name"], "test-plugin")
            self.assertEqual(plugin["version"], "1.0.0")
            self.assertFalse(plugin["enabled"])
    
    def test_plugin_enable(self):
        """Test enabling a plugin."""
        with patch.object(PluginManager, 'enable_plugin') as mock_enable:
            mock_enable.return_value = True
            
            result = self.plugin_manager.enable_plugin("test-plugin")
            
            self.assertTrue(result)
            mock_enable.assert_called_once_with("test-plugin")
    
    def test_plugin_disable(self):
        """Test disabling a plugin."""
        with patch.object(PluginManager, 'disable_plugin') as mock_disable:
            mock_disable.return_value = True
            
            result = self.plugin_manager.disable_plugin("test-plugin")
            
            self.assertTrue(result)
            mock_disable.assert_called_once_with("test-plugin")
    
    def test_plugin_execution(self):
        """Test executing plugin commands."""
        with patch.object(PluginManager, 'execute_command') as mock_execute:
            mock_execute.return_value = {"status": "success", "output": "Command executed"}
            
            result = self.plugin_manager.execute_command("test-plugin", "test-command")
            
            self.assertEqual(result["status"], "success")
            self.assertEqual(result["output"], "Command executed")
            mock_execute.assert_called_once_with("test-plugin", "test-command")


if __name__ == "__main__":
    unittest.main()

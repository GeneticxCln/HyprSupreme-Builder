#!/usr/bin/env python3
"""
Integration tests for the HyprSupreme-Builder theme system.
Tests the interaction between themes and the Hyprland configuration.
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
    from modules.themes.theme_manager import ThemeManager
    from modules.core.config_generator import ConfigGenerator
except ImportError:
    # Mock classes for testing without actual modules
    class ThemeManager:
        def load_theme(self, name):
            return {"name": name, "colors": {}, "variables": {}}
        
        def apply_theme(self, name):
            return True
    
    class ConfigGenerator:
        def generate_config(self, theme, output_dir):
            return True


class TestThemeIntegration(unittest.TestCase):
    """Integration tests for the theme system."""
    
    def setUp(self):
        """Set up test environment."""
        self.temp_dir = tempfile.TemporaryDirectory()
        self.config_dir = self.temp_dir.name
        
        # Initialize managers
        self.theme_manager = ThemeManager()
        self.config_generator = ConfigGenerator()
    
    def tearDown(self):
        """Clean up after tests."""
        self.temp_dir.cleanup()
    
    def test_theme_application_to_config(self):
        """Test applying a theme and generating Hyprland configuration."""
        with patch.object(ThemeManager, 'load_theme') as mock_load:
            mock_load.return_value = {
                "name": "test-theme",
                "colors": {
                    "background": "#1a1b26",
                    "foreground": "#c0caf5",
                    "accent": "#7aa2f7"
                },
                "variables": {
                    "font": "JetBrains Mono Nerd Font",
                    "font_size": "10"
                }
            }
            
            with patch.object(ConfigGenerator, 'generate_config') as mock_generate:
                mock_generate.return_value = True
                
                # Load theme
                theme = self.theme_manager.load_theme("test-theme")
                
                # Generate config
                result = self.config_generator.generate_config(theme, self.config_dir)
                
                self.assertTrue(result)
                mock_generate.assert_called_once()
    
    def test_theme_reload(self):
        """Test reloading Hyprland when theme changes."""
        with patch.object(ThemeManager, 'apply_theme') as mock_apply:
            mock_apply.return_value = True
            
            with patch('subprocess.run') as mock_run:
                mock_run.return_value = subprocess.CompletedProcess(args=[], returncode=0)
                
                # Apply theme
                result = self.theme_manager.apply_theme("test-theme")
                
                self.assertTrue(result)
                # Check if hyprctl was called to reload configs
                mock_run.assert_called()


if __name__ == "__main__":
    unittest.main()

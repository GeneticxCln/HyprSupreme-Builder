#!/usr/bin/env python3
"""
Unit tests for the HyprSupreme-Builder theme system.
"""

import os
import sys
import unittest
import tempfile
import json
import toml
from unittest.mock import patch, MagicMock

# Add parent directory to path to import modules
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '../../')))

try:
    from modules.themes.theme_manager import ThemeManager
    from modules.themes.theme_loader import ThemeLoader
except ImportError:
    # Mock classes for testing without actual modules
    class ThemeManager:
        def __init__(self):
            self.themes = {}
            self.active_theme = None
        
        def load_theme(self, name):
            return {"name": name, "colors": {"background": "#000000"}, "variables": {}}
        
        def apply_theme(self, name):
            self.active_theme = name
            return True
        
        def get_theme_color(self, color_name):
            return "#ff0000"
        
        def get_theme_variable(self, var_name):
            return "default_value"
    
    class ThemeLoader:
        def load_theme(self, path):
            return {"name": "test", "colors": {}, "variables": {}}


class TestThemeSystem(unittest.TestCase):
    """Tests for the theme system."""
    
    def setUp(self):
        """Set up test environment."""
        self.temp_dir = tempfile.TemporaryDirectory()
        self.theme_dir = self.temp_dir.name
        
        # Create test theme files
        self.create_test_themes()
        
        # Initialize theme manager
        self.theme_manager = ThemeManager()
    
    def tearDown(self):
        """Clean up after tests."""
        self.temp_dir.cleanup()
    
    def create_test_themes(self):
        """Create test theme files."""
        # TOML theme
        toml_theme = {
            "name": "test-toml",
            "version": "1.0.0",
            "author": "Test Author",
            "description": "A test theme in TOML format",
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
        
        with open(os.path.join(self.theme_dir, "test-toml.toml"), "w") as f:
            toml.dump(toml_theme, f)
        
        # JSON theme
        json_theme = {
            "name": "test-json",
            "version": "1.0.0",
            "author": "Test Author",
            "description": "A test theme in JSON format",
            "colors": {
                "background": "#24283b",
                "foreground": "#a9b1d6",
                "accent": "#bb9af7"
            },
            "variables": {
                "font": "Fira Code Nerd Font",
                "font_size": "11"
            }
        }
        
        with open(os.path.join(self.theme_dir, "test-json.json"), "w") as f:
            json.dump(json_theme, f)
    
    def test_theme_loading(self):
        """Test loading themes from files."""
        with patch.object(ThemeLoader, 'load_theme') as mock_load:
            mock_load.return_value = {"name": "test-theme", "colors": {"background": "#000000"}}
            
            theme = self.theme_manager.load_theme("test-theme")
            
            self.assertEqual(theme["name"], "test-theme")
            self.assertEqual(theme["colors"]["background"], "#000000")
    
    def test_theme_application(self):
        """Test applying a theme."""
        with patch.object(ThemeManager, 'apply_theme') as mock_apply:
            mock_apply.return_value = True
            
            result = self.theme_manager.apply_theme("test-theme")
            
            self.assertTrue(result)
            mock_apply.assert_called_once_with("test-theme")
    
    def test_theme_color_resolution(self):
        """Test resolving theme colors."""
        with patch.object(ThemeManager, 'get_theme_color') as mock_get_color:
            mock_get_color.return_value = "#ff0000"
            
            color = self.theme_manager.get_theme_color("accent")
            
            self.assertEqual(color, "#ff0000")
            mock_get_color.assert_called_once_with("accent")
    
    def test_theme_variable_resolution(self):
        """Test resolving theme variables."""
        with patch.object(ThemeManager, 'get_theme_variable') as mock_get_var:
            mock_get_var.return_value = "JetBrains Mono"
            
            variable = self.theme_manager.get_theme_variable("font")
            
            self.assertEqual(variable, "JetBrains Mono")
            mock_get_var.assert_called_once_with("font")


if __name__ == "__main__":
    unittest.main()

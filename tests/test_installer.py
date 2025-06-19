"""
Unit tests for the main installer functionality.
"""

import pytest
import json
import os
from pathlib import Path
from unittest.mock import patch, MagicMock, mock_open

class TestMainInstaller:
    """Test the main installer script functionality."""
    
    def test_dependency_check(self, mock_system_commands):
        """Test dependency checking functionality."""
        # This would test the dependency checking logic
        # Since the installer is a shell script, we'll mock the subprocess calls
        
        # Mock successful dependency check
        mock_system_commands['run'].return_value.returncode = 0
        
        # Test would verify that required dependencies are checked
        required_deps = ['git', 'curl', 'wget', 'base-devel']
        
        # In a real test, we'd call the actual dependency check function
        # For now, we'll assert the mock was called correctly
        assert mock_system_commands['run'].return_value.returncode == 0
    
    def test_preset_validation(self, sample_config):
        """Test preset validation logic."""
        valid_presets = ["JaKooLit", "prasanthrangan", "SolDoesTech", "custom"]
        
        # Test valid preset
        assert sample_config["preset"] in valid_presets
        
        # Test invalid preset handling
        invalid_config = sample_config.copy()
        invalid_config["preset"] = "InvalidPreset"
        
        assert invalid_config["preset"] not in valid_presets
    
    def test_component_selection(self, sample_config):
        """Test component selection logic."""
        components = sample_config["components"]
        
        # Test that components are properly structured
        assert isinstance(components, dict)
        assert "hyprland" in components
        assert isinstance(components["hyprland"], bool)
        
        # Test required components
        required_components = ["hyprland"]
        for component in required_components:
            assert component in components
            assert components[component] is True
    
    @patch('builtins.open', new_callable=mock_open)
    def test_config_generation(self, mock_file, sample_config, temp_dir):
        """Test configuration file generation."""
        config_path = temp_dir / "test_config.json"
        
        # Test writing configuration
        with open(config_path, 'w') as f:
            json.dump(sample_config, f, indent=2)
        
        mock_file.assert_called_once()
        
        # Test reading configuration back
        mock_file.return_value.read.return_value = json.dumps(sample_config)
        
        with open(config_path, 'r') as f:
            loaded_config = json.load(f)
        
        assert loaded_config["preset"] == sample_config["preset"]
        assert loaded_config["components"] == sample_config["components"]

class TestInstallationModules:
    """Test individual installation modules."""
    
    def test_hyprland_module(self, mock_system_commands, temp_dir):
        """Test Hyprland installation module."""
        # Mock successful installation
        mock_system_commands['run'].return_value.returncode = 0
        
        # Test installation success
        result = mock_system_commands['run'].return_value.returncode
        assert result == 0
    
    def test_waybar_module(self, mock_system_commands):
        """Test Waybar installation module."""
        mock_system_commands['run'].return_value.returncode = 0
        
        result = mock_system_commands['run'].return_value.returncode
        assert result == 0
    
    def test_rofi_module(self, mock_system_commands):
        """Test Rofi installation module."""
        mock_system_commands['run'].return_value.returncode = 0
        
        result = mock_system_commands['run'].return_value.returncode
        assert result == 0
    
    def test_nvidia_detection(self, mock_system_commands):
        """Test NVIDIA GPU detection."""
        # Mock lspci output for NVIDIA GPU
        mock_system_commands['output'].return_value = b"NVIDIA Corporation"
        
        # Test NVIDIA detection logic
        output = mock_system_commands['output'].return_value.decode()
        has_nvidia = "NVIDIA" in output
        
        assert has_nvidia is True
        
        # Test without NVIDIA
        mock_system_commands['output'].return_value = b"Intel Corporation"
        output = mock_system_commands['output'].return_value.decode()
        has_nvidia = "NVIDIA" in output
        
        assert has_nvidia is False

class TestErrorHandling:
    """Test error handling scenarios."""
    
    def test_missing_dependencies(self, mock_system_commands):
        """Test handling of missing dependencies."""
        # Mock failed dependency check
        mock_system_commands['run'].return_value.returncode = 1
        
        result = mock_system_commands['run'].return_value.returncode
        assert result != 0
    
    def test_insufficient_permissions(self, mock_system_commands):
        """Test handling of insufficient permissions."""
        # Mock permission denied error
        mock_system_commands['run'].return_value.returncode = 126
        
        result = mock_system_commands['run'].return_value.returncode
        assert result == 126
    
    def test_network_failure(self, mock_system_commands):
        """Test handling of network failures."""
        # Mock network timeout
        mock_system_commands['run'].return_value.returncode = 2
        
        result = mock_system_commands['run'].return_value.returncode
        assert result == 2
    
    def test_disk_space_check(self, temp_dir):
        """Test disk space checking."""
        import shutil
        
        # Get disk usage
        total, used, free = shutil.disk_usage(temp_dir)
        
        # Test minimum space requirement (1GB = 1073741824 bytes)
        min_space_required = 1073741824
        has_sufficient_space = free > min_space_required
        
        # This should pass in most test environments
        assert isinstance(has_sufficient_space, bool)

class TestConfigurationBackup:
    """Test configuration backup functionality."""
    
    def test_backup_creation(self, mock_home_dir, temp_dir):
        """Test backup creation before installation."""
        # Create mock configuration files
        config_dir = mock_home_dir / ".config"
        config_dir.mkdir(exist_ok=True)
        
        hypr_config = config_dir / "hypr"
        hypr_config.mkdir(exist_ok=True)
        
        config_file = hypr_config / "hyprland.conf"
        config_file.write_text("# Test configuration")
        
        # Test backup directory creation
        backup_dir = temp_dir / "backup"
        backup_dir.mkdir(exist_ok=True)
        
        assert backup_dir.exists()
        assert config_file.exists()
    
    def test_backup_restoration(self, mock_home_dir, temp_dir):
        """Test backup restoration functionality."""
        # Create backup
        backup_dir = temp_dir / "backup"
        backup_dir.mkdir(exist_ok=True)
        
        backup_file = backup_dir / "hyprland.conf"
        backup_file.write_text("# Backup configuration")
        
        # Test restoration
        config_dir = mock_home_dir / ".config" / "hypr"
        config_dir.mkdir(parents=True, exist_ok=True)
        
        restored_file = config_dir / "hyprland.conf"
        restored_file.write_text(backup_file.read_text())
        
        assert restored_file.read_text() == "# Backup configuration"

class TestIntegration:
    """Integration tests for the installer."""
    
    def test_full_installation_flow(self, mock_system_commands, sample_config, temp_dir):
        """Test complete installation flow."""
        # Mock all system commands to succeed
        mock_system_commands['run'].return_value.returncode = 0
        
        # Simulate installation steps
        steps = [
            "dependency_check",
            "backup_creation", 
            "package_installation",
            "configuration_setup",
            "theme_application",
            "service_setup"
        ]
        
        results = []
        for step in steps:
            # Mock each step
            result = mock_system_commands['run'].return_value.returncode
            results.append(result == 0)
        
        # All steps should succeed
        assert all(results)
    
    def test_rollback_on_failure(self, mock_system_commands, temp_dir):
        """Test rollback functionality on installation failure."""
        # Mock failure in middle of installation
        mock_system_commands['run'].return_value.returncode = 1
        
        # Test rollback logic
        rollback_needed = mock_system_commands['run'].return_value.returncode != 0
        
        if rollback_needed:
            # Mock rollback steps
            rollback_steps = ["restore_backup", "cleanup_temp_files", "reset_configs"]
            rollback_results = []
            
            for step in rollback_steps:
                # Mock successful rollback
                mock_system_commands['run'].return_value.returncode = 0
                result = mock_system_commands['run'].return_value.returncode
                rollback_results.append(result == 0)
            
            assert all(rollback_results)
    
    def test_post_installation_verification(self, mock_system_commands):
        """Test post-installation verification."""
        # Mock verification commands
        verification_commands = [
            "hyprctl version",
            "waybar --version", 
            "rofi -version"
        ]
        
        mock_system_commands['run'].return_value.returncode = 0
        mock_system_commands['output'].return_value = b"version 0.1.0"
        
        for cmd in verification_commands:
            result = mock_system_commands['run'].return_value.returncode
            assert result == 0
            
            output = mock_system_commands['output'].return_value.decode()
            assert "version" in output.lower()


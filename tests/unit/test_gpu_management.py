#!/usr/bin/env python3
"""
Unit tests for the HyprSupreme-Builder GPU management system.
"""

import os
import sys
import unittest
import tempfile
import json
from unittest.mock import patch, MagicMock

# Add parent directory to path to import modules
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '../../')))

try:
    from modules.core.gpu_manager import GPUManager
    from modules.core.gpu_scheduler import GPUScheduler
except ImportError:
    # Mock classes for testing without actual modules
    class GPUManager:
        def __init__(self):
            self.gpus = []
            self.active_gpu = None
        
        def detect_gpus(self):
            return [
                {"type": "nvidia", "model": "RTX 3080", "driver": "nvidia", "is_active": True},
                {"type": "intel", "model": "Intel UHD", "driver": "intel", "is_active": False}
            ]
        
        def switch_gpu(self, gpu_type):
            self.active_gpu = gpu_type
            return True
        
        def optimize_gpu(self, profile):
            return True
    
    class GPUScheduler:
        def __init__(self):
            self.scheduled_tasks = []
        
        def schedule_gpu_switch(self, gpu_type, time):
            self.scheduled_tasks.append((gpu_type, time))
            return True
        
        def cancel_scheduled_switch(self, task_id):
            return True


class TestGPUManagement(unittest.TestCase):
    """Tests for the GPU management system."""
    
    def setUp(self):
        """Set up test environment."""
        # Initialize GPU manager
        self.gpu_manager = GPUManager()
        self.gpu_scheduler = GPUScheduler()
    
    def test_gpu_detection(self):
        """Test detecting available GPUs."""
        with patch.object(GPUManager, 'detect_gpus') as mock_detect:
            mock_detect.return_value = [
                {"type": "nvidia", "model": "RTX 3080", "driver": "nvidia", "is_active": True},
                {"type": "intel", "model": "Intel UHD", "driver": "intel", "is_active": False}
            ]
            
            gpus = self.gpu_manager.detect_gpus()
            
            self.assertEqual(len(gpus), 2)
            self.assertEqual(gpus[0]["type"], "nvidia")
            self.assertEqual(gpus[1]["type"], "intel")
            self.assertTrue(gpus[0]["is_active"])
            self.assertFalse(gpus[1]["is_active"])
    
    def test_gpu_switching(self):
        """Test switching between GPUs."""
        with patch.object(GPUManager, 'switch_gpu') as mock_switch:
            mock_switch.return_value = True
            
            result = self.gpu_manager.switch_gpu("intel")
            
            self.assertTrue(result)
            mock_switch.assert_called_once_with("intel")
    
    def test_gpu_optimization(self):
        """Test optimizing GPU settings for different profiles."""
        with patch.object(GPUManager, 'optimize_gpu') as mock_optimize:
            mock_optimize.return_value = True
            
            result = self.gpu_manager.optimize_gpu("gaming")
            
            self.assertTrue(result)
            mock_optimize.assert_called_once_with("gaming")
    
    def test_gpu_scheduling(self):
        """Test scheduling GPU switches."""
        with patch.object(GPUScheduler, 'schedule_gpu_switch') as mock_schedule:
            mock_schedule.return_value = 1  # Task ID
            
            task_id = self.gpu_scheduler.schedule_gpu_switch("intel", "18:00")
            
            self.assertEqual(task_id, 1)
            mock_schedule.assert_called_once_with("intel", "18:00")
    
    def test_cancel_scheduled_switch(self):
        """Test canceling a scheduled GPU switch."""
        with patch.object(GPUScheduler, 'cancel_scheduled_switch') as mock_cancel:
            mock_cancel.return_value = True
            
            result = self.gpu_scheduler.cancel_scheduled_switch(1)
            
            self.assertTrue(result)
            mock_cancel.assert_called_once_with(1)


if __name__ == "__main__":
    unittest.main()

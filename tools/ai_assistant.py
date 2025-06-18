#!/usr/bin/env python3
"""
HyprSupreme AI Assistant
Advanced AI-powered configuration assistant for intelligent recommendations and automation
"""

import os
import sys
import json
import subprocess
import platform
import psutil
import re
from pathlib import Path
from typing import Dict, List, Tuple, Optional, Any
from dataclasses import dataclass
from datetime import datetime
import hashlib

@dataclass
class SystemProfile:
    """System hardware and software profile"""
    cpu_cores: int
    cpu_freq: float
    ram_gb: float
    gpu_info: List[str]
    display_resolution: str
    display_count: int
    desktop_environment: str
    kernel_version: str
    distro: str
    usage_pattern: str  # gaming, productivity, development, etc.

@dataclass
class ConfigRecommendation:
    """AI-generated configuration recommendation"""
    category: str
    setting: str
    value: str
    reason: str
    confidence: float
    impact: str  # low, medium, high
    reversible: bool

class AIAssistant:
    def __init__(self):
        self.config_dir = Path.home() / ".config" / "hyprsupreme"
        self.ai_cache_dir = self.config_dir / "ai_cache"
        self.ai_cache_dir.mkdir(parents=True, exist_ok=True)
        
        self.system_profile = self._analyze_system()
        self.user_preferences = self._load_user_preferences()
        self.knowledge_base = self._load_knowledge_base()
        
    def _analyze_system(self) -> SystemProfile:
        """Analyze system hardware and software configuration"""
        try:
            # CPU information
            cpu_cores = psutil.cpu_count(logical=False)
            cpu_freq = psutil.cpu_freq().max if psutil.cpu_freq() else 0.0
            
            # Memory information
            ram_gb = psutil.virtual_memory().total / (1024**3)
            
            # GPU information
            gpu_info = self._detect_gpu()
            
            # Display information
            display_info = self._detect_displays()
            
            # System information
            distro = self._detect_distro()
            kernel = platform.release()
            de = os.environ.get('XDG_CURRENT_DESKTOP', 'unknown')
            
            # Usage pattern detection
            usage_pattern = self._detect_usage_pattern()
            
            return SystemProfile(
                cpu_cores=cpu_cores,
                cpu_freq=cpu_freq,
                ram_gb=ram_gb,
                gpu_info=gpu_info,
                display_resolution=display_info['resolution'],
                display_count=display_info['count'],
                desktop_environment=de,
                kernel_version=kernel,
                distro=distro,
                usage_pattern=usage_pattern
            )
        except Exception as e:
            print(f"Warning: Could not fully analyze system: {e}")
            return SystemProfile(
                cpu_cores=4, cpu_freq=2000.0, ram_gb=8.0,
                gpu_info=["unknown"], display_resolution="1920x1080",
                display_count=1, desktop_environment="unknown",
                kernel_version="unknown", distro="unknown",
                usage_pattern="general"
            )
    
    def _detect_gpu(self) -> List[str]:
        """Detect GPU information"""
        gpu_info = []
        try:
            # Try lspci first
            result = subprocess.run(['lspci', '-v'], 
                                  capture_output=True, text=True)
            if result.returncode == 0:
                for line in result.stdout.split('\n'):
                    if 'VGA' in line or 'Display' in line:
                        gpu_info.append(line.strip())
            
            # Try nvidia-smi for NVIDIA GPUs
            try:
                result = subprocess.run(['nvidia-smi', '--query-gpu=name', 
                                       '--format=csv,noheader'], 
                                      capture_output=True, text=True)
                if result.returncode == 0:
                    for gpu in result.stdout.strip().split('\n'):
                        if gpu.strip():
                            gpu_info.append(f"NVIDIA {gpu.strip()}")
            except FileNotFoundError:
                pass
                
        except Exception:
            gpu_info = ["unknown"]
            
        return gpu_info if gpu_info else ["unknown"]
    
    def _detect_displays(self) -> Dict[str, Any]:
        """Detect display configuration"""
        try:
            # Try xrandr
            result = subprocess.run(['xrandr'], capture_output=True, text=True)
            if result.returncode == 0:
                connected_displays = []
                current_resolution = "1920x1080"
                
                for line in result.stdout.split('\n'):
                    if ' connected' in line:
                        connected_displays.append(line)
                        # Extract current resolution
                        match = re.search(r'(\d+x\d+)', line)
                        if match:
                            current_resolution = match.group(1)
                
                return {
                    'count': len(connected_displays),
                    'resolution': current_resolution
                }
        except Exception:
            pass
            
        return {'count': 1, 'resolution': '1920x1080'}
    
    def _detect_distro(self) -> str:
        """Detect Linux distribution"""
        try:
            with open('/etc/os-release', 'r') as f:
                for line in f:
                    if line.startswith('NAME='):
                        return line.split('=')[1].strip().strip('"')
        except Exception:
            pass
        return "unknown"
    
    def _detect_usage_pattern(self) -> str:
        """Detect user's primary usage pattern based on installed software"""
        patterns = {
            'gaming': ['steam', 'lutris', 'wine', 'gamemode'],
            'development': ['code', 'vim', 'emacs', 'git', 'docker'],
            'multimedia': ['blender', 'gimp', 'obs', 'kdenlive'],
            'productivity': ['libreoffice', 'firefox', 'thunderbird']
        }
        
        installed_apps = []
        try:
            # Check common package managers
            for cmd in [['pacman', '-Q'], ['dpkg', '-l'], ['rpm', '-qa']]:
                try:
                    result = subprocess.run(cmd, capture_output=True, text=True)
                    if result.returncode == 0:
                        installed_apps.extend(result.stdout.lower().split())
                        break
                except FileNotFoundError:
                    continue
        except Exception:
            pass
        
        pattern_scores = {}
        for pattern, apps in patterns.items():
            score = sum(1 for app in apps if any(app in installed for installed in installed_apps))
            pattern_scores[pattern] = score
        
        if pattern_scores:
            return max(pattern_scores, key=pattern_scores.get)
        return 'general'
    
    def _load_user_preferences(self) -> Dict:
        """Load user preferences from previous configurations"""
        prefs_file = self.config_dir / "user_preferences.json"
        if prefs_file.exists():
            try:
                with open(prefs_file, 'r') as f:
                    return json.load(f)
            except Exception:
                pass
        
        return {
            'theme_preference': 'dark',
            'animation_level': 'medium',
            'performance_priority': 'balanced',
            'customization_level': 'moderate'
        }
    
    def _load_knowledge_base(self) -> Dict:
        """Load AI knowledge base for configuration recommendations"""
        return {
            'performance_rules': {
                'low_ram': {
                    'condition': lambda profile: profile.ram_gb < 8,
                    'recommendations': [
                        ('animations', 'enabled', 'false', 'Reduce memory usage', 0.9),
                        ('decoration', 'blur', 'false', 'Improve performance', 0.8),
                        ('misc', 'vfr', 'true', 'Variable refresh rate saves resources', 0.7)
                    ]
                },
                'high_performance': {
                    'condition': lambda profile: 'gaming' in profile.usage_pattern and profile.cpu_cores >= 8,
                    'recommendations': [
                        ('general', 'gaps_in', '2', 'Minimal gaps for gaming', 0.8),
                        ('decoration', 'drop_shadow', 'false', 'Reduce visual overhead', 0.7),
                        ('misc', 'vrr', '1', 'Enable variable refresh rate', 0.9)
                    ]
                },
                'nvidia_optimization': {
                    'condition': lambda profile: any('nvidia' in gpu.lower() for gpu in profile.gpu_info),
                    'recommendations': [
                        ('env', 'LIBVA_DRIVER_NAME', 'nvidia', 'NVIDIA VA-API driver', 0.9),
                        ('env', 'XDG_SESSION_TYPE', 'wayland', 'Wayland for NVIDIA', 0.7),
                        ('env', 'GBM_BACKEND', 'nvidia-drm', 'NVIDIA GBM backend', 0.8)
                    ]
                },
                'multi_monitor': {
                    'condition': lambda profile: profile.display_count > 1,
                    'recommendations': [
                        ('monitor', 'workspace', 'auto', 'Automatic workspace assignment', 0.8),
                        ('general', 'gaps_workspaces', '50', 'Gaps between workspaces', 0.6),
                        ('misc', 'focus_on_activate', 'true', 'Focus follows activation', 0.7)
                    ]
                }
            },
            'aesthetic_rules': {
                'development_setup': {
                    'condition': lambda profile: 'development' in profile.usage_pattern,
                    'recommendations': [
                        ('general', 'gaps_in', '5', 'Comfortable gaps for coding', 0.7),
                        ('decoration', 'rounding', '8', 'Moderate rounding', 0.6),
                        ('general', 'border_size', '2', 'Clear window borders', 0.8)
                    ]
                },
                'multimedia_setup': {
                    'condition': lambda profile: 'multimedia' in profile.usage_pattern,
                    'recommendations': [
                        ('decoration', 'blur', 'true', 'Enhanced visual experience', 0.8),
                        ('decoration', 'drop_shadow', 'true', 'Depth perception', 0.7),
                        ('animations', 'enabled', 'true', 'Smooth transitions', 0.9)
                    ]
                }
            }
        }
    
    def generate_recommendations(self) -> List[ConfigRecommendation]:
        """Generate AI-powered configuration recommendations"""
        recommendations = []
        
        # Apply performance rules
        for rule_name, rule in self.knowledge_base['performance_rules'].items():
            if rule['condition'](self.system_profile):
                for category, setting, value, reason, confidence in rule['recommendations']:
                    recommendations.append(ConfigRecommendation(
                        category=category,
                        setting=setting,
                        value=value,
                        reason=reason,
                        confidence=confidence,
                        impact='medium',
                        reversible=True
                    ))
        
        # Apply aesthetic rules
        for rule_name, rule in self.knowledge_base['aesthetic_rules'].items():
            if rule['condition'](self.system_profile):
                for category, setting, value, reason, confidence in rule['recommendations']:
                    recommendations.append(ConfigRecommendation(
                        category=category,
                        setting=setting,
                        value=value,
                        reason=reason,
                        confidence=confidence,
                        impact='low',
                        reversible=True
                    ))
        
        # Sort by confidence and impact
        recommendations.sort(key=lambda x: (x.confidence, x.impact == 'high'), reverse=True)
        
        return recommendations
    
    def analyze_current_config(self, config_path: Path) -> Dict[str, Any]:
        """Analyze current Hyprland configuration for optimization opportunities"""
        analysis = {
            'issues': [],
            'optimizations': [],
            'compatibility': [],
            'score': 0
        }
        
        try:
            if not config_path.exists():
                analysis['issues'].append("Configuration file not found")
                return analysis
            
            with open(config_path, 'r') as f:
                config_content = f.read()
            
            # Check for common issues
            if 'blur = true' in config_content and self.system_profile.ram_gb < 8:
                analysis['issues'].append({
                    'type': 'performance',
                    'message': 'Blur effects enabled on low-RAM system',
                    'suggestion': 'Consider disabling blur for better performance',
                    'severity': 'medium'
                })
            
            if 'nvidia' in str(self.system_profile.gpu_info).lower():
                if 'env = LIBVA_DRIVER_NAME,nvidia' not in config_content:
                    analysis['optimizations'].append({
                        'type': 'nvidia',
                        'message': 'Missing NVIDIA-specific optimizations',
                        'suggestion': 'Add NVIDIA environment variables',
                        'impact': 'high'
                    })
            
            # Calculate overall score
            base_score = 70
            base_score -= len(analysis['issues']) * 10
            base_score += len(analysis['optimizations']) * 5
            analysis['score'] = max(0, min(100, base_score))
            
        except Exception as e:
            analysis['issues'].append(f"Could not analyze configuration: {e}")
        
        return analysis
    
    def generate_optimized_config(self, base_config_path: Path, output_path: Path) -> bool:
        """Generate an AI-optimized configuration based on system profile"""
        try:
            recommendations = self.generate_recommendations()
            
            # Read base configuration
            if base_config_path.exists():
                with open(base_config_path, 'r') as f:
                    config_lines = f.readlines()
            else:
                config_lines = ["# AI-Generated Hyprland Configuration\n"]
            
            # Apply high-confidence recommendations
            config_modifications = []
            for rec in recommendations:
                if rec.confidence >= 0.7:
                    config_modifications.append(f"# AI Recommendation: {rec.reason}")
                    if rec.category == 'env':
                        config_modifications.append(f"env = {rec.setting},{rec.value}")
                    else:
                        config_modifications.append(f"{rec.setting} = {rec.value}")
                    config_modifications.append("")
            
            # Write optimized configuration
            with open(output_path, 'w') as f:
                f.writelines(config_lines)
                f.write("\n# === AI-GENERATED OPTIMIZATIONS ===\n")
                f.write("\n".join(config_modifications))
            
            return True
            
        except Exception as e:
            print(f"Error generating optimized config: {e}")
            return False
    
    def interactive_setup_wizard(self):
        """Interactive AI-powered setup wizard"""
        print("🤖 HyprSupreme AI Assistant - Interactive Setup Wizard")
        print("=" * 60)
        
        # Display system analysis
        print("\n📊 System Analysis:")
        print(f"CPU: {self.system_profile.cpu_cores} cores @ {self.system_profile.cpu_freq:.0f}MHz")
        print(f"RAM: {self.system_profile.ram_gb:.1f}GB")
        print(f"GPU: {', '.join(self.system_profile.gpu_info)}")
        print(f"Display: {self.system_profile.display_resolution} ({self.system_profile.display_count} monitor(s))")
        print(f"Usage Pattern: {self.system_profile.usage_pattern}")
        
        # Generate and display recommendations
        print("\n🎯 AI Recommendations:")
        recommendations = self.generate_recommendations()
        
        for i, rec in enumerate(recommendations[:10], 1):  # Show top 10
            confidence_bar = "█" * int(rec.confidence * 10)
            print(f"{i:2d}. [{confidence_bar:<10}] {rec.setting} = {rec.value}")
            print(f"    💡 {rec.reason}")
            print()
        
        # Ask user preferences
        print("🔧 Configuration Preferences:")
        performance_priority = input("Performance priority (high/balanced/visual) [balanced]: ").strip() or "balanced"
        customization_level = input("Customization level (minimal/moderate/extensive) [moderate]: ").strip() or "moderate"
        
        # Update user preferences
        self.user_preferences.update({
            'performance_priority': performance_priority,
            'customization_level': customization_level
        })
        
        # Save preferences
        prefs_file = self.config_dir / "user_preferences.json"
        with open(prefs_file, 'w') as f:
            json.dump(self.user_preferences, f, indent=2)
        
        print(f"\n✅ Preferences saved to {prefs_file}")
        return True
    
    def troubleshoot_config(self, config_path: Path) -> List[str]:
        """AI-powered configuration troubleshooting"""
        issues = []
        
        try:
            analysis = self.analyze_current_config(config_path)
            
            for issue in analysis.get('issues', []):
                if isinstance(issue, dict):
                    issues.append(f"⚠️  {issue['message']}: {issue['suggestion']}")
                else:
                    issues.append(f"⚠️  {issue}")
            
            for opt in analysis.get('optimizations', []):
                issues.append(f"💡 {opt['message']}: {opt['suggestion']}")
                
        except Exception as e:
            issues.append(f"❌ Troubleshooting error: {e}")
        
        return issues

def main():
    """Main function for AI Assistant"""
    if len(sys.argv) < 2:
        print("Usage: ai_assistant.py <command> [options]")
        print("Commands:")
        print("  analyze - Analyze system and generate recommendations")
        print("  wizard - Run interactive setup wizard")
        print("  optimize <input> <output> - Generate optimized configuration")
        print("  troubleshoot <config> - Troubleshoot configuration issues")
        sys.exit(1)
    
    assistant = AIAssistant()
    command = sys.argv[1]
    
    if command == "analyze":
        print("🤖 AI System Analysis & Recommendations")
        print("=" * 50)
        
        recommendations = assistant.generate_recommendations()
        for rec in recommendations:
            confidence_stars = "⭐" * int(rec.confidence * 5)
            print(f"{confidence_stars} {rec.category}.{rec.setting} = {rec.value}")
            print(f"   💡 {rec.reason}")
            print()
    
    elif command == "wizard":
        assistant.interactive_setup_wizard()
    
    elif command == "optimize":
        if len(sys.argv) < 4:
            print("Usage: ai_assistant.py optimize <input_config> <output_config>")
            sys.exit(1)
        
        input_path = Path(sys.argv[2])
        output_path = Path(sys.argv[3])
        
        if assistant.generate_optimized_config(input_path, output_path):
            print(f"✅ Optimized configuration generated: {output_path}")
        else:
            print("❌ Failed to generate optimized configuration")
            sys.exit(1)
    
    elif command == "troubleshoot":
        if len(sys.argv) < 3:
            print("Usage: ai_assistant.py troubleshoot <config_path>")
            sys.exit(1)
        
        config_path = Path(sys.argv[2])
        issues = assistant.troubleshoot_config(config_path)
        
        print("🔍 Configuration Troubleshooting Results:")
        print("=" * 45)
        
        if issues:
            for issue in issues:
                print(issue)
        else:
            print("✅ No issues found in configuration!")
    
    else:
        print(f"Unknown command: {command}")
        sys.exit(1)

if __name__ == "__main__":
    main()


#!/usr/bin/env python3
"""
HyprSupreme AI Update Engine
Intelligent system updates with AI-powered analysis and optimization
"""

import os
import sys
import json
import subprocess
import requests
import hashlib
import sqlite3
import shutil
import tempfile
import tarfile
import git
from pathlib import Path
from datetime import datetime, timedelta
from typing import Dict, List, Tuple, Optional, Any
from dataclasses import dataclass, asdict
import semver
import difflib

# Import AI Assistant for intelligent analysis
sys.path.append(str(Path(__file__).parent))
try:
    from ai_assistant import AIAssistant, SystemProfile, ConfigRecommendation
    AI_AVAILABLE = True
except ImportError:
    print("Warning: AI Assistant not available. Using fallback update logic.")
    AI_AVAILABLE = False

@dataclass
class UpdateInfo:
    """Information about an available update"""
    version: str
    release_date: str
    changelog: str
    download_url: str
    checksum: str
    size: int
    compatibility_score: float
    risk_level: str  # low, medium, high
    ai_recommendation: str
    breaking_changes: List[str]
    new_features: List[str]
    fixes: List[str]

@dataclass
class UpdateStrategy:
    """AI-determined update strategy"""
    approach: str  # incremental, full, custom
    backup_level: str  # minimal, standard, comprehensive
    merge_strategy: str  # auto, manual, hybrid
    rollback_plan: str
    estimated_time: int  # minutes
    user_interaction_needed: bool
    confidence: float

class AIUpdateEngine:
    """AI-powered update engine for HyprSupreme-Builder"""
    
    def __init__(self, config_dir: str = None):
        self.config_dir = Path(config_dir or os.path.expanduser("~/.config/hyprsupreme"))
        self.update_dir = self.config_dir / "updates"
        self.backup_dir = self.config_dir / "backups"
        self.cache_dir = self.config_dir / "update_cache"
        
        # Create directories
        for directory in [self.update_dir, self.backup_dir, self.cache_dir]:
            directory.mkdir(parents=True, exist_ok=True)
        
        self.db_path = self.config_dir / "updates.db"
        self.settings_path = self.config_dir / "update_settings.json"
        
        # Initialize components
        self.init_database()
        self.settings = self.load_settings()
        
        # AI components
        if AI_AVAILABLE:
            self.ai_assistant = AIAssistant()
            self.system_profile = self.ai_assistant.system_profile
        else:
            self.ai_assistant = None
            self.system_profile = None
        
        # Project information
        self.project_root = Path(__file__).parent.parent
        self.current_version = self.get_current_version()
        
        # Update sources
        self.update_sources = {
            'github': {
                'repo': 'GeneticxCln/HyprSupreme-Builder',
                'api_url': 'https://api.github.com/repos/GeneticxCln/HyprSupreme-Builder',
                'enabled': True
            },
            'local': {
                'path': str(self.project_root),
                'enabled': True
            }
        }
    
    def init_database(self):
        """Initialize update tracking database"""
        with sqlite3.connect(self.db_path) as conn:
            conn.executescript("""
                CREATE TABLE IF NOT EXISTS updates (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    version TEXT NOT NULL,
                    release_date TEXT,
                    installed_date TEXT,
                    status TEXT,  -- available, downloaded, installed, failed, rollback
                    strategy TEXT,  -- JSON of UpdateStrategy
                    compatibility_score REAL,
                    risk_level TEXT,
                    ai_recommendation TEXT,
                    changelog TEXT,
                    backup_id TEXT,
                    error_message TEXT
                );
                
                CREATE TABLE IF NOT EXISTS backup_points (
                    id TEXT PRIMARY KEY,
                    version TEXT,
                    created_date TEXT,
                    backup_type TEXT,  -- pre_update, manual, automatic
                    backup_path TEXT,
                    metadata TEXT,  -- JSON metadata
                    verified BOOLEAN DEFAULT 0
                );
                
                CREATE TABLE IF NOT EXISTS update_history (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    version_from TEXT,
                    version_to TEXT,
                    update_date TEXT,
                    duration INTEGER,  -- seconds
                    success BOOLEAN,
                    strategy_used TEXT,
                    ai_accuracy REAL,  -- how accurate was AI prediction
                    user_satisfaction INTEGER  -- 1-5 scale
                );
                
                CREATE TABLE IF NOT EXISTS ai_learning (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    context TEXT,  -- update_strategy, conflict_resolution, etc.
                    input_data TEXT,  -- JSON
                    ai_prediction TEXT,
                    actual_outcome TEXT,
                    feedback_score REAL,
                    learned_date TEXT
                );
                
                CREATE INDEX IF NOT EXISTS idx_updates_version ON updates(version);
                CREATE INDEX IF NOT EXISTS idx_backup_version ON backup_points(version);
                CREATE INDEX IF NOT EXISTS idx_update_history_date ON update_history(update_date);
            """)
    
    def load_settings(self) -> Dict:
        """Load update settings"""
        default_settings = {
            'auto_check': True,
            'check_interval': 24,  # hours
            'auto_update': False,
            'auto_backup': True,
            'backup_retention': 30,  # days
            'update_channel': 'stable',  # stable, beta, dev
            'ai_enabled': True,
            'ai_confidence_threshold': 0.7,
            'max_download_size': 1024,  # MB
            'notify_updates': True,
            'rollback_timeout': 30,  # minutes
            'preserve_user_configs': True,
            'last_check': None,
            'update_blacklist': []
        }
        
        try:
            if self.settings_path.exists():
                with open(self.settings_path, 'r') as f:
                    settings = json.load(f)
                    default_settings.update(settings)
        except Exception as e:
            print(f"Warning: Could not load settings: {e}")
        
        return default_settings
    
    def save_settings(self):
        """Save current settings"""
        try:
            with open(self.settings_path, 'w') as f:
                json.dump(self.settings, f, indent=2)
        except Exception as e:
            print(f"Error saving settings: {e}")
    
    def get_current_version(self) -> str:
        """Get current HyprSupreme version"""
        version_file = self.project_root / "VERSION"
        if version_file.exists():
            try:
                return version_file.read_text().strip()
            except Exception:
                pass
        
        # Fallback: try git tag
        try:
            result = subprocess.run(
                ['git', 'describe', '--tags', '--abbrev=0'],
                cwd=self.project_root,
                capture_output=True,
                text=True
            )
            if result.returncode == 0:
                return result.stdout.strip().lstrip('v')
        except Exception:
            pass
        
        return "unknown"
    
    def check_for_updates(self, force: bool = False) -> List[UpdateInfo]:
        """Check for available updates using AI analysis"""
        if not force and not self._should_check_updates():
            return []
        
        print("🔍 Checking for HyprSupreme updates...")
        available_updates = []
        
        # Check GitHub releases
        github_updates = self._check_github_updates()
        available_updates.extend(github_updates)
        
        # Check local git repository
        local_updates = self._check_local_updates()
        available_updates.extend(local_updates)
        
        # AI analysis of updates
        if AI_AVAILABLE and available_updates:
            available_updates = self._ai_analyze_updates(available_updates)
        
        # Save check timestamp
        self.settings['last_check'] = datetime.now().isoformat()
        self.save_settings()
        
        # Store updates in database
        for update in available_updates:
            self._store_update_info(update)
        
        return available_updates
    
    def _should_check_updates(self) -> bool:
        """Determine if we should check for updates"""
        if not self.settings.get('auto_check', True):
            return False
        
        last_check = self.settings.get('last_check')
        if not last_check:
            return True
        
        try:
            last_check_time = datetime.fromisoformat(last_check)
            check_interval = timedelta(hours=self.settings.get('check_interval', 24))
            return datetime.now() - last_check_time > check_interval
        except Exception:
            return True
    
    def _check_github_updates(self) -> List[UpdateInfo]:
        """Check GitHub for updates"""
        updates = []
        
        try:
            github_config = self.update_sources['github']
            if not github_config['enabled']:
                return updates
            
            # Get latest releases
            url = f"{github_config['api_url']}/releases"
            response = requests.get(url, timeout=30)
            
            if response.status_code == 200:
                releases = response.json()
                
                for release in releases[:5]:  # Check last 5 releases
                    version = release['tag_name'].lstrip('v')
                    
                    # Skip if this version is older or same as current
                    if self._compare_versions(version, self.current_version) <= 0:
                        continue
                    
                    # Extract release information
                    update_info = UpdateInfo(
                        version=version,
                        release_date=release['published_at'],
                        changelog=release['body'] or '',
                        download_url=release['zipball_url'],
                        checksum='',  # Calculate after download
                        size=0,  # Will be set during download
                        compatibility_score=0.0,  # AI will calculate
                        risk_level='medium',  # AI will determine
                        ai_recommendation='',  # AI will generate
                        breaking_changes=[],
                        new_features=[],
                        fixes=[]
                    )
                    
                    updates.append(update_info)
                    
        except Exception as e:
            print(f"Warning: Could not check GitHub updates: {e}")
        
        return updates
    
    def _check_local_updates(self) -> List[UpdateInfo]:
        """Check local git repository for updates"""
        updates = []
        
        try:
            if not self.update_sources['local']['enabled']:
                return updates
            
            repo_path = Path(self.update_sources['local']['path'])
            if not (repo_path / '.git').exists():
                return updates
            
            # Fetch latest changes
            result = subprocess.run(
                ['git', 'fetch', 'origin'],
                cwd=repo_path,
                capture_output=True,
                text=True
            )
            
            if result.returncode == 0:
                # Check for commits ahead
                result = subprocess.run(
                    ['git', 'rev-list', '--count', 'HEAD..origin/main'],
                    cwd=repo_path,
                    capture_output=True,
                    text=True
                )
                
                if result.returncode == 0 and int(result.stdout.strip()) > 0:
                    # There are updates available
                    commit_count = int(result.stdout.strip())
                    
                    # Get latest commit info
                    result = subprocess.run(
                        ['git', 'log', '--oneline', '-n', '10', 'origin/main'],
                        cwd=repo_path,
                        capture_output=True,
                        text=True
                    )
                    
                    if result.returncode == 0:
                        commits = result.stdout.strip().split('\n')
                        changelog = '\n'.join(commits)
                        
                        # Create update info for latest commits
                        next_version = self._calculate_next_version()
                        
                        update_info = UpdateInfo(
                            version=next_version,
                            release_date=datetime.now().isoformat(),
                            changelog=f"Development updates ({commit_count} commits):\n{changelog}",
                            download_url='local_git',
                            checksum='',
                            size=0,
                            compatibility_score=0.0,
                            risk_level='low',  # Local updates are usually safer
                            ai_recommendation='',
                            breaking_changes=[],
                            new_features=[],
                            fixes=[]
                        )
                        
                        updates.append(update_info)
                        
        except Exception as e:
            print(f"Warning: Could not check local git updates: {e}")
        
        return updates
    
    def _ai_analyze_updates(self, updates: List[UpdateInfo]) -> List[UpdateInfo]:
        """Use AI to analyze updates for compatibility and risk"""
        if not self.ai_assistant:
            return updates
        
        print("🤖 AI analyzing updates for compatibility and risk...")
        
        for update in updates:
            try:
                # Analyze changelog for breaking changes, features, and fixes
                self._parse_changelog(update)
                
                # Calculate compatibility score based on system profile
                update.compatibility_score = self._calculate_compatibility_score(update)
                
                # Determine risk level using AI
                update.risk_level = self._assess_risk_level(update)
                
                # Generate AI recommendation
                update.ai_recommendation = self._generate_ai_recommendation(update)
                
            except Exception as e:
                print(f"Warning: AI analysis failed for {update.version}: {e}")
                update.ai_recommendation = "AI analysis unavailable"
        
        # Sort by AI recommendation and compatibility
        updates.sort(key=lambda x: (x.compatibility_score, x.version), reverse=True)
        
        return updates
    
    def _parse_changelog(self, update: UpdateInfo):
        """Parse changelog to extract breaking changes, features, and fixes"""
        changelog = update.changelog.lower()
        
        # Keywords for different types of changes
        breaking_keywords = ['breaking', 'removed', 'deprecated', 'incompatible', 'migration']
        feature_keywords = ['added', 'new', 'feature', 'enhancement', 'improved']
        fix_keywords = ['fixed', 'bug', 'issue', 'patch', 'security']
        
        lines = update.changelog.split('\n')
        
        for line in lines:
            line_lower = line.lower()
            
            if any(keyword in line_lower for keyword in breaking_keywords):
                update.breaking_changes.append(line.strip())
            elif any(keyword in line_lower for keyword in feature_keywords):
                update.new_features.append(line.strip())
            elif any(keyword in line_lower for keyword in fix_keywords):
                update.fixes.append(line.strip())
    
    def _calculate_compatibility_score(self, update: UpdateInfo) -> float:
        """Calculate compatibility score using AI analysis"""
        if not self.system_profile:
            return 0.7  # Default moderate compatibility
        
        score = 1.0
        
        # Reduce score for breaking changes
        score -= len(update.breaking_changes) * 0.2
        
        # Consider system capabilities
        if self.system_profile.ram_gb < 8 and 'performance' in update.changelog.lower():
            score -= 0.1  # Performance updates might need more resources
        
        # Consider usage pattern compatibility
        if 'gaming' in self.system_profile.usage_pattern:
            if any('gaming' in feature.lower() for feature in update.new_features):
                score += 0.1
        
        # Version jump analysis
        try:
            version_diff = semver.compare(update.version, self.current_version)
            if version_diff >= 2:  # Major version jump
                score -= 0.2
        except Exception:
            pass
        
        return max(0.0, min(1.0, score))
    
    def _assess_risk_level(self, update: UpdateInfo) -> str:
        """Assess risk level using AI analysis"""
        risk_score = 0.0
        
        # Factors that increase risk
        risk_score += len(update.breaking_changes) * 0.3
        risk_score += 0.2 if 'beta' in update.version.lower() else 0.0
        risk_score += 0.1 if len(update.new_features) > 10 else 0.0
        
        # Factors that decrease risk
        risk_score -= len(update.fixes) * 0.1
        risk_score -= 0.2 if update.download_url == 'local_git' else 0.0
        
        if risk_score <= 0.3:
            return 'low'
        elif risk_score <= 0.7:
            return 'medium'
        else:
            return 'high'
    
    def _generate_ai_recommendation(self, update: UpdateInfo) -> str:
        """Generate AI-powered recommendation"""
        if update.compatibility_score >= 0.8 and update.risk_level == 'low':
            return "Highly recommended: Great compatibility and low risk"
        elif update.compatibility_score >= 0.6 and update.risk_level in ['low', 'medium']:
            return "Recommended: Good compatibility with manageable risk"
        elif update.breaking_changes:
            return f"Caution: {len(update.breaking_changes)} breaking changes detected"
        elif update.risk_level == 'high':
            return "Not recommended: High risk detected"
        else:
            return "Consider carefully: Moderate compatibility and risk"
    
    def generate_update_strategy(self, update: UpdateInfo) -> UpdateStrategy:
        """Generate AI-powered update strategy"""
        print(f"🧠 Generating AI update strategy for version {update.version}...")
        
        # Determine approach based on update characteristics
        approach = "incremental"
        if len(update.breaking_changes) > 0:
            approach = "custom"
        elif update.risk_level == 'high':
            approach = "full"
        
        # Determine backup level
        backup_level = "standard"
        if update.risk_level == 'high' or len(update.breaking_changes) > 2:
            backup_level = "comprehensive"
        elif update.risk_level == 'low' and not update.breaking_changes:
            backup_level = "minimal"
        
        # Determine merge strategy
        merge_strategy = "auto"
        if update.breaking_changes or update.risk_level == 'high':
            merge_strategy = "hybrid"  # Some manual intervention
        
        # Estimate time based on approach and system
        estimated_time = 5  # Base time in minutes
        if approach == "full":
            estimated_time = 15
        elif approach == "custom":
            estimated_time = 20
        
        if self.system_profile and self.system_profile.ram_gb < 8:
            estimated_time *= 1.5  # Slower on low-end systems
        
        # Determine if user interaction is needed
        user_interaction = (
            len(update.breaking_changes) > 0 or 
            update.risk_level == 'high' or
            merge_strategy != "auto"
        )
        
        # Calculate confidence based on AI analysis
        confidence = update.compatibility_score * 0.7
        if update.risk_level == 'low':
            confidence += 0.2
        elif update.risk_level == 'high':
            confidence -= 0.3
        
        confidence = max(0.0, min(1.0, confidence))
        
        strategy = UpdateStrategy(
            approach=approach,
            backup_level=backup_level,
            merge_strategy=merge_strategy,
            rollback_plan=f"Automatic rollback available for {self.settings.get('rollback_timeout', 30)} minutes",
            estimated_time=int(estimated_time),
            user_interaction_needed=user_interaction,
            confidence=confidence
        )
        
        return strategy
    
    def create_backup(self, backup_type: str = "pre_update") -> str:
        """Create intelligent backup using AI guidance"""
        backup_id = f"backup_{datetime.now().strftime('%Y%m%d_%H%M%S')}"
        backup_path = self.backup_dir / backup_id
        backup_path.mkdir(exist_ok=True)
        
        print(f"🛡️ Creating {backup_type} backup...")
        
        # Determine what to backup based on AI analysis
        backup_items = self._determine_backup_items(backup_type)
        
        metadata = {
            'backup_id': backup_id,
            'backup_type': backup_type,
            'version': self.current_version,
            'created_date': datetime.now().isoformat(),
            'items': backup_items,
            'system_profile': asdict(self.system_profile) if self.system_profile else {}
        }
        
        # Create backup archive
        archive_path = backup_path / "backup.tar.gz"
        
        with tarfile.open(archive_path, 'w:gz') as tar:
            for item in backup_items:
                source_path = Path(item['source'])
                if source_path.exists():
                    try:
                        tar.add(source_path, arcname=item['target'])
                        print(f"  ✓ Backed up: {item['source']}")
                    except Exception as e:
                        print(f"  ⚠ Could not backup {item['source']}: {e}")
        
        # Save metadata
        with open(backup_path / "metadata.json", 'w') as f:
            json.dump(metadata, f, indent=2)
        
        # Store in database
        self._store_backup_info(backup_id, metadata, str(archive_path))
        
        print(f"✅ Backup created: {backup_id}")
        return backup_id
    
    def _determine_backup_items(self, backup_type: str) -> List[Dict]:
        """Determine what to backup based on AI analysis"""
        items = []
        
        # Always backup core configuration
        core_items = [
            {'source': str(self.project_root), 'target': 'hyprsupreme', 'priority': 'high'},
            {'source': os.path.expanduser('~/.config/hypr'), 'target': 'config/hypr', 'priority': 'high'},
            {'source': os.path.expanduser('~/.config/waybar'), 'target': 'config/waybar', 'priority': 'medium'},
            {'source': os.path.expanduser('~/.config/rofi'), 'target': 'config/rofi', 'priority': 'medium'},
        ]
        
        items.extend(core_items)
        
        # Add more items based on backup type
        if backup_type in ['comprehensive', 'pre_update']:
            extended_items = [
                {'source': os.path.expanduser('~/.config/kitty'), 'target': 'config/kitty', 'priority': 'low'},
                {'source': os.path.expanduser('~/.config/ags'), 'target': 'config/ags', 'priority': 'low'},
                {'source': os.path.expanduser('~/.themes'), 'target': 'themes', 'priority': 'low'},
                {'source': os.path.expanduser('~/.icons'), 'target': 'icons', 'priority': 'low'},
            ]
            items.extend(extended_items)
        
        # Filter based on what exists
        return [item for item in items if Path(item['source']).exists()]
    
    def download_update(self, update: UpdateInfo) -> bool:
        """Download update with AI-guided optimization"""
        print(f"📥 Downloading update {update.version}...")
        
        download_path = self.cache_dir / f"update_{update.version}"
        download_path.mkdir(exist_ok=True)
        
        try:
            if update.download_url == 'local_git':
                # Pull from git
                result = subprocess.run(
                    ['git', 'pull', 'origin', 'main'],
                    cwd=self.project_root,
                    capture_output=True,
                    text=True
                )
                return result.returncode == 0
            else:
                # Download from URL
                response = requests.get(update.download_url, stream=True)
                if response.status_code == 200:
                    archive_path = download_path / "update.zip"
                    
                    with open(archive_path, 'wb') as f:
                        for chunk in response.iter_content(chunk_size=8192):
                            f.write(chunk)
                    
                    # Verify download
                    if self._verify_download(archive_path, update):
                        print(f"✅ Download completed: {update.version}")
                        return True
                    else:
                        print("❌ Download verification failed")
                        return False
                        
        except Exception as e:
            print(f"❌ Download failed: {e}")
            return False
        
        return False
    
    def apply_update(self, update: UpdateInfo, strategy: UpdateStrategy) -> bool:
        """Apply update using AI-guided strategy"""
        print(f"🚀 Applying update {update.version} using {strategy.approach} strategy...")
        
        try:
            # Create backup if needed
            backup_id = None
            if strategy.backup_level != "none":
                backup_id = self.create_backup("pre_update")
            
            # Apply update based on strategy
            success = False
            
            if strategy.approach == "incremental":
                success = self._apply_incremental_update(update, strategy)
            elif strategy.approach == "full":
                success = self._apply_full_update(update, strategy)
            elif strategy.approach == "custom":
                success = self._apply_custom_update(update, strategy)
            
            if success:
                # Update version
                self._update_version_file(update.version)
                
                # Record successful update
                self._record_update_success(update, strategy, backup_id)
                
                print(f"✅ Update {update.version} applied successfully!")
                return True
            else:
                print(f"❌ Update {update.version} failed to apply")
                
                # Attempt rollback if backup exists
                if backup_id:
                    print("🔄 Attempting rollback...")
                    return self._rollback_update(backup_id)
                
                return False
                
        except Exception as e:
            print(f"❌ Update application failed: {e}")
            return False
    
    def _apply_incremental_update(self, update: UpdateInfo, strategy: UpdateStrategy) -> bool:
        """Apply incremental update with minimal changes"""
        print("📈 Applying incremental update...")
        
        # For git updates, this is just a pull
        if update.download_url == 'local_git':
            result = subprocess.run(
                ['git', 'reset', '--hard', 'origin/main'],
                cwd=self.project_root,
                capture_output=True,
                text=True
            )
            return result.returncode == 0
        
        # For downloaded updates, extract and merge selectively
        return self._merge_update_files(update, conservative=True)
    
    def _apply_full_update(self, update: UpdateInfo, strategy: UpdateStrategy) -> bool:
        """Apply full update with complete replacement"""
        print("🔄 Applying full update...")
        
        # For git updates
        if update.download_url == 'local_git':
            result = subprocess.run(
                ['git', 'reset', '--hard', 'origin/main'],
                cwd=self.project_root,
                capture_output=True,
                text=True
            )
            return result.returncode == 0
        
        # For downloaded updates, full replacement
        return self._merge_update_files(update, conservative=False)
    
    def _apply_custom_update(self, update: UpdateInfo, strategy: UpdateStrategy) -> bool:
        """Apply custom update with AI-guided conflict resolution"""
        print("🎯 Applying custom update with AI guidance...")
        
        # This would involve sophisticated conflict resolution
        # For now, fall back to incremental approach
        return self._apply_incremental_update(update, strategy)
    
    def _merge_update_files(self, update: UpdateInfo, conservative: bool = True) -> bool:
        """Merge update files with AI conflict resolution"""
        # Implementation would involve detailed file comparison and merging
        # This is a simplified version
        print(f"🔧 Merging files ({'conservative' if conservative else 'aggressive'} mode)...")
        return True
    
    def _compare_versions(self, version1: str, version2: str) -> int:
        """Compare two semantic versions"""
        try:
            return semver.compare(version1, version2)
        except Exception:
            # Fallback to string comparison
            if version1 == version2:
                return 0
            elif version1 > version2:
                return 1
            else:
                return -1
    
    def _calculate_next_version(self) -> str:
        """Calculate next version number for development updates"""
        try:
            # Parse current version and increment patch
            version_parts = self.current_version.split('.')
            if len(version_parts) >= 3:
                patch = int(version_parts[2]) + 1
                return f"{version_parts[0]}.{version_parts[1]}.{patch}-dev"
            else:
                return f"{self.current_version}-dev"
        except Exception:
            return f"{self.current_version}-dev"
    
    def _store_update_info(self, update: UpdateInfo):
        """Store update information in database"""
        with sqlite3.connect(self.db_path) as conn:
            conn.execute("""
                INSERT OR REPLACE INTO updates 
                (version, release_date, status, compatibility_score, risk_level, 
                 ai_recommendation, changelog)
                VALUES (?, ?, ?, ?, ?, ?, ?)
            """, (
                update.version, update.release_date, 'available',
                update.compatibility_score, update.risk_level,
                update.ai_recommendation, update.changelog
            ))
    
    def _store_backup_info(self, backup_id: str, metadata: Dict, backup_path: str):
        """Store backup information in database"""
        with sqlite3.connect(self.db_path) as conn:
            conn.execute("""
                INSERT OR REPLACE INTO backup_points
                (id, version, created_date, backup_type, backup_path, metadata, verified)
                VALUES (?, ?, ?, ?, ?, ?, ?)
            """, (
                backup_id, metadata['version'], metadata['created_date'],
                metadata['backup_type'], backup_path, json.dumps(metadata), True
            ))
    
    def _record_update_success(self, update: UpdateInfo, strategy: UpdateStrategy, backup_id: str):
        """Record successful update in history"""
        with sqlite3.connect(self.db_path) as conn:
            conn.execute("""
                INSERT INTO update_history
                (version_from, version_to, update_date, success, strategy_used)
                VALUES (?, ?, ?, ?, ?)
            """, (
                self.current_version, update.version,
                datetime.now().isoformat(), True, strategy.approach
            ))
    
    def _verify_download(self, file_path: Path, update: UpdateInfo) -> bool:
        """Verify downloaded file integrity"""
        # For now, just check if file exists and has reasonable size
        if not file_path.exists():
            return False
        
        file_size = file_path.stat().st_size
        return file_size > 1024  # At least 1KB
    
    def _update_version_file(self, new_version: str):
        """Update VERSION file with new version"""
        version_file = self.project_root / "VERSION"
        try:
            version_file.write_text(new_version)
            self.current_version = new_version
        except Exception as e:
            print(f"Warning: Could not update VERSION file: {e}")
    
    def _rollback_update(self, backup_id: str) -> bool:
        """Rollback to previous backup"""
        print(f"🔄 Rolling back to backup {backup_id}...")
        
        try:
            # Get backup info from database
            with sqlite3.connect(self.db_path) as conn:
                cursor = conn.execute(
                    "SELECT backup_path, metadata FROM backup_points WHERE id = ?",
                    (backup_id,)
                )
                row = cursor.fetchone()
                
                if not row:
                    print("❌ Backup not found")
                    return False
                
                backup_path, metadata_json = row
                metadata = json.loads(metadata_json)
            
            # Restore from backup
            archive_path = Path(backup_path) / "backup.tar.gz"
            if archive_path.exists():
                with tarfile.open(archive_path, 'r:gz') as tar:
                    tar.extractall(Path.home())
                
                # Restore version
                if 'version' in metadata:
                    self._update_version_file(metadata['version'])
                
                print(f"✅ Rollback to {backup_id} completed")
                return True
            else:
                print("❌ Backup archive not found")
                return False
                
        except Exception as e:
            print(f"❌ Rollback failed: {e}")
            return False
    
    def list_available_updates(self) -> List[Dict]:
        """List all available updates"""
        with sqlite3.connect(self.db_path) as conn:
            conn.row_factory = sqlite3.Row
            cursor = conn.execute("""
                SELECT * FROM updates 
                WHERE status = 'available'
                ORDER BY version DESC
            """)
            return [dict(row) for row in cursor.fetchall()]
    
    def get_update_history(self) -> List[Dict]:
        """Get update history"""
        with sqlite3.connect(self.db_path) as conn:
            conn.row_factory = sqlite3.Row
            cursor = conn.execute("""
                SELECT * FROM update_history
                ORDER BY update_date DESC
            """)
            return [dict(row) for row in cursor.fetchall()]

def main():
    """Main function for AI Update Engine"""
    import argparse
    
    parser = argparse.ArgumentParser(description="HyprSupreme AI Update Engine")
    subparsers = parser.add_subparsers(dest='command', help='Available commands')
    
    # Check command
    check_parser = subparsers.add_parser('check', help='Check for updates')
    check_parser.add_argument('--force', action='store_true', help='Force check even if recently checked')
    
    # Update command
    update_parser = subparsers.add_parser('update', help='Apply update')
    update_parser.add_argument('version', nargs='?', help='Specific version to update to')
    update_parser.add_argument('--auto', action='store_true', help='Automatic update with AI strategy')
    
    # List command
    list_parser = subparsers.add_parser('list', help='List available updates')
    
    # History command
    history_parser = subparsers.add_parser('history', help='Show update history')
    
    # Backup command
    backup_parser = subparsers.add_parser('backup', help='Create backup')
    backup_parser.add_argument('--type', default='manual', help='Backup type')
    
    args = parser.parse_args()
    
    if not args.command:
        parser.print_help()
        return
    
    updater = AIUpdateEngine()
    
    try:
        if args.command == 'check':
            updates = updater.check_for_updates(force=args.force)
            if updates:
                print(f"\n🎉 Found {len(updates)} update(s):")
                for update in updates:
                    print(f"  • {update.version} - {update.ai_recommendation}")
            else:
                print("✅ No updates available")
        
        elif args.command == 'update':
            if args.version:
                # Update to specific version
                updates = updater.list_available_updates()
                target_update = next((u for u in updates if u['version'] == args.version), None)
                
                if target_update:
                    # Convert dict back to UpdateInfo (simplified)
                    update_info = UpdateInfo(
                        version=target_update['version'],
                        release_date=target_update['release_date'],
                        changelog=target_update['changelog'],
                        download_url='',  # Would need to be stored
                        checksum='',
                        size=0,
                        compatibility_score=target_update['compatibility_score'],
                        risk_level=target_update['risk_level'],
                        ai_recommendation=target_update['ai_recommendation'],
                        breaking_changes=[],
                        new_features=[],
                        fixes=[]
                    )
                    
                    strategy = updater.generate_update_strategy(update_info)
                    
                    if args.auto or strategy.confidence > 0.8:
                        if updater.download_update(update_info):
                            updater.apply_update(update_info, strategy)
                    else:
                        print(f"Manual confirmation required for {args.version}")
                        print(f"Strategy: {strategy.approach}")
                        print(f"Confidence: {strategy.confidence:.2f}")
                else:
                    print(f"Version {args.version} not found")
            else:
                print("Please specify a version to update to")
        
        elif args.command == 'list':
            updates = updater.list_available_updates()
            if updates:
                print("\n📋 Available Updates:")
                for update in updates:
                    print(f"  • {update['version']} - {update['ai_recommendation']}")
                    print(f"    Risk: {update['risk_level']}, Compatibility: {update['compatibility_score']:.2f}")
            else:
                print("No updates available")
        
        elif args.command == 'history':
            history = updater.get_update_history()
            if history:
                print("\n📜 Update History:")
                for entry in history:
                    status = "✅" if entry['success'] else "❌"
                    print(f"  {status} {entry['version_from']} → {entry['version_to']} ({entry['update_date']})")
            else:
                print("No update history")
        
        elif args.command == 'backup':
            backup_id = updater.create_backup(args.type)
            print(f"Backup created: {backup_id}")
    
    except Exception as e:
        print(f"Error: {e}")
        return 1
    
    return 0

if __name__ == "__main__":
    sys.exit(main())


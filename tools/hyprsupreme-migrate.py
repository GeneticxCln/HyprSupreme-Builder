#!/usr/bin/env python3
"""
HyprSupreme Configuration Migration System
Advanced migration and update system with version management
"""

import os
import sys
import json
import sqlite3
import shutil
import hashlib
import subprocess
from pathlib import Path
from datetime import datetime
from typing import Dict, List, Optional, Tuple, Any
from dataclasses import dataclass, asdict
import semver
import difflib

@dataclass
class MigrationRule:
    """Configuration migration rule"""
    id: str
    name: str
    description: str
    from_version: str
    to_version: str
    component: str  # hyprland, waybar, rofi, etc.
    rule_type: str  # file_rename, config_update, setting_change, etc.
    conditions: List[str]
    actions: List[Dict[str, Any]]
    rollback_actions: List[Dict[str, Any]]
    priority: int = 0
    required: bool = True

@dataclass
class MigrationPlan:
    """Migration execution plan"""
    id: str
    name: str
    from_version: str
    to_version: str
    rules: List[MigrationRule]
    estimated_time: int  # seconds
    backup_required: bool
    risk_level: str  # low, medium, high
    changelog: List[str]

@dataclass
class ConfigBackup:
    """Configuration backup metadata"""
    id: str
    name: str
    description: str
    created_at: str
    version: str
    components: List[str]
    file_count: int
    size: int
    path: str
    checksum: str

class HyprSupremeMigrator:
    """Advanced configuration migration system"""
    
    def __init__(self, config_dir: str = None):
        self.config_dir = Path(config_dir or os.path.expanduser("~/.config/hyprsupreme"))
        self.config_dir.mkdir(parents=True, exist_ok=True)
        
        self.db_path = self.config_dir / "migration.db"
        self.backups_dir = self.config_dir / "backups"
        self.migrations_dir = self.config_dir / "migrations"
        self.temp_dir = self.config_dir / "temp"
        
        for dir_path in [self.backups_dir, self.migrations_dir, self.temp_dir]:
            dir_path.mkdir(exist_ok=True)
            
        # Initialize database
        self.init_database()
        
        # Load migration rules
        self.load_migration_rules()
        
        # Current version tracking
        self.version_file = self.config_dir / "version.json"
        self.current_version = self.load_current_version()
        
    def init_database(self):
        """Initialize migration database"""
        with sqlite3.connect(self.db_path) as conn:
            conn.executescript("""
                CREATE TABLE IF NOT EXISTS migration_history (
                    id TEXT PRIMARY KEY,
                    name TEXT NOT NULL,
                    from_version TEXT,
                    to_version TEXT,
                    executed_at TEXT,
                    duration INTEGER,
                    success BOOLEAN,
                    backup_id TEXT,
                    error_message TEXT,
                    rollback_available BOOLEAN DEFAULT 1
                );
                
                CREATE TABLE IF NOT EXISTS backups (
                    id TEXT PRIMARY KEY,
                    name TEXT NOT NULL,
                    description TEXT,
                    created_at TEXT,
                    version TEXT,
                    components TEXT,  -- JSON array
                    file_count INTEGER,
                    size INTEGER,
                    path TEXT,
                    checksum TEXT,
                    auto_created BOOLEAN DEFAULT 0
                );
                
                CREATE TABLE IF NOT EXISTS version_history (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    version TEXT NOT NULL,
                    component TEXT,
                    updated_at TEXT,
                    migration_id TEXT,
                    FOREIGN KEY (migration_id) REFERENCES migration_history (id)
                );
                
                CREATE TABLE IF NOT EXISTS configuration_checksums (
                    file_path TEXT PRIMARY KEY,
                    checksum TEXT,
                    last_updated TEXT,
                    component TEXT
                );
                
                CREATE INDEX IF NOT EXISTS idx_migration_history_version ON migration_history(to_version);
                CREATE INDEX IF NOT EXISTS idx_backups_created ON backups(created_at);
                CREATE INDEX IF NOT EXISTS idx_version_history_component ON version_history(component);
            """)
            
    def load_migration_rules(self):
        """Load migration rules from files"""
        self.migration_rules = {}
        
        # Built-in migration rules
        self.migration_rules.update(self._get_builtin_rules())
        
        # Load custom rules from files
        rules_file = self.migrations_dir / "custom_rules.json"
        if rules_file.exists():
            try:
                with open(rules_file, 'r') as f:
                    custom_rules = json.load(f)
                    for rule_data in custom_rules:
                        rule = MigrationRule(**rule_data)
                        self.migration_rules[rule.id] = rule
            except Exception as e:
                print(f"Warning: Failed to load custom migration rules: {e}")
                
    def _get_builtin_rules(self) -> Dict[str, MigrationRule]:
        """Get built-in migration rules"""
        rules = {}
        
        # Hyprland v0.40.0 -> v0.41.0 migration
        rules["hyprland_040_041"] = MigrationRule(
            id="hyprland_040_041",
            name="Hyprland 0.40.0 to 0.41.0",
            description="Update deprecated settings and new syntax",
            from_version="0.40.0",
            to_version="0.41.0",
            component="hyprland",
            rule_type="config_update",
            conditions=["file_exists:~/.config/hypr/hyprland.conf"],
            actions=[
                {
                    "type": "replace_text",
                    "file": "~/.config/hypr/hyprland.conf",
                    "replacements": [
                        {"old": "gaps_in", "new": "gaps:inner"},
                        {"old": "gaps_out", "new": "gaps:outer"},
                        {"old": "border_size", "new": "general:border_size"},
                        {"old": "col.active_border", "new": "general:col.active_border"},
                        {"old": "col.inactive_border", "new": "general:col.inactive_border"}
                    ]
                }
            ],
            rollback_actions=[
                {
                    "type": "restore_from_backup"
                }
            ]
        )
        
        # Waybar font configuration update
        rules["waybar_font_update"] = MigrationRule(
            id="waybar_font_update",
            name="Waybar Font Configuration Update",
            description="Update font specifications to new format",
            from_version="0.9.0",
            to_version="0.10.0",
            component="waybar",
            rule_type="config_update",
            conditions=["file_exists:~/.config/waybar/style.css"],
            actions=[
                {
                    "type": "replace_regex",
                    "file": "~/.config/waybar/style.css",
                    "patterns": [
                        {
                            "pattern": r'font-family:\s*"([^"]+)"\s*;',
                            "replacement": r'font-family: "\1", monospace;'
                        }
                    ]
                }
            ],
            rollback_actions=[
                {
                    "type": "restore_from_backup"
                }
            ]
        )
        
        # AGS v1 to v2 migration
        rules["ags_v1_v2"] = MigrationRule(
            id="ags_v1_v2",
            name="AGS v1 to v2 Migration",
            description="Migrate AGS configuration from v1 to v2 API",
            from_version="1.8.0",
            to_version="2.0.0",
            component="ags",
            rule_type="config_rewrite",
            conditions=["file_exists:~/.config/ags/config.js"],
            actions=[
                {
                    "type": "run_script",
                    "script": "ags_v1_v2_converter.py",
                    "args": ["~/.config/ags/config.js"]
                }
            ],
            rollback_actions=[
                {
                    "type": "restore_from_backup"
                }
            ],
            priority=10
        )
        
        return rules
        
    def load_current_version(self) -> Dict[str, str]:
        """Load current version information"""
        default_versions = {
            "hyprsupreme": "1.0.0",
            "hyprland": "0.40.0",
            "waybar": "0.9.0",
            "rofi": "1.7.0",
            "kitty": "0.31.0",
            "ags": "1.8.0"
        }
        
        try:
            if self.version_file.exists():
                with open(self.version_file, 'r') as f:
                    versions = json.load(f)
                    default_versions.update(versions)
        except Exception as e:
            print(f"Warning: Failed to load version file: {e}")
            
        return default_versions
        
    def save_current_version(self):
        """Save current version information"""
        try:
            with open(self.version_file, 'w') as f:
                json.dump(self.current_version, f, indent=2)
        except Exception as e:
            print(f"Error saving version file: {e}")
            
    def detect_installed_versions(self) -> Dict[str, str]:
        """Detect versions of installed components"""
        versions = {}
        
        # Detect Hyprland version
        try:
            result = subprocess.run(['hyprctl', 'version'], capture_output=True, text=True)
            if result.returncode == 0:
                # Parse Hyprland version from output
                for line in result.stdout.split('\n'):
                    if 'Hyprland' in line and 'v' in line:
                        version = line.split('v')[1].split()[0]
                        versions['hyprland'] = version
                        break
        except:
            pass
            
        # Detect Waybar version
        try:
            result = subprocess.run(['waybar', '--version'], capture_output=True, text=True)
            if result.returncode == 0:
                # Parse version from output
                version_line = result.stdout.strip()
                if version_line:
                    versions['waybar'] = version_line.split()[-1]
        except:
            pass
            
        # Detect other component versions
        component_commands = {
            'rofi': ['rofi', '-version'],
            'kitty': ['kitty', '--version'],
            'ags': ['ags', '--version']
        }
        
        for component, cmd in component_commands.items():
            try:
                result = subprocess.run(cmd, capture_output=True, text=True)
                if result.returncode == 0:
                    # Simple version extraction
                    output = result.stdout.strip()
                    # Extract version number (assumes format like "program version")
                    words = output.split()
                    for word in words:
                        if word.replace('.', '').replace('-', '').isdigit() or \
                           any(c.isdigit() for c in word):
                            versions[component] = word
                            break
            except:
                pass
                
        return versions
        
    def plan_migration(self, target_version: str, component: str = None) -> Optional[MigrationPlan]:
        """Plan migration to target version"""
        current_ver = self.current_version.get(component or 'hyprsupreme', '1.0.0')
        
        if semver.compare(current_ver, target_version) >= 0:
            return None  # Already at or above target version
            
        # Find applicable migration rules
        applicable_rules = []
        for rule in self.migration_rules.values():
            if component and rule.component != component:
                continue
                
            # Check if rule applies to this version range
            if (semver.compare(current_ver, rule.from_version) >= 0 and
                semver.compare(rule.to_version, target_version) <= 0):
                
                # Check conditions
                if self._check_conditions(rule.conditions):
                    applicable_rules.append(rule)
                    
        # Sort rules by priority and version order
        applicable_rules.sort(key=lambda r: (r.priority, r.to_version))
        
        if not applicable_rules:
            return None
            
        # Create migration plan
        plan_id = hashlib.sha256(f"{current_ver}_{target_version}_{datetime.now().isoformat()}".encode()).hexdigest()[:16]
        
        plan = MigrationPlan(
            id=plan_id,
            name=f"Migration from {current_ver} to {target_version}",
            from_version=current_ver,
            to_version=target_version,
            rules=applicable_rules,
            estimated_time=len(applicable_rules) * 30,  # 30 seconds per rule
            backup_required=any(r.required for r in applicable_rules),
            risk_level=self._assess_risk_level(applicable_rules),
            changelog=self._generate_changelog(applicable_rules)
        )
        
        return plan
        
    def _check_conditions(self, conditions: List[str]) -> bool:
        """Check if migration conditions are met"""
        for condition in conditions:
            if condition.startswith("file_exists:"):
                file_path = Path(condition[12:]).expanduser()
                if not file_path.exists():
                    return False
            elif condition.startswith("version_gte:"):
                # Check version greater than or equal
                component, version = condition[12:].split(":")
                current = self.current_version.get(component, "0.0.0")
                if semver.compare(current, version) < 0:
                    return False
            # Add more condition types as needed
            
        return True
        
    def _assess_risk_level(self, rules: List[MigrationRule]) -> str:
        """Assess risk level of migration"""
        if any(r.rule_type == "config_rewrite" for r in rules):
            return "high"
        elif any(r.rule_type == "config_update" for r in rules):
            return "medium"
        else:
            return "low"
            
    def _generate_changelog(self, rules: List[MigrationRule]) -> List[str]:
        """Generate changelog for migration"""
        changelog = []
        for rule in rules:
            changelog.append(f"• {rule.name}: {rule.description}")
        return changelog
        
    def create_backup(self, name: str, description: str = "", components: List[str] = None) -> str:
        """Create configuration backup"""
        backup_id = hashlib.sha256(f"{name}_{datetime.now().isoformat()}".encode()).hexdigest()[:16]
        backup_path = self.backups_dir / f"backup_{backup_id}.tar.gz"
        
        # Default components to backup
        if components is None:
            components = ["hyprland", "waybar", "rofi", "kitty", "ags", "themes"]
            
        # Collect files to backup
        files_to_backup = []
        config_base = Path.home() / ".config"
        
        component_dirs = {
            "hyprland": "hypr",
            "waybar": "waybar",
            "rofi": "rofi", 
            "kitty": "kitty",
            "ags": "ags",
            "themes": ["gtk-3.0", "gtk-4.0"]
        }
        
        for component in components:
            if component in component_dirs:
                dirs = component_dirs[component]
                if isinstance(dirs, str):
                    dirs = [dirs]
                    
                for dir_name in dirs:
                    config_dir = config_base / dir_name
                    if config_dir.exists():
                        for file_path in config_dir.rglob("*"):
                            if file_path.is_file():
                                files_to_backup.append(file_path)
                                
        # Create backup archive
        import tarfile
        with tarfile.open(backup_path, 'w:gz') as tar:
            for file_path in files_to_backup:
                arcname = file_path.relative_to(Path.home())
                tar.add(file_path, arcname=arcname)
                
        # Calculate backup metadata
        file_count = len(files_to_backup)
        size = backup_path.stat().st_size
        checksum = self._calculate_checksum(backup_path)
        
        # Save backup metadata
        backup = ConfigBackup(
            id=backup_id,
            name=name,
            description=description,
            created_at=datetime.now().isoformat(),
            version=self.current_version.get('hyprsupreme', '1.0.0'),
            components=components,
            file_count=file_count,
            size=size,
            path=str(backup_path),
            checksum=checksum
        )
        
        self._save_backup_metadata(backup)
        
        print(f"Backup created: {backup_id}")
        print(f"  Files: {file_count}")
        print(f"  Size: {size / (1024*1024):.1f} MB")
        print(f"  Path: {backup_path}")
        
        return backup_id
        
    def execute_migration(self, plan: MigrationPlan, dry_run: bool = False) -> bool:
        """Execute migration plan"""
        if dry_run:
            print("DRY RUN - No changes will be made")
            
        start_time = datetime.now()
        backup_id = None
        
        try:
            # Create backup if required
            if plan.backup_required and not dry_run:
                backup_id = self.create_backup(
                    f"Pre-migration backup for {plan.name}",
                    f"Automatic backup before migrating from {plan.from_version} to {plan.to_version}",
                    auto_created=True
                )
                
            print(f"Executing migration: {plan.name}")
            print(f"Risk level: {plan.risk_level}")
            
            # Execute migration rules
            for i, rule in enumerate(plan.rules, 1):
                print(f"Step {i}/{len(plan.rules)}: {rule.name}")
                
                if not dry_run:
                    self._execute_rule(rule)
                else:
                    print(f"  Would execute: {rule.description}")
                    
            # Update version information
            if not dry_run:
                self.current_version['hyprsupreme'] = plan.to_version
                self.save_current_version()
                
            # Record migration
            duration = int((datetime.now() - start_time).total_seconds())
            
            if not dry_run:
                self._record_migration(plan, backup_id, duration, True)
                
            print(f"Migration completed successfully in {duration} seconds")
            return True
            
        except Exception as e:
            duration = int((datetime.now() - start_time).total_seconds())
            
            if not dry_run:
                self._record_migration(plan, backup_id, duration, False, str(e))
                
            print(f"Migration failed: {e}")
            
            # Offer rollback if backup was created
            if backup_id and not dry_run:
                print(f"Backup available for rollback: {backup_id}")
                
            return False
            
    def _execute_rule(self, rule: MigrationRule):
        """Execute a single migration rule"""
        for action in rule.actions:
            action_type = action["type"]
            
            if action_type == "replace_text":
                self._execute_replace_text(action)
            elif action_type == "replace_regex":
                self._execute_replace_regex(action)
            elif action_type == "run_script":
                self._execute_run_script(action)
            elif action_type == "move_file":
                self._execute_move_file(action)
            elif action_type == "delete_file":
                self._execute_delete_file(action)
            else:
                print(f"Warning: Unknown action type: {action_type}")
                
    def _execute_replace_text(self, action: Dict):
        """Execute text replacement action"""
        file_path = Path(action["file"]).expanduser()
        
        if not file_path.exists():
            print(f"Warning: File not found: {file_path}")
            return
            
        content = file_path.read_text()
        
        for replacement in action["replacements"]:
            old_text = replacement["old"]
            new_text = replacement["new"]
            content = content.replace(old_text, new_text)
            
        file_path.write_text(content)
        
    def _execute_replace_regex(self, action: Dict):
        """Execute regex replacement action"""
        import re
        
        file_path = Path(action["file"]).expanduser()
        
        if not file_path.exists():
            print(f"Warning: File not found: {file_path}")
            return
            
        content = file_path.read_text()
        
        for pattern_info in action["patterns"]:
            pattern = pattern_info["pattern"]
            replacement = pattern_info["replacement"]
            content = re.sub(pattern, replacement, content)
            
        file_path.write_text(content)
        
    def _execute_run_script(self, action: Dict):
        """Execute script action"""
        script_name = action["script"]
        args = action.get("args", [])
        
        # Look for script in migrations directory
        script_path = self.migrations_dir / script_name
        
        if not script_path.exists():
            raise FileNotFoundError(f"Migration script not found: {script_path}")
            
        # Execute script
        cmd = [sys.executable, str(script_path)] + args
        result = subprocess.run(cmd, capture_output=True, text=True)
        
        if result.returncode != 0:
            raise RuntimeError(f"Script failed: {result.stderr}")
            
    def _execute_move_file(self, action: Dict):
        """Execute file move action"""
        source = Path(action["source"]).expanduser()
        dest = Path(action["dest"]).expanduser()
        
        if source.exists():
            dest.parent.mkdir(parents=True, exist_ok=True)
            shutil.move(str(source), str(dest))
            
    def _execute_delete_file(self, action: Dict):
        """Execute file deletion action"""
        file_path = Path(action["file"]).expanduser()
        
        if file_path.exists():
            if file_path.is_file():
                file_path.unlink()
            elif file_path.is_dir():
                shutil.rmtree(file_path)
                
    def rollback_migration(self, migration_id: str) -> bool:
        """Rollback a migration using backup"""
        try:
            # Get migration info
            with sqlite3.connect(self.db_path) as conn:
                cursor = conn.execute(
                    "SELECT backup_id, from_version FROM migration_history WHERE id = ?",
                    (migration_id,)
                )
                row = cursor.fetchone()
                
                if not row:
                    raise ValueError(f"Migration {migration_id} not found")
                    
                backup_id, from_version = row
                
            if not backup_id:
                raise ValueError("No backup available for this migration")
                
            # Restore from backup
            self.restore_backup(backup_id)
            
            # Revert version
            self.current_version['hyprsupreme'] = from_version
            self.save_current_version()
            
            print(f"Migration {migration_id} rolled back successfully")
            return True
            
        except Exception as e:
            print(f"Rollback failed: {e}")
            return False
            
    def restore_backup(self, backup_id: str) -> bool:
        """Restore configuration from backup"""
        try:
            backup = self._get_backup_metadata(backup_id)
            if not backup:
                raise ValueError(f"Backup {backup_id} not found")
                
            backup_path = Path(backup['path'])
            if not backup_path.exists():
                raise FileNotFoundError(f"Backup file not found: {backup_path}")
                
            # Extract backup
            import tarfile
            with tarfile.open(backup_path, 'r:gz') as tar:
                tar.extractall(Path.home())
                
            print(f"Backup {backup_id} restored successfully")
            return True
            
        except Exception as e:
            print(f"Restore failed: {e}")
            return False
            
    def list_backups(self) -> List[Dict]:
        """List available backups"""
        with sqlite3.connect(self.db_path) as conn:
            conn.row_factory = sqlite3.Row
            cursor = conn.execute("SELECT * FROM backups ORDER BY created_at DESC")
            return [dict(row) for row in cursor.fetchall()]
            
    def list_migrations(self) -> List[Dict]:
        """List migration history"""
        with sqlite3.connect(self.db_path) as conn:
            conn.row_factory = sqlite3.Row
            cursor = conn.execute("SELECT * FROM migration_history ORDER BY executed_at DESC")
            return [dict(row) for row in cursor.fetchall()]
            
    def check_for_updates(self) -> List[MigrationPlan]:
        """Check for available updates/migrations"""
        plans = []
        
        # Check each component for available updates
        detected_versions = self.detect_installed_versions()
        
        for component, current_version in self.current_version.items():
            if component == 'hyprsupreme':
                continue
                
            # Check if newer version is available
            if component in detected_versions:
                installed_version = detected_versions[component]
                if semver.compare(installed_version, current_version) > 0:
                    plan = self.plan_migration(installed_version, component)
                    if plan:
                        plans.append(plan)
                        
        return plans
        
    def _calculate_checksum(self, file_path: Path) -> str:
        """Calculate SHA256 checksum of file"""
        sha256_hash = hashlib.sha256()
        with open(file_path, "rb") as f:
            for chunk in iter(lambda: f.read(4096), b""):
                sha256_hash.update(chunk)
        return sha256_hash.hexdigest()
        
    def _save_backup_metadata(self, backup: ConfigBackup):
        """Save backup metadata to database"""
        with sqlite3.connect(self.db_path) as conn:
            conn.execute("""
                INSERT INTO backups 
                (id, name, description, created_at, version, components, 
                 file_count, size, path, checksum)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            """, (
                backup.id, backup.name, backup.description, backup.created_at,
                backup.version, json.dumps(backup.components), backup.file_count,
                backup.size, backup.path, backup.checksum
            ))
            
    def _get_backup_metadata(self, backup_id: str) -> Optional[Dict]:
        """Get backup metadata from database"""
        with sqlite3.connect(self.db_path) as conn:
            conn.row_factory = sqlite3.Row
            cursor = conn.execute("SELECT * FROM backups WHERE id = ?", (backup_id,))
            row = cursor.fetchone()
            return dict(row) if row else None
            
    def _record_migration(self, plan: MigrationPlan, backup_id: str, duration: int, 
                         success: bool, error_message: str = None):
        """Record migration in history"""
        with sqlite3.connect(self.db_path) as conn:
            conn.execute("""
                INSERT INTO migration_history 
                (id, name, from_version, to_version, executed_at, duration, 
                 success, backup_id, error_message, rollback_available)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            """, (
                plan.id, plan.name, plan.from_version, plan.to_version,
                datetime.now().isoformat(), duration, success, backup_id,
                error_message, backup_id is not None
            ))

# CLI Interface
def main():
    """Command line interface for migration system"""
    import argparse
    
    parser = argparse.ArgumentParser(description="HyprSupreme Configuration Migration")
    subparsers = parser.add_subparsers(dest='command', help='Available commands')
    
    # Status command
    subparsers.add_parser('status', help='Show current version status')
    
    # Check command
    subparsers.add_parser('check', help='Check for available updates')
    
    # Plan command
    plan_parser = subparsers.add_parser('plan', help='Plan migration to version')
    plan_parser.add_argument('version', help='Target version')
    plan_parser.add_argument('-c', '--component', help='Specific component')
    
    # Migrate command
    migrate_parser = subparsers.add_parser('migrate', help='Execute migration')
    migrate_parser.add_argument('version', help='Target version')
    migrate_parser.add_argument('-c', '--component', help='Specific component')
    migrate_parser.add_argument('--dry-run', action='store_true', help='Dry run mode')
    
    # Backup commands
    backup_parser = subparsers.add_parser('backup', help='Backup management')
    backup_subparsers = backup_parser.add_subparsers(dest='backup_action')
    
    create_backup = backup_subparsers.add_parser('create', help='Create backup')
    create_backup.add_argument('name', help='Backup name')
    create_backup.add_argument('-d', '--description', default='', help='Description')
    create_backup.add_argument('-c', '--components', nargs='*', help='Components to backup')
    
    list_backups = backup_subparsers.add_parser('list', help='List backups')
    
    restore_backup = backup_subparsers.add_parser('restore', help='Restore backup')
    restore_backup.add_argument('backup_id', help='Backup ID')
    
    # Rollback command
    rollback_parser = subparsers.add_parser('rollback', help='Rollback migration')
    rollback_parser.add_argument('migration_id', help='Migration ID')
    
    # History command
    subparsers.add_parser('history', help='Show migration history')
    
    args = parser.parse_args()
    
    if not args.command:
        parser.print_help()
        return
        
    migrator = HyprSupremeMigrator()
    
    try:
        if args.command == 'status':
            print("Current Versions:")
            for component, version in migrator.current_version.items():
                print(f"  {component}: {version}")
                
            detected = migrator.detect_installed_versions()
            if detected:
                print("\nDetected Versions:")
                for component, version in detected.items():
                    print(f"  {component}: {version}")
                    
        elif args.command == 'check':
            plans = migrator.check_for_updates()
            if plans:
                print(f"Found {len(plans)} available updates:")
                for plan in plans:
                    print(f"  {plan.name}")
                    print(f"    From: {plan.from_version} -> To: {plan.to_version}")
                    print(f"    Risk: {plan.risk_level}")
                    print()
            else:
                print("No updates available")
                
        elif args.command == 'plan':
            plan = migrator.plan_migration(args.version, args.component)
            if plan:
                print(f"Migration Plan: {plan.name}")
                print(f"From: {plan.from_version} -> To: {plan.to_version}")
                print(f"Risk Level: {plan.risk_level}")
                print(f"Estimated Time: {plan.estimated_time} seconds")
                print(f"Backup Required: {plan.backup_required}")
                print("\nChanges:")
                for change in plan.changelog:
                    print(f"  {change}")
                print(f"\nSteps: {len(plan.rules)} migration rules")
            else:
                print("No migration needed or available")
                
        elif args.command == 'migrate':
            plan = migrator.plan_migration(args.version, args.component)
            if plan:
                if migrator.execute_migration(plan, args.dry_run):
                    print("Migration completed successfully!")
                else:
                    print("Migration failed!")
            else:
                print("No migration needed or available")
                
        elif args.command == 'backup':
            if args.backup_action == 'create':
                backup_id = migrator.create_backup(args.name, args.description, args.components)
                print(f"Backup created: {backup_id}")
                
            elif args.backup_action == 'list':
                backups = migrator.list_backups()
                print(f"Available backups ({len(backups)}):")
                for backup in backups:
                    size_mb = backup['size'] / (1024 * 1024)
                    print(f"  {backup['id']}: {backup['name']}")
                    print(f"    Created: {backup['created_at']}")
                    print(f"    Size: {size_mb:.1f} MB, Files: {backup['file_count']}")
                    print()
                    
            elif args.backup_action == 'restore':
                if migrator.restore_backup(args.backup_id):
                    print("Backup restored successfully!")
                else:
                    print("Restore failed!")
            else:
                backup_parser.print_help()
                
        elif args.command == 'rollback':
            if migrator.rollback_migration(args.migration_id):
                print("Migration rolled back successfully!")
            else:
                print("Rollback failed!")
                
        elif args.command == 'history':
            migrations = migrator.list_migrations()
            print(f"Migration history ({len(migrations)}):")
            for migration in migrations:
                status = "✓" if migration['success'] else "✗"
                print(f"  {status} {migration['name']}")
                print(f"    {migration['from_version']} -> {migration['to_version']}")
                print(f"    Executed: {migration['executed_at']}")
                if migration['rollback_available']:
                    print(f"    Rollback: Available (ID: {migration['id']})")
                print()
                
    except Exception as e:
        print(f"Error: {e}")
        return 1
        
    return 0

if __name__ == "__main__":
    sys.exit(main())


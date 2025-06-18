#!/usr/bin/env python3
"""
HyprSupreme Cloud Sync
Synchronize configurations across devices using cloud storage
"""

import os
import sys
import json
import hashlib
import sqlite3
import requests
import tarfile
import tempfile
import uuid
import time
import hmac
from pathlib import Path
from datetime import datetime, timedelta
from typing import Dict, List, Optional, Tuple, Any
from dataclasses import dataclass, asdict
# Optional cryptography imports - graceful fallback
try:
    from cryptography.fernet import Fernet
    from cryptography.hazmat.primitives import hashes, serialization
    from cryptography.hazmat.primitives.kdf.pbkdf2 import PBKDF2HMAC
    from cryptography.hazmat.primitives.asymmetric import rsa, padding
    from cryptography.hazmat.primitives.ciphers.aead import AESGCM
    import base64
    ENCRYPTION_AVAILABLE = True
except ImportError:
    print("Warning: cryptography module not found. Encryption features disabled.")
    print("Install with: pip install cryptography")
    ENCRYPTION_AVAILABLE = False
    
    # Mock classes for graceful degradation
    class MockAESGCM:
        def __init__(self, key): pass
        def encrypt(self, nonce, data, associated_data): return data
        def decrypt(self, nonce, data, associated_data): return data
    
    AESGCM = MockAESGCM

@dataclass
class ConfigProfile:
    """Configuration profile data structure"""
    id: str
    name: str
    description: str
    author: str
    version: str
    created_at: str
    updated_at: str
    tags: List[str]
    components: List[str]
    features: List[str]
    preset: str
    checksum: str
    size: int
    downloads: int = 0
    rating: float = 0.0
    public: bool = False

class HyprSupremeCloud:
    """Cloud sync manager for HyprSupreme configurations with advanced encryption"""
    
    def __init__(self, config_dir: str = None):
        self.config_dir = Path(config_dir or os.path.expanduser("~/.config/hyprsupreme"))
        self.config_dir.mkdir(parents=True, exist_ok=True)
        
        self.db_path = self.config_dir / "cloud.db"
        self.settings_path = self.config_dir / "cloud_settings.json"
        self.cache_dir = self.config_dir / "cache"
        self.encrypted_cache_dir = self.config_dir / "encrypted_cache"
        self.keys_dir = self.config_dir / "keys"
        
        # Create directories with secure permissions
        for directory in [self.cache_dir, self.encrypted_cache_dir, self.keys_dir]:
            directory.mkdir(exist_ok=True, mode=0o700)
        
        # Cloud endpoints (would be actual API endpoints)
        self.api_base = "https://api.hyprsupreme.com/v1"  # Placeholder
        
        # Initialize database
        self.init_database()
        
        # Load settings
        self.settings = self.load_settings()
        self.api_key = self.settings.get('api_key')
        
        # Device identification
        self.device_id = self.get_or_create_device_id()
        self.device_name = self.settings.get('device_name', self.get_default_device_name())
        
        # Encryption components
        self.master_key = self.get_or_create_master_key()
        self.device_keypair = self.get_or_create_device_keypair()
        if ENCRYPTION_AVAILABLE:
            self.aes_gcm = AESGCM(self.master_key)
        else:
            self.aes_gcm = MockAESGCM(self.master_key)
        
    def init_database(self):
        """Initialize local database for caching and tracking"""
        with sqlite3.connect(self.db_path) as conn:
            conn.executescript("""
                CREATE TABLE IF NOT EXISTS profiles (
                    id TEXT PRIMARY KEY,
                    name TEXT NOT NULL,
                    description TEXT,
                    author TEXT,
                    version TEXT,
                    created_at TEXT,
                    updated_at TEXT,
                    tags TEXT,  -- JSON array
                    components TEXT,  -- JSON array
                    features TEXT,  -- JSON array
                    preset TEXT,
                    checksum TEXT,
                    size INTEGER,
                    downloads INTEGER DEFAULT 0,
                    rating REAL DEFAULT 0.0,
                    public BOOLEAN DEFAULT 0,
                    local_path TEXT,
                    synced_at TEXT
                );
                
                CREATE TABLE IF NOT EXISTS sync_history (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    profile_id TEXT,
                    action TEXT,  -- upload, download, delete
                    timestamp TEXT,
                    success BOOLEAN,
                    error_message TEXT,
                    FOREIGN KEY (profile_id) REFERENCES profiles (id)
                );
                
                CREATE TABLE IF NOT EXISTS user_settings (
                    key TEXT PRIMARY KEY,
                    value TEXT
                );
                
                CREATE INDEX IF NOT EXISTS idx_profiles_author ON profiles(author);
                CREATE INDEX IF NOT EXISTS idx_profiles_tags ON profiles(tags);
                CREATE INDEX IF NOT EXISTS idx_sync_history_profile ON sync_history(profile_id);
            """)
            
    def load_settings(self) -> Dict:
        """Load cloud sync settings"""
        default_settings = {
            'auto_sync': False,
            'sync_interval': 3600,  # 1 hour
            'compression_level': 6,
            'encryption_enabled': True,
            'backup_before_sync': True,
            'api_endpoint': self.api_base,
            'username': '',
            'api_key': '',
            'last_sync': None
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
        """Save current settings to file"""
        try:
            with open(self.settings_path, 'w') as f:
                json.dump(self.settings, f, indent=2)
        except Exception as e:
            print(f"Error saving settings: {e}")
            
    def get_or_create_device_id(self) -> str:
        """Get or create unique device identifier"""
        device_file = self.config_dir / ".device_id"
        
        if device_file.exists():
            try:
                device_id = device_file.read_text().strip()
                if device_id:
                    return device_id
            except Exception:
                pass
        
        # Generate new device ID
        device_id = str(uuid.uuid4())
        try:
            device_file.write_text(device_id)
            device_file.chmod(0o600)
        except Exception as e:
            print(f"Warning: Could not save device ID: {e}")
        
        return device_id
    
    def get_default_device_name(self) -> str:
        """Generate default device name"""
        import socket
        import getpass
        hostname = socket.gethostname()
        username = getpass.getuser()
        return f"{username}@{hostname}"
    
    def get_or_create_master_key(self) -> bytes:
        """Get or create master encryption key using PBKDF2"""
        if not ENCRYPTION_AVAILABLE:
            # Return a simple key for testing
            return os.urandom(32)
            
        key_file = self.keys_dir / "master.key"
        salt_file = self.keys_dir / "master.salt"
        
        if key_file.exists() and salt_file.exists():
            try:
                with open(key_file, 'rb') as f:
                    encrypted_key = f.read()
                with open(salt_file, 'rb') as f:
                    salt = f.read()
                
                # In real implementation, would prompt for passphrase
                # For demo, using device-specific data as passphrase source
                passphrase = f"{self.device_id}:{os.getlogin()}".encode()
                
                kdf = PBKDF2HMAC(
                    algorithm=hashes.SHA256(),
                    length=32,
                    salt=salt,
                    iterations=100000,
                )
                key = kdf.derive(passphrase)
                
                # Decrypt and return master key
                f = Fernet(base64.urlsafe_b64encode(key))
                return f.decrypt(encrypted_key)
            except Exception as e:
                print(f"Warning: Could not load master key: {e}")
        
        # Generate new master key
        master_key = os.urandom(32)  # 256-bit key
        salt = os.urandom(16)
        
        try:
            # Derive encryption key from passphrase
            passphrase = f"{self.device_id}:{os.getlogin()}".encode()
            kdf = PBKDF2HMAC(
                algorithm=hashes.SHA256(),
                length=32,
                salt=salt,
                iterations=100000,
            )
            derived_key = kdf.derive(passphrase)
            
            # Encrypt master key
            f = Fernet(base64.urlsafe_b64encode(derived_key))
            encrypted_master_key = f.encrypt(master_key)
            
            # Save encrypted master key and salt
            key_file.write_bytes(encrypted_master_key)
            salt_file.write_bytes(salt)
            
            # Set secure permissions
            key_file.chmod(0o600)
            salt_file.chmod(0o600)
            
        except Exception as e:
            print(f"Warning: Could not save master key: {e}")
        
        return master_key
    
    def get_or_create_device_keypair(self) -> Tuple[bytes, bytes]:
        """Get or create RSA keypair for device authentication"""
        if not ENCRYPTION_AVAILABLE:
            # Return mock keypair for testing
            return b"mock_private_key", b"mock_public_key"
            
        private_key_file = self.keys_dir / "device_private.pem"
        public_key_file = self.keys_dir / "device_public.pem"
        
        if private_key_file.exists() and public_key_file.exists():
            try:
                private_key_bytes = private_key_file.read_bytes()
                public_key_bytes = public_key_file.read_bytes()
                return private_key_bytes, public_key_bytes
            except Exception:
                pass
        
        # Generate new keypair
        private_key = rsa.generate_private_key(
            public_exponent=65537,
            key_size=2048,
        )
        
        # Serialize keys
        private_key_bytes = private_key.private_bytes(
            encoding=serialization.Encoding.PEM,
            format=serialization.PrivateFormat.PKCS8,
            encryption_algorithm=serialization.NoEncryption()
        )
        
        public_key_bytes = private_key.public_key().public_bytes(
            encoding=serialization.Encoding.PEM,
            format=serialization.PublicFormat.SubjectPublicKeyInfo
        )
        
        try:
            private_key_file.write_bytes(private_key_bytes)
            public_key_file.write_bytes(public_key_bytes)
            
            private_key_file.chmod(0o600)
            public_key_file.chmod(0o644)
        except Exception as e:
            print(f"Warning: Could not save device keypair: {e}")
        
        return private_key_bytes, public_key_bytes
    
    def encrypt_data(self, data: bytes, additional_data: bytes = None) -> Dict[str, bytes]:
        """Encrypt data using AES-GCM with timestamp and nonce"""
        if not ENCRYPTION_AVAILABLE:
            # Return unencrypted data for testing
            timestamp = int(time.time()).to_bytes(8, 'big')
            return {
                'ciphertext': data,
                'nonce': os.urandom(12),
                'timestamp': timestamp,
                'aad': additional_data or b''
            }
            
        # Generate random nonce
        nonce = os.urandom(12)  # 96-bit nonce for GCM
        
        # Add timestamp to prevent replay attacks
        timestamp = int(time.time()).to_bytes(8, 'big')
        
        # Combine additional authenticated data
        aad = timestamp + (additional_data or b'')
        
        # Encrypt data
        ciphertext = self.aes_gcm.encrypt(nonce, data, aad)
        
        return {
            'ciphertext': ciphertext,
            'nonce': nonce,
            'timestamp': timestamp,
            'aad': additional_data or b''
        }
    
    def decrypt_data(self, encrypted_data: Dict[str, bytes], additional_data: bytes = None, max_age: int = 3600) -> bytes:
        """Decrypt data and verify timestamp"""
        if not ENCRYPTION_AVAILABLE:
            # Return unencrypted data for testing
            return encrypted_data['ciphertext']
            
        # Verify timestamp to prevent replay attacks
        timestamp = int.from_bytes(encrypted_data['timestamp'], 'big')
        current_time = int(time.time())
        
        if current_time - timestamp > max_age:
            raise ValueError("Encrypted data is too old")
        
        # Reconstruct AAD
        aad = encrypted_data['timestamp'] + (additional_data or encrypted_data['aad'])
        
        # Decrypt data
        plaintext = self.aes_gcm.decrypt(
            encrypted_data['nonce'], 
            encrypted_data['ciphertext'], 
            aad
        )
        
        return plaintext
    
    def sign_data(self, data: bytes) -> bytes:
        """Sign data using device private key"""
        if not ENCRYPTION_AVAILABLE:
            # Return mock signature for testing
            return hashlib.sha256(data).digest()
            
        private_key_bytes, _ = self.device_keypair
        
        private_key = serialization.load_pem_private_key(
            private_key_bytes,
            password=None
        )
        
        signature = private_key.sign(
            data,
            padding.PSS(
                mgf=padding.MGF1(hashes.SHA256()),
                salt_length=padding.PSS.MAX_LENGTH
            ),
            hashes.SHA256()
        )
        
        return signature
    
    def verify_signature(self, data: bytes, signature: bytes, public_key_bytes: bytes) -> bool:
        """Verify signature using public key"""
        if not ENCRYPTION_AVAILABLE:
            # Simple verification for testing
            expected_signature = hashlib.sha256(data).digest()
            return signature == expected_signature
            
        try:
            public_key = serialization.load_pem_public_key(public_key_bytes)
            
            public_key.verify(
                signature,
                data,
                padding.PSS(
                    mgf=padding.MGF1(hashes.SHA256()),
                    salt_length=padding.PSS.MAX_LENGTH
                ),
                hashes.SHA256()
            )
            return True
        except Exception:
            return False
    
    def get_or_create_encryption_key(self):
        """Get or create legacy encryption key for backward compatibility"""
        if not ENCRYPTION_AVAILABLE:
            # Return mock encryption for testing
            class MockFernet:
                def encrypt(self, data): return data
                def decrypt(self, data): return data
            return MockFernet()
            
        key_file = self.config_dir / ".encryption_key"
        
        if key_file.exists():
            try:
                with open(key_file, 'rb') as f:
                    key = f.read()
                return Fernet(key)
            except:
                pass
                
        # Create new encryption key
        key = Fernet.generate_key()
        try:
            key_file.write_bytes(key)
            key_file.chmod(0o600)  # Restrict permissions
        except Exception as e:
            print(f"Warning: Could not save encryption key: {e}")
            
        return Fernet(key)
        
    def authenticate(self, username: str, password: str) -> bool:
        """Authenticate with cloud service"""
        try:
            # This would make actual API call to authenticate
            # For now, simulate authentication
            auth_data = {
                'username': username,
                'password': password
            }
            
            # Simulated API response
            if username and password:
                self.settings['username'] = username
                self.settings['api_key'] = f"fake_api_key_{username}"
                self.api_key = self.settings['api_key']
                self.save_settings()
                return True
                
        except Exception as e:
            print(f"Authentication failed: {e}")
            
        return False
        
    def create_profile_from_current(self, name: str, description: str, tags: List[str] = None, public: bool = False) -> str:
        """Create a profile from current configuration"""
        if not name:
            raise ValueError("Profile name is required")
            
        # Generate profile ID
        profile_id = hashlib.sha256(f"{name}_{datetime.now().isoformat()}".encode()).hexdigest()[:16]
        
        # Collect current configuration
        config_files = self.collect_config_files()
        
        # Create archive
        archive_path = self.cache_dir / f"{profile_id}.tar.gz"
        self.create_config_archive(config_files, archive_path)
        
        # Calculate checksum
        checksum = self.calculate_checksum(archive_path)
        
        # Create profile
        profile = ConfigProfile(
            id=profile_id,
            name=name,
            description=description,
            author=self.settings.get('username', 'unknown'),
            version="1.0.0",
            created_at=datetime.now().isoformat(),
            updated_at=datetime.now().isoformat(),
            tags=tags or [],
            components=self.detect_components(),
            features=self.detect_features(),
            preset="custom",
            checksum=checksum,
            size=archive_path.stat().st_size,
            public=public
        )
        
        # Save to database
        self.save_profile_to_db(profile, str(archive_path))
        
        return profile_id
        
    def collect_config_files(self) -> List[Tuple[str, str]]:
        """Collect all configuration files"""
        config_base = Path.home() / ".config"
        files_to_sync = []
        
        # Configuration directories to sync
        sync_dirs = [
            "hypr",
            "waybar", 
            "rofi",
            "kitty",
            "ags",
            "gtk-3.0",
            "gtk-4.0"
        ]
        
        for dir_name in sync_dirs:
            config_dir = config_base / dir_name
            if config_dir.exists():
                for file_path in config_dir.rglob("*"):
                    if file_path.is_file():
                        # Store as (relative_path, absolute_path)
                        rel_path = file_path.relative_to(config_base)
                        files_to_sync.append((str(rel_path), str(file_path)))
                        
        # Also include some dotfiles
        dotfiles = [
            ".gtkrc-2.0",
            ".themes",
            ".icons"
        ]
        
        for dotfile in dotfiles:
            dotfile_path = Path.home() / dotfile
            if dotfile_path.exists():
                if dotfile_path.is_file():
                    files_to_sync.append((dotfile, str(dotfile_path)))
                elif dotfile_path.is_dir():
                    for file_path in dotfile_path.rglob("*"):
                        if file_path.is_file():
                            rel_path = file_path.relative_to(Path.home())
                            files_to_sync.append((str(rel_path), str(file_path)))
                            
        return files_to_sync
        
    def create_config_archive(self, files: List[Tuple[str, str]], output_path: Path):
        """Create compressed archive of configuration files"""
        with tarfile.open(output_path, 'w:gz', compresslevel=self.settings['compression_level']) as tar:
            for rel_path, abs_path in files:
                try:
                    tar.add(abs_path, arcname=rel_path)
                except Exception as e:
                    print(f"Warning: Could not add {abs_path}: {e}")
                    
    def calculate_checksum(self, file_path: Path) -> str:
        """Calculate SHA256 checksum of file"""
        sha256_hash = hashlib.sha256()
        with open(file_path, "rb") as f:
            for chunk in iter(lambda: f.read(4096), b""):
                sha256_hash.update(chunk)
        return sha256_hash.hexdigest()
        
    def detect_components(self) -> List[str]:
        """Detect installed components"""
        components = []
        config_base = Path.home() / ".config"
        
        component_map = {
            "hypr": "hyprland",
            "waybar": "waybar",
            "rofi": "rofi", 
            "kitty": "kitty",
            "ags": "ags"
        }
        
        for config_dir, component in component_map.items():
            if (config_base / config_dir).exists():
                components.append(component)
                
        return components
        
    def detect_features(self) -> List[str]:
        """Detect enabled features"""
        features = []
        
        # Check Hyprland config for features
        hypr_config = Path.home() / ".config/hypr/hyprland.conf"
        if hypr_config.exists():
            try:
                content = hypr_config.read_text()
                
                # Simple feature detection
                if "animation" in content:
                    features.append("animations")
                if "blur" in content:
                    features.append("blur")
                if "shadow" in content:
                    features.append("shadows")
                if "rounding" in content:
                    features.append("rounded")
                if "opacity" in content:
                    features.append("transparency")
                    
            except Exception as e:
                print(f"Warning: Could not read Hyprland config: {e}")
                
        return features
        
    def save_profile_to_db(self, profile: ConfigProfile, local_path: str):
        """Save profile to local database"""
        with sqlite3.connect(self.db_path) as conn:
            conn.execute("""
                INSERT OR REPLACE INTO profiles 
                (id, name, description, author, version, created_at, updated_at, 
                 tags, components, features, preset, checksum, size, downloads, 
                 rating, public, local_path, synced_at)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            """, (
                profile.id, profile.name, profile.description, profile.author,
                profile.version, profile.created_at, profile.updated_at,
                json.dumps(profile.tags), json.dumps(profile.components),
                json.dumps(profile.features), profile.preset, profile.checksum,
                profile.size, profile.downloads, profile.rating, profile.public,
                local_path, None
            ))
            
    def upload_profile(self, profile_id: str) -> bool:
        """Upload profile to cloud"""
        try:
            profile = self.get_profile_from_db(profile_id)
            if not profile:
                raise ValueError(f"Profile {profile_id} not found")
                
            # Get archive path
            archive_path = Path(profile['local_path'])
            if not archive_path.exists():
                raise FileNotFoundError(f"Archive not found: {archive_path}")
                
            # Simulate upload (would be actual API call)
            print(f"Uploading profile {profile['name']} ({archive_path.stat().st_size} bytes)...")
            
            # In real implementation, this would:
            # 1. Upload the archive to cloud storage
            # 2. Update profile metadata on server
            # 3. Handle versioning and conflicts
            
            # Update sync timestamp
            self.update_sync_timestamp(profile_id)
            
            # Log sync action
            self.log_sync_action(profile_id, "upload", True)
            
            print(f"Successfully uploaded profile: {profile['name']}")
            return True
            
        except Exception as e:
            print(f"Upload failed: {e}")
            self.log_sync_action(profile_id, "upload", False, str(e))
            return False
            
    def download_profile(self, profile_id: str, apply: bool = False) -> bool:
        """Download profile from cloud"""
        try:
            # Simulate download (would be actual API call)
            print(f"Downloading profile {profile_id}...")
            
            # In real implementation, this would:
            # 1. Download archive from cloud storage
            # 2. Verify checksum
            # 3. Extract to cache
            # 4. Optionally apply configuration
            
            if apply:
                return self.apply_profile(profile_id)
                
            self.log_sync_action(profile_id, "download", True)
            return True
            
        except Exception as e:
            print(f"Download failed: {e}")
            self.log_sync_action(profile_id, "download", False, str(e))
            return False
            
    def apply_profile(self, profile_id: str) -> bool:
        """Apply downloaded profile configuration"""
        try:
            profile = self.get_profile_from_db(profile_id)
            if not profile:
                raise ValueError(f"Profile {profile_id} not found")
                
            archive_path = Path(profile['local_path'])
            
            # Backup current configuration
            if self.settings['backup_before_sync']:
                backup_id = self.create_profile_from_current(
                    f"Auto-backup-{datetime.now().strftime('%Y%m%d-%H%M%S')}",
                    "Automatic backup before applying cloud profile"
                )
                print(f"Created backup: {backup_id}")
                
            # Extract archive
            config_base = Path.home() / ".config"
            
            with tarfile.open(archive_path, 'r:gz') as tar:
                # Extract safely
                for member in tar.getmembers():
                    if member.isfile():
                        # Ensure safe extraction path
                        safe_path = config_base / member.name
                        if config_base in safe_path.resolve().parents:
                            tar.extract(member, config_base)
                            
            print(f"Applied profile: {profile['name']}")
            return True
            
        except Exception as e:
            print(f"Apply failed: {e}")
            return False
            
    def get_profile_from_db(self, profile_id: str) -> Optional[Dict]:
        """Get profile from database"""
        with sqlite3.connect(self.db_path) as conn:
            conn.row_factory = sqlite3.Row
            cursor = conn.execute("SELECT * FROM profiles WHERE id = ?", (profile_id,))
            row = cursor.fetchone()
            return dict(row) if row else None
            
    def list_local_profiles(self) -> List[Dict]:
        """List all local profiles"""
        with sqlite3.connect(self.db_path) as conn:
            conn.row_factory = sqlite3.Row
            cursor = conn.execute("SELECT * FROM profiles ORDER BY updated_at DESC")
            return [dict(row) for row in cursor.fetchall()]
            
    def search_cloud_profiles(self, query: str = "", tags: List[str] = None, author: str = "") -> List[Dict]:
        """Search for profiles in cloud"""
        # Simulate cloud search (would be actual API call)
        print(f"Searching cloud profiles: query='{query}', tags={tags}, author='{author}'")
        
        # Return mock data for demonstration
        return [
            {
                'id': 'demo1',
                'name': 'Gaming Setup',
                'description': 'Optimized for gaming performance',
                'author': 'gamer123',
                'tags': ['gaming', 'performance'],
                'downloads': 1250,
                'rating': 4.8
            },
            {
                'id': 'demo2', 
                'name': 'Minimal Rice',
                'description': 'Clean and minimal configuration',
                'author': 'minimalist',
                'tags': ['minimal', 'clean'],
                'downloads': 890,
                'rating': 4.6
            }
        ]
        
    def update_sync_timestamp(self, profile_id: str):
        """Update last sync timestamp for profile"""
        with sqlite3.connect(self.db_path) as conn:
            conn.execute(
                "UPDATE profiles SET synced_at = ? WHERE id = ?",
                (datetime.now().isoformat(), profile_id)
            )
            
    def log_sync_action(self, profile_id: str, action: str, success: bool, error_message: str = None):
        """Log sync action to history"""
        with sqlite3.connect(self.db_path) as conn:
            conn.execute(
                "INSERT INTO sync_history (profile_id, action, timestamp, success, error_message) VALUES (?, ?, ?, ?, ?)",
                (profile_id, action, datetime.now().isoformat(), success, error_message)
            )
            
    def auto_sync(self):
        """Perform automatic sync if enabled"""
        if not self.settings['auto_sync']:
            return
            
        last_sync = self.settings.get('last_sync')
        if last_sync:
            last_sync_time = datetime.fromisoformat(last_sync)
            time_since_sync = (datetime.now() - last_sync_time).total_seconds()
            
            if time_since_sync < self.settings['sync_interval']:
                return  # Too soon to sync again
                
        # Sync all local profiles
        profiles = self.list_local_profiles()
        for profile in profiles:
            if profile['public']:
                self.upload_profile(profile['id'])
                
        self.settings['last_sync'] = datetime.now().isoformat()
        self.save_settings()
        
    def delete_profile(self, profile_id: str, delete_from_cloud: bool = False) -> bool:
        """Delete profile locally and optionally from cloud"""
        try:
            profile = self.get_profile_from_db(profile_id)
            if not profile:
                return False
                
            # Delete local archive
            if profile['local_path']:
                archive_path = Path(profile['local_path'])
                if archive_path.exists():
                    archive_path.unlink()
                    
            # Delete from cloud if requested
            if delete_from_cloud and profile['public']:
                # Would make API call to delete from cloud
                print(f"Deleting {profile['name']} from cloud...")
                self.log_sync_action(profile_id, "delete", True)
                
            # Delete from database
            with sqlite3.connect(self.db_path) as conn:
                conn.execute("DELETE FROM profiles WHERE id = ?", (profile_id,))
                conn.execute("DELETE FROM sync_history WHERE profile_id = ?", (profile_id,))
                
            return True
            
        except Exception as e:
            print(f"Delete failed: {e}")
            return False

# CLI Interface
def main():
    """Command line interface for cloud sync"""
    import argparse
    
    parser = argparse.ArgumentParser(description="HyprSupreme Cloud Sync")
    subparsers = parser.add_subparsers(dest='command', help='Available commands')
    
    # Auth command
    auth_parser = subparsers.add_parser('auth', help='Authenticate with cloud service')
    auth_parser.add_argument('username', help='Username')
    auth_parser.add_argument('password', help='Password')
    
    # Create profile command
    create_parser = subparsers.add_parser('create', help='Create profile from current config')
    create_parser.add_argument('name', help='Profile name')
    create_parser.add_argument('-d', '--description', default='', help='Profile description')
    create_parser.add_argument('-t', '--tags', nargs='*', default=[], help='Profile tags')
    create_parser.add_argument('--public', action='store_true', help='Make profile public')
    
    # Upload command
    upload_parser = subparsers.add_parser('upload', help='Upload profile to cloud')
    upload_parser.add_argument('profile_id', help='Profile ID to upload')
    
    # Download command
    download_parser = subparsers.add_parser('download', help='Download profile from cloud')
    download_parser.add_argument('profile_id', help='Profile ID to download')
    download_parser.add_argument('--apply', action='store_true', help='Apply after download')
    
    # List command
    list_parser = subparsers.add_parser('list', help='List profiles')
    list_parser.add_argument('--local', action='store_true', help='List local profiles only')
    
    # Search command
    search_parser = subparsers.add_parser('search', help='Search cloud profiles')
    search_parser.add_argument('-q', '--query', default='', help='Search query')
    search_parser.add_argument('-t', '--tags', nargs='*', default=[], help='Filter by tags')
    search_parser.add_argument('-a', '--author', default='', help='Filter by author')
    
    # Delete command
    delete_parser = subparsers.add_parser('delete', help='Delete profile')
    delete_parser.add_argument('profile_id', help='Profile ID to delete')
    delete_parser.add_argument('--cloud', action='store_true', help='Also delete from cloud')
    
    # Apply command
    apply_parser = subparsers.add_parser('apply', help='Apply profile configuration')
    apply_parser.add_argument('profile_id', help='Profile ID to apply')
    
    # Auto-sync command
    subparsers.add_parser('sync', help='Run auto-sync')
    
    args = parser.parse_args()
    
    if not args.command:
        parser.print_help()
        return
        
    cloud = HyprSupremeCloud()
    
    try:
        if args.command == 'auth':
            if cloud.authenticate(args.username, args.password):
                print("Authentication successful!")
            else:
                print("Authentication failed!")
                
        elif args.command == 'create':
            profile_id = cloud.create_profile_from_current(
                args.name, args.description, args.tags, args.public
            )
            print(f"Created profile: {profile_id}")
            
        elif args.command == 'upload':
            if cloud.upload_profile(args.profile_id):
                print("Upload successful!")
            else:
                print("Upload failed!")
                
        elif args.command == 'download':
            if cloud.download_profile(args.profile_id, args.apply):
                print("Download successful!")
            else:
                print("Download failed!")
                
        elif args.command == 'list':
            if args.local:
                profiles = cloud.list_local_profiles()
                print("Local Profiles:")
            else:
                profiles = cloud.search_cloud_profiles()
                print("Cloud Profiles:")
                
            for profile in profiles:
                print(f"  {profile['id']}: {profile['name']} - {profile.get('description', '')}")
                
        elif args.command == 'search':
            profiles = cloud.search_cloud_profiles(args.query, args.tags, args.author)
            print(f"Found {len(profiles)} profiles:")
            for profile in profiles:
                print(f"  {profile['id']}: {profile['name']} by {profile['author']}")
                print(f"    Downloads: {profile['downloads']}, Rating: {profile['rating']}")
                
        elif args.command == 'delete':
            if cloud.delete_profile(args.profile_id, args.cloud):
                print("Profile deleted!")
            else:
                print("Delete failed!")
                
        elif args.command == 'apply':
            if cloud.apply_profile(args.profile_id):
                print("Profile applied successfully!")
            else:
                print("Apply failed!")
                
        elif args.command == 'sync':
            cloud.auto_sync()
            print("Auto-sync completed!")
            
    except Exception as e:
        print(f"Error: {e}")
        return 1
        
    return 0

if __name__ == "__main__":
    sys.exit(main())


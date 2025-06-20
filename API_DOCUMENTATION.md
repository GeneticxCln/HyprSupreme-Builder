# HyprSupreme-Builder API Documentation

## Overview

HyprSupreme-Builder provides a RESTful API through its web interface for programmatic access to community features, theme management, system information, and installation management.

**Base URL**: `http://localhost:5000/api/v1`

**API Version**: v1.2 (v2.2.0 release)

## Authentication

Currently, the API does not require authentication when running locally. For production deployments, consider implementing proper authentication mechanisms.

**New in v2.2.0**: API key authentication option is available for enhanced security:

```bash
# Generate API key
./hyprsupreme --generate-api-key

# Use API key in requests
curl -H "X-API-Key: your_api_key" http://localhost:5000/api/v1/status
```

## Rate Limiting

- **Local Development**: No rate limiting
- **Production**: 100 requests per minute per IP (recommended)
- **API Key Authentication**: 300 requests per minute (new in v2.2.0)

---

## Endpoints

### 🏠 **Health & Status**

#### `GET /health`
Check API health status.

**Response:**
```json
{
    "status": "healthy",
    "version": "2.2.0",
    "timestamp": "2025-06-20T14:30:00Z",
    "uptime": "3d 2h 15m",
    "system_load": [0.15, 0.25, 0.30]
}
```

#### `GET /api/v1/status`
Get detailed system status.

**Response:**
```json
{
    "api_version": "v1.2",
    "app_version": "2.2.0",
    "database_status": "connected",
    "services": {
        "community_platform": "running",
        "theme_manager": "running",
        "network_manager": "running",
        "audio_service": "running",
        "installation_tracker": "running"
    },
    "statistics": {
        "total_themes": 142,
        "total_users": 583,
        "total_downloads": 28493,
        "active_installations": 357,
        "reported_hardware_configs": 218
    },
    "hardware": {
        "detected_gpu": "NVIDIA RTX 3070",
        "detected_cpu": "AMD Ryzen 7 5800X",
        "detected_displays": 2,
        "display_resolutions": ["2560x1440", "1920x1080"]
    },
    "system_health": {
        "status": "healthy",
        "performance_score": 98,
        "last_check": "2025-06-20T14:15:00Z"
    }
}
```

---

### 🛠️ **Installation Management (New in v2.2.0)**

#### `GET /api/v1/installation/status`
Get current installation status and progress.

**Response:**
```json
{
    "installation_id": "inst_2025062001",
    "status": "completed",
    "progress": 100,
    "current_step": "finalization",
    "steps_completed": 23,
    "total_steps": 23,
    "started_at": "2025-06-20T12:30:00Z",
    "completed_at": "2025-06-20T12:45:23Z",
    "duration_seconds": 923,
    "log_file": "/home/user/.cache/hyprsupreme/logs/installation_2025062001.log",
    "configuration": {
        "preset": "gaming",
        "theme": "catppuccin-mocha",
        "gpu": "nvidia"
    },
    "system_compatibility": {
        "status": "compatible",
        "score": 95,
        "warnings": 2,
        "critical_issues": 0
    }
}
```

#### `POST /api/v1/installation/verify`
Verify installation integrity.

**Request Body:**
```json
{
    "components": ["all"],
    "detail_level": "standard"
}
```

**Response:**
```json
{
    "verification_id": "ver_2025062002",
    "status": "passed",
    "timestamp": "2025-06-20T14:30:00Z",
    "components_verified": 42,
    "components_passed": 42,
    "components_failed": 0,
    "verification_details": {
        "core_services": "passed",
        "configurations": "passed",
        "permissions": "passed",
        "dependencies": "passed",
        "network_services": "passed",
        "audio_services": "passed"
    },
    "recommendations": []
}
```

#### `POST /api/v1/installation/repair`
Repair installation issues.

**Request Body:**
```json
{
    "components": ["audio", "network"],
    "backup": true,
    "verification_id": "ver_2025062002"
}
```

**Response:**
```json
{
    "repair_id": "rep_2025062003",
    "status": "completed",
    "components_repaired": ["audio", "network"],
    "backup_created": "backup_2025062003",
    "timestamp": "2025-06-20T14:35:00Z",
    "details": {
        "audio": {
            "status": "repaired",
            "actions": ["configuration_reset", "service_restart"]
        },
        "network": {
            "status": "repaired",
            "actions": ["driver_reload", "configuration_reset"]
        }
    }
}
```

#### `GET /api/v1/installation/logs`
Get installation logs.

**Query Parameters:**
- `id` (string): Installation ID (optional)
- `type` (string): Log type (installation, repair, verification)
- `limit` (integer): Number of log entries (default: 100)

**Response:**
```json
{
    "logs": [
        {
            "timestamp": "2025-06-20T12:30:00Z",
            "level": "INFO",
            "component": "installer",
            "message": "Installation started"
        },
        {
            "timestamp": "2025-06-20T12:30:05Z",
            "level": "INFO",
            "component": "dependency_validator",
            "message": "Validating system dependencies"
        }
    ],
    "total_entries": 256,
    "returned_entries": 100,
    "installation_id": "inst_2025062001"
}
```

### 🔄 **State Management (New in v2.2.0)**

#### `GET /api/v1/state`
Get current state information.

**Response:**
```json
{
    "installation_state": {
        "status": "completed",
        "version": "2.2.0",
        "installed_at": "2025-06-20T12:45:23Z",
        "last_updated": "2025-06-20T14:10:15Z",
        "modifications": 3
    },
    "configuration_state": {
        "status": "modified",
        "last_modified": "2025-06-20T13:30:45Z",
        "backup_available": true,
        "last_backup": "2025-06-20T13:25:00Z"
    },
    "runtime_state": {
        "services_running": 7,
        "services_stopped": 0,
        "uptime": "1h 45m",
        "memory_usage_mb": 342,
        "cpu_usage_percent": 2.5
    }
}
```

#### `POST /api/v1/state/save`
Save current state for later restoration.

**Request Body:**
```json
{
    "name": "pre-update-backup",
    "components": ["configuration", "themes", "keybindings"],
    "description": "Backup before system update"
}
```

**Response:**
```json
{
    "state_id": "state_2025062004",
    "timestamp": "2025-06-20T14:40:00Z",
    "name": "pre-update-backup",
    "components": ["configuration", "themes", "keybindings"],
    "size_bytes": 1458920,
    "expiration": "2025-07-20T14:40:00Z"
}
```

#### `POST /api/v1/state/restore`
Restore previously saved state.

**Request Body:**
```json
{
    "state_id": "state_2025062004",
    "components": ["all"],
    "backup_current": true
}
```

**Response:**
```json
{
    "restore_id": "restore_2025062005",
    "status": "completed",
    "timestamp": "2025-06-20T14:45:00Z",
    "components_restored": ["configuration", "themes", "keybindings"],
    "backup_created": "backup_2025062005",
    "details": {
        "configuration": {
            "status": "restored",
            "files": 24
        },
        "themes": {
            "status": "restored",
            "files": 8
        },
        "keybindings": {
            "status": "restored",
            "files": 3
        }
    }
}
```

### 🔍 **Hardware Detection (New in v2.2.0)**

#### `GET /api/v1/hardware`
Get hardware information.

**Response:**
```json
{
    "cpu": {
        "model": "AMD Ryzen 7 5800X",
        "cores": 8,
        "threads": 16,
        "frequency_mhz": 3800,
        "architecture": "x86_64"
    },
    "gpu": {
        "primary": {
            "model": "NVIDIA GeForce RTX 3070",
            "driver": "nvidia",
            "driver_version": "550.40",
            "vram_mb": 8192
        },
        "secondary": null
    },
    "memory": {
        "total_mb": 32768,
        "available_mb": 28512,
        "swap_total_mb": 8192
    },
    "displays": [
        {
            "name": "DP-1",
            "resolution": "2560x1440",
            "refresh_rate": 144,
            "primary": true,
            "scale_factor": 1.0
        },
        {
            "name": "HDMI-1",
            "resolution": "1920x1080",
            "refresh_rate": 60,
            "primary": false,
            "scale_factor": 1.0
        }
    ],
    "storage": {
        "devices": [
            {
                "name": "/dev/nvme0n1",
                "type": "nvme",
                "size_gb": 1000,
                "model": "Samsung SSD 980 PRO"
            },
            {
                "name": "/dev/sda",
                "type": "sata",
                "size_gb": 2000,
                "model": "WDC WD20EZBX-00A"
            }
        ]
    },
    "network": {
        "interfaces": [
            {
                "name": "enp5s0",
                "type": "ethernet",
                "speed_mbps": 1000,
                "mac_address": "xx:xx:xx:xx:xx:xx"
            },
            {
                "name": "wlan0",
                "type": "wifi",
                "chipset": "Intel AX200",
                "mac_address": "xx:xx:xx:xx:xx:xx"
            }
        ]
    },
    "audio": {
        "devices": [
            {
                "name": "HDA Intel PCH",
                "type": "internal",
                "default": false
            },
            {
                "name": "USB Audio Device",
                "type": "usb",
                "default": true
            }
        ]
    }
}
```

#### `POST /api/v1/hardware/optimize`
Request hardware-specific optimizations.

**Request Body:**
```json
{
    "target": "gpu",
    "profile": "gaming",
    "apply_immediately": true
}
```

**Response:**
```json
{
    "optimization_id": "opt_2025062006",
    "status": "completed",
    "target": "gpu",
    "profile": "gaming",
    "applied": true,
    "timestamp": "2025-06-20T14:50:00Z",
    "changes": [
        "Set power management to performance",
        "Enabled hardware acceleration",
        "Applied gaming-optimized driver settings"
    ],
    "estimated_performance_gain": "15-20%"
}
```

### 🎨 **Themes**

#### `GET /api/v1/themes`
Get list of themes with optional filtering.

**Query Parameters:**
- `category` (string): Filter by category (minimal, colorful, dark, etc.)
- `author` (string): Filter by author username
- `search` (string): Search in theme names and descriptions
- `sort` (string): Sort by `name`, `created_at`, `downloads`, `rating`
- `order` (string): `asc` or `desc` (default: `desc`)
- `limit` (integer): Number of results (default: 20, max: 100)
- `offset` (integer): Pagination offset (default: 0)
- `hardware_compatible` (boolean): Filter by hardware compatibility (new in v2.2.0)
- `gpu` (string): Filter by GPU compatibility (nvidia, amd, intel) (new in v2.2.0)
- `performance_profile` (string): Filter by performance profile (low, medium, high) (new in v2.2.0)

**Example Request:**
```bash
GET /api/v1/themes?category=minimal&sort=rating&limit=10
```

**Response:**
```json
{
    "themes": [
        {
            "id": "minimal-dark-v2",
            "name": "Minimal Dark v2",
            "description": "A clean, minimal dark theme",
            "author": "username",
            "category": "minimal",
            "tags": ["dark", "minimal", "clean"],
            "version": "2.1.0",
            "created_at": "2024-01-01T12:00:00Z",
            "updated_at": "2024-01-15T10:30:00Z",
            "downloads": 1250,
            "rating": 4.8,
            "rating_count": 45,
            "preview_url": "/api/v1/themes/minimal-dark-v2/preview",
            "download_url": "/api/v1/themes/minimal-dark-v2/download",
            "hardware_compatibility": {
                "minimum": {
                    "gpu": "any",
                    "cpu": "dual-core",
                    "memory_mb": 4096
                },
                "recommended": {
                    "gpu": "nvidia:1060,amd:580,intel:iris",
                    "cpu": "quad-core",
                    "memory_mb": 8192
                },
                "performance_impact": "low"
            },
            "verified": true,
            "verified_on_v2_2_0": true
        }
    ],
    "pagination": {
        "total": 142,
        "limit": 10,
        "offset": 0,
        "has_next": true
    }
}
```

#### `GET /api/v1/themes/{theme_id}`
Get detailed information about a specific theme.

**Response:**
```json
{
    "id": "minimal-dark-v2",
    "name": "Minimal Dark v2",
    "description": "A clean, minimal dark theme with subtle animations",
    "author": "username",
    "category": "minimal",
    "tags": ["dark", "minimal", "clean"],
    "version": "2.1.0",
    "created_at": "2024-01-01T12:00:00Z",
    "updated_at": "2024-01-15T10:30:00Z",
    "downloads": 1250,
    "rating": 4.8,
    "rating_count": 45,
    "file_size": "2.3MB",
    "components": ["hyprland", "waybar", "rofi", "kitty"],
    "requirements": {
        "hyprland": ">=0.35.0",
        "waybar": ">=0.9.0"
    },
    "screenshots": [
        "/api/v1/themes/minimal-dark-v2/screenshots/1",
        "/api/v1/themes/minimal-dark-v2/screenshots/2"
    ],
    "installation_notes": "Requires Nerd Fonts for proper icon display"
}
```

#### `POST /api/v1/themes`
Upload a new theme (requires authentication in production).

**Request Body:**
```json
{
    "name": "My Awesome Theme",
    "description": "A beautiful custom theme",
    "category": "colorful",
    "tags": ["custom", "bright", "animated"],
    "version": "1.0.0",
    "theme_data": "base64_encoded_theme_archive"
}
```

#### `GET /api/v1/themes/{theme_id}/download`
Download theme archive.

**Response:** Binary file download (ZIP/TAR.GZ)

#### `POST /api/v1/themes/{theme_id}/rate`
Rate a theme.

**Request Body:**
```json
{
    "rating": 5,
    "comment": "Excellent theme!"
}
```

---

### 👤 **Users**

#### `GET /api/v1/users/{username}`
Get user profile information.

**Response:**
```json
{
    "username": "themecreator",
    "display_name": "Theme Creator",
    "avatar_url": "/api/v1/users/themecreator/avatar",
    "joined_at": "2023-06-01T00:00:00Z",
    "theme_count": 12,
    "total_downloads": 5420,
    "reputation": 98,
    "badges": ["prolific_creator", "highly_rated"],
    "bio": "I love creating beautiful Hyprland themes"
}
```

#### `GET /api/v1/users/{username}/themes`
Get themes created by a specific user.

**Response:** Same format as `/api/v1/themes` but filtered by author.

---

### 🌐 **Network Management (New in v2.2.0)**

#### `GET /api/v1/network/status`
Get network status and available connections.

**Response:**
```json
{
    "status": "connected",
    "primary_interface": "wlan0",
    "connections": [
        {
            "interface": "wlan0",
            "type": "wifi",
            "status": "connected",
            "ssid": "MyHomeNetwork",
            "signal_strength": 85,
            "ip_address": "192.168.1.100",
            "speed_mbps": 300
        },
        {
            "interface": "enp5s0",
            "type": "ethernet",
            "status": "disconnected",
            "ip_address": null,
            "speed_mbps": null
        }
    ],
    "wifi_networks": [
        {
            "ssid": "MyHomeNetwork",
            "signal_strength": 85,
            "security": "WPA2",
            "connected": true
        },
        {
            "ssid": "Neighbor's WiFi",
            "signal_strength": 45,
            "security": "WPA2",
            "connected": false
        }
    ],
    "internet_connectivity": {
        "status": "connected",
        "ping_ms": 23,
        "dns_working": true
    }
}
```

#### `POST /api/v1/network/connect`
Connect to a network.

**Request Body:**
```json
{
    "interface": "wlan0",
    "ssid": "MyHomeNetwork",
    "password": "secure_password",
    "auto_connect": true
}
```

**Response:**
```json
{
    "status": "connected",
    "connection_id": "conn_2025062007",
    "interface": "wlan0",
    "ssid": "MyHomeNetwork",
    "ip_address": "192.168.1.100",
    "timestamp": "2025-06-20T14:55:00Z",
    "auto_connect": true
}
```

#### `POST /api/v1/network/scan`
Scan for available WiFi networks.

**Response:**
```json
{
    "scan_id": "scan_2025062008",
    "timestamp": "2025-06-20T14:56:00Z",
    "networks": [
        {
            "ssid": "MyHomeNetwork",
            "signal_strength": 85,
            "security": "WPA2",
            "channel": 6,
            "frequency": "2.4GHz",
            "mac_address": "xx:xx:xx:xx:xx:xx"
        },
        {
            "ssid": "Neighbor's WiFi",
            "signal_strength": 45,
            "security": "WPA2",
            "channel": 11,
            "frequency": "2.4GHz",
            "mac_address": "xx:xx:xx:xx:xx:xx"
        }
    ]
}
```

### 🔊 **Audio Management (New in v2.2.0)**

#### `GET /api/v1/audio/status`
Get audio status and available devices.

**Response:**
```json
{
    "status": "active",
    "backend": "pipewire",
    "devices": {
        "output": [
            {
                "id": "alsa_output.usb-0000_00_1f.3",
                "name": "USB Audio Device",
                "description": "Headphones",
                "default": true,
                "active": true,
                "volume": 85,
                "muted": false
            },
            {
                "id": "alsa_output.pci-0000_00_1f.3",
                "name": "HDA Intel PCH",
                "description": "Speakers",
                "default": false,
                "active": false,
                "volume": 75,
                "muted": false
            }
        ],
        "input": [
            {
                "id": "alsa_input.usb-046d_HD_Pro_Webcam",
                "name": "HD Pro Webcam",
                "description": "Microphone",
                "default": true,
                "active": true,
                "volume": 70,
                "muted": false
            }
        ]
    },
    "applications": [
        {
            "name": "Firefox",
            "pid": 12345,
            "volume": 100,
            "muted": false,
            "output_device": "alsa_output.usb-0000_00_1f.3"
        }
    ]
}
```

#### `POST /api/v1/audio/device/set-default`
Set default audio device.

**Request Body:**
```json
{
    "device_id": "alsa_output.pci-0000_00_1f.3",
    "type": "output"
}
```

**Response:**
```json
{
    "status": "success",
    "device_id": "alsa_output.pci-0000_00_1f.3",
    "type": "output",
    "name": "HDA Intel PCH",
    "previous_default": "alsa_output.usb-0000_00_1f.3",
    "timestamp": "2025-06-20T14:58:00Z"
}
```

#### `POST /api/v1/audio/volume`
Adjust volume for device or application.

**Request Body:**
```json
{
    "target": "device",
    "id": "alsa_output.usb-0000_00_1f.3",
    "volume": 75,
    "mute": false
}
```

**Response:**
```json
{
    "status": "success",
    "target": "device",
    "id": "alsa_output.usb-0000_00_1f.3",
    "name": "USB Audio Device",
    "previous_volume": 85,
    "current_volume": 75,
    "muted": false,
    "timestamp": "2025-06-20T14:59:00Z"
}
```

### 🛡️ **Error Handling (New in v2.2.0)**

#### `GET /api/v1/errors`
Get error history and details.

**Query Parameters:**
- `level` (string): Error level (warning, error, critical)
- `component` (string): Component name
- `limit` (integer): Number of results (default: 20)
- `since` (string): ISO timestamp to filter errors

**Response:**
```json
{
    "errors": [
        {
            "id": "err_2025062009",
            "timestamp": "2025-06-20T13:30:00Z",
            "level": "error",
            "code": "NETWORK_CONNECTION_FAILED",
            "component": "network_manager",
            "message": "Failed to connect to WiFi network",
            "details": {
                "interface": "wlan0",
                "ssid": "MyHomeNetwork",
                "reason": "authentication_failed"
            },
            "resolution": {
                "status": "resolved",
                "resolved_at": "2025-06-20T13:35:00Z",
                "resolution_method": "user_intervention"
            }
        }
    ],
    "total": 5,
    "statistics": {
        "error_rate_24h": 0.02,
        "most_common_component": "network_manager",
        "most_common_code": "NETWORK_CONNECTION_FAILED",
        "unresolved_count": 1
    }
}
```

#### `GET /api/v1/errors/{error_id}`
Get detailed information about a specific error.

**Response:**
```json
{
    "id": "err_2025062009",
    "timestamp": "2025-06-20T13:30:00Z",
    "level": "error",
    "code": "NETWORK_CONNECTION_FAILED",
    "component": "network_manager",
    "message": "Failed to connect to WiFi network",
    "details": {
        "interface": "wlan0",
        "ssid": "MyHomeNetwork",
        "reason": "authentication_failed",
        "attempt": 3,
        "driver": "iwlwifi",
        "driver_version": "5.15.0",
        "signal_strength": 75
    },
    "stack_trace": "...",
    "system_state": {
        "running_services": ["NetworkManager", "wpa_supplicant"],
        "related_log_files": ["/var/log/NetworkManager.log"]
    },
    "resolution": {
        "status": "resolved",
        "resolved_at": "2025-06-20T13:35:00Z",
        "resolution_method": "user_intervention",
        "resolution_details": "User provided correct password",
        "resolution_time_seconds": 300
    },
    "recommendations": [
        "Verify WiFi password is correct",
        "Check WiFi signal strength",
        "Ensure WiFi radio is enabled"
    ]
}
```

#### `POST /api/v1/errors/{error_id}/resolve`
Mark an error as resolved with resolution details.

**Request Body:**
```json
{
    "resolution_method": "config_change",
    "resolution_details": "Updated WiFi password",
    "prevent_recurrence": true
}
```

**Response:**
```json
{
    "id": "err_2025062009",
    "status": "resolved",
    "timestamp": "2025-06-20T15:00:00Z",
    "resolution_method": "config_change",
    "resolution_details": "Updated WiFi password",
    "prevent_recurrence": true
}
```

### 📊 **Statistics**

#### `GET /api/v1/stats`
Get global platform statistics.

**Response:**
```json
{
    "themes": {
        "total": 127,
        "by_category": {
            "minimal": 45,
            "colorful": 32,
            "dark": 28,
            "light": 15,
            "gaming": 7
        },
        "recent_uploads": 8
    },
    "users": {
        "total": 89,
        "active_this_month": 34
    },
    "downloads": {
        "total": 12450,
        "this_month": 892
    },
    "top_themes": [
        {
            "id": "catppuccin-supreme",
            "name": "Catppuccin Supreme",
            "downloads": 2100
        }
    ]
}
```

---

### 🔍 **Search**

#### `GET /api/v1/search`
Advanced search across themes and users.

**Query Parameters:**
- `q` (string, required): Search query
- `type` (string): `themes`, `users`, or `all` (default: `all`)
- `limit` (integer): Results limit (default: 20)

**Response:**
```json
{
    "query": "minimal dark",
    "results": {
        "themes": [
            {
                "id": "minimal-dark-v2",
                "name": "Minimal Dark v2",
                "relevance": 0.95
            }
        ],
        "users": [
            {
                "username": "darkthemer",
                "display_name": "Dark Theme Master",
                "relevance": 0.78
            }
        ]
    },
    "total_results": 15
}
```

---

## Error Handling

All API endpoints return consistent error responses:

```json
{
    "error": {
        "code": "THEME_NOT_FOUND",
        "message": "Theme with ID 'invalid-theme' not found",
        "details": {},
        "timestamp": "2024-01-01T12:00:00Z"
    }
}
```

### Common Error Codes

- `400` - Bad Request: Invalid parameters or request body
- `404` - Not Found: Resource doesn't exist
- `429` - Too Many Requests: Rate limit exceeded
- `500` - Internal Server Error: Server-side error

---

## SDK Examples

### Python
```python
import requests

# Get themes
response = requests.get('http://localhost:5000/api/v1/themes')
themes = response.json()['themes']

# Search themes
response = requests.get('http://localhost:5000/api/v1/themes', {
    'category': 'minimal',
    'search': 'dark'
})
```

### JavaScript
```javascript
// Fetch themes
const response = await fetch('http://localhost:5000/api/v1/themes');
const data = await response.json();

// Get theme details
const theme = await fetch(`http://localhost:5000/api/v1/themes/${themeId}`)
    .then(res => res.json());
```

### cURL
```bash
# Get all themes
curl "http://localhost:5000/api/v1/themes"

# Search themes
curl "http://localhost:5000/api/v1/themes?search=minimal&category=dark"

# Get theme details
curl "http://localhost:5000/api/v1/themes/minimal-dark-v2"
```

---

## WebSocket Events (Future)

Real-time updates for theme uploads, ratings, and community activity:

```javascript
const ws = new WebSocket('ws://localhost:5000/api/v1/ws');

ws.onmessage = (event) => {
    const data = JSON.parse(event.data);
    
    switch(data.type) {
        case 'theme_uploaded':
            console.log('New theme:', data.theme);
            break;
        case 'theme_rated':
            console.log('Theme rated:', data.rating);
            break;
    }
};
```

---

## Rate Limiting Headers

API responses include rate limiting information:

```
X-RateLimit-Limit: 100
X-RateLimit-Remaining: 95
X-RateLimit-Reset: 1640995200
```

---

## SDK Examples for v2.2.0

### Python

```python
import requests

class HyprSupremeAPI:
    def __init__(self, base_url="http://localhost:5000/api/v1", api_key=None):
        self.base_url = base_url
        self.headers = {}
        if api_key:
            self.headers["X-API-Key"] = api_key
    
    def get_installation_status(self):
        """Get current installation status"""
        return requests.get(f"{self.base_url}/installation/status", headers=self.headers).json()
    
    def verify_installation(self, components=["all"], detail_level="standard"):
        """Verify installation integrity"""
        data = {
            "components": components,
            "detail_level": detail_level
        }
        return requests.post(f"{self.base_url}/installation/verify", json=data, headers=self.headers).json()
    
    def get_hardware_info(self):
        """Get hardware information"""
        return requests.get(f"{self.base_url}/hardware", headers=self.headers).json()
    
    def optimize_hardware(self, target="gpu", profile="gaming", apply_immediately=True):
        """Apply hardware optimizations"""
        data = {
            "target": target,
            "profile": profile,
            "apply_immediately": apply_immediately
        }
        return requests.post(f"{self.base_url}/hardware/optimize", json=data, headers=self.headers).json()
    
    def get_network_status(self):
        """Get network status"""
        return requests.get(f"{self.base_url}/network/status", headers=self.headers).json()
    
    def connect_to_wifi(self, ssid, password, interface="wlan0", auto_connect=True):
        """Connect to WiFi network"""
        data = {
            "interface": interface,
            "ssid": ssid,
            "password": password,
            "auto_connect": auto_connect
        }
        return requests.post(f"{self.base_url}/network/connect", json=data, headers=self.headers).json()
    
    def get_audio_status(self):
        """Get audio status"""
        return requests.get(f"{self.base_url}/audio/status", headers=self.headers).json()
    
    def set_audio_volume(self, device_id, volume, mute=False):
        """Set volume for audio device"""
        data = {
            "target": "device",
            "id": device_id,
            "volume": volume,
            "mute": mute
        }
        return requests.post(f"{self.base_url}/audio/volume", json=data, headers=self.headers).json()

# Usage example
api = HyprSupremeAPI(api_key="your_api_key")
hardware = api.get_hardware_info()
print(f"GPU: {hardware['gpu']['primary']['model']}")

# Verify installation
verification = api.verify_installation()
if verification["status"] == "passed":
    print("Installation is healthy!")
else:
    print(f"Installation issues: {verification['components_failed']} components failed")
```

### JavaScript/TypeScript

```typescript
class HyprSupremeAPI {
    private baseUrl: string;
    private headers: Record<string, string>;

    constructor(baseUrl = 'http://localhost:5000/api/v1', apiKey?: string) {
        this.baseUrl = baseUrl;
        this.headers = {};
        if (apiKey) {
            this.headers['X-API-Key'] = apiKey;
        }
    }

    async getStatus() {
        const response = await fetch(`${this.baseUrl}/status`, {
            headers: this.headers
        });
        return await response.json();
    }

    async getInstallationStatus() {
        const response = await fetch(`${this.baseUrl}/installation/status`, {
            headers: this.headers
        });
        return await response.json();
    }

    async verifyInstallation(components = ['all'], detailLevel = 'standard') {
        const response = await fetch(`${this.baseUrl}/installation/verify`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                ...this.headers
            },
            body: JSON.stringify({
                components,
                detail_level: detailLevel
            })
        });
        return await response.json();
    }

    async getHardwareInfo() {
        const response = await fetch(`${this.baseUrl}/hardware`, {
            headers: this.headers
        });
        return await response.json();
    }

    async getNetworkStatus() {
        const response = await fetch(`${this.baseUrl}/network/status`, {
            headers: this.headers
        });
        return await response.json();
    }

    async connectToWifi(ssid: string, password: string, interface = 'wlan0') {
        const response = await fetch(`${this.baseUrl}/network/connect`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                ...this.headers
            },
            body: JSON.stringify({
                interface,
                ssid,
                password,
                auto_connect: true
            })
        });
        return await response.json();
    }
}

// Usage example
const api = new HyprSupremeAPI(undefined, 'your_api_key');

// Get hardware info
api.getHardwareInfo().then(hardware => {
    console.log(`CPU: ${hardware.cpu.model}, Cores: ${hardware.cpu.cores}`);
    console.log(`GPU: ${hardware.gpu.primary.model}`);
});

// Get network status
api.getNetworkStatus().then(network => {
    if (network.status === 'connected') {
        console.log(`Connected to ${network.connections[0].ssid} on ${network.primary_interface}`);
    } else {
        console.log('Not connected to any network');
    }
});
```

## Changelog

### v1.2.0 (v2.2.0 Release)
- Added installation management endpoints
- Added state management endpoints
- Added hardware detection endpoints
- Added network management endpoints
- Added audio management endpoints
- Added error handling endpoints
- Enhanced theme endpoints with hardware compatibility info
- Added optional API key authentication
- Added detailed error responses
- Improved status information

### v1.1.0
- WebSocket support
- Authentication system
- Advanced filtering

### v1.0.0
- Initial API release
- Basic theme and user endpoints
- Search functionality

---

For more information, see the [Community Commands Documentation](COMMUNITY_COMMANDS.md).


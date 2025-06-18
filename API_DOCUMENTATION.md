# HyprSupreme-Builder API Documentation

## Overview

HyprSupreme-Builder provides a RESTful API through its web interface for programmatic access to community features, theme management, and system information.

**Base URL**: `http://localhost:5000/api/v1`

## Authentication

Currently, the API does not require authentication when running locally. For production deployments, consider implementing proper authentication mechanisms.

## Rate Limiting

- **Local Development**: No rate limiting
- **Production**: 100 requests per minute per IP (recommended)

---

## Endpoints

### 🏠 **Health & Status**

#### `GET /health`
Check API health status.

**Response:**
```json
{
    "status": "healthy",
    "version": "2.0.0",
    "timestamp": "2024-01-01T12:00:00Z"
}
```

#### `GET /api/v1/status`
Get detailed system status.

**Response:**
```json
{
    "api_version": "v1",
    "app_version": "2.0.0",
    "database_status": "connected",
    "services": {
        "community_platform": "running",
        "theme_manager": "running"
    },
    "statistics": {
        "total_themes": 42,
        "total_users": 15,
        "total_downloads": 1337
    }
}
```

---

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
            "download_url": "/api/v1/themes/minimal-dark-v2/download"
        }
    ],
    "pagination": {
        "total": 42,
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

## Changelog

### v1.0.0
- Initial API release
- Basic theme and user endpoints
- Search functionality

### v1.1.0 (Planned)
- WebSocket support
- Authentication system
- Advanced filtering

---

For more information, see the [Community Commands Documentation](COMMUNITY_COMMANDS.md).


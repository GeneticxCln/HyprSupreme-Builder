use color_eyre::{eyre::Context, Result};
use serde::{Deserialize, Serialize};
use std::collections::HashMap;
use std::fs;
use std::path::{Path, PathBuf};
use std::sync::{Arc, RwLock};
use walkdir::WalkDir;

/// Represents a color scheme theme
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Theme {
    /// Name of the theme
    pub name: String,
    
    /// Author of the theme
    #[serde(default)]
    pub author: Option<String>,
    
    /// Description of the theme
    #[serde(default)]
    pub description: Option<String>,
    
    /// Theme version
    #[serde(default = "default_version")]
    pub version: String,
    
    /// Base theme to extend (if any)
    #[serde(default)]
    pub extends: Option<String>,
    
    /// Color scheme variables
    #[serde(default)]
    pub colors: HashMap<String, String>,
    
    /// Other variables for the theme
    #[serde(default)]
    pub variables: HashMap<String, String>,
    
    /// Metadata for the theme
    #[serde(default)]
    pub metadata: HashMap<String, String>,
}

fn default_version() -> String {
    "0.1.0".to_string()
}

impl Theme {
    /// Create a new theme with the given name
    pub fn new(name: &str) -> Self {
        Theme {
            name: name.to_string(),
            author: None,
            description: None,
            version: default_version(),
            extends: None,
            colors: HashMap::new(),
            variables: HashMap::new(),
            metadata: HashMap::new(),
        }
    }
    
    /// Load a theme from a file
    pub fn from_file<P: AsRef<Path>>(path: P) -> Result<Self> {
        let path = path.as_ref();
        let content = fs::read_to_string(path)
            .with_context(|| format!("Failed to read theme file: {}", path.display()))?;
        
        let extension = path.extension()
            .and_then(|ext| ext.to_str())
            .unwrap_or("");
        
        match extension {
            "toml" => {
                toml::from_str(&content)
                    .with_context(|| format!("Failed to parse TOML theme file: {}", path.display()))
            },
            "json" => {
                serde_json::from_str(&content)
                    .with_context(|| format!("Failed to parse JSON theme file: {}", path.display()))
            },
            _ => {
                Err(color_eyre::eyre::eyre!("Unsupported theme file format: {}", extension))
            }
        }
    }
    
    /// Save theme to a file
    pub fn save_to_file<P: AsRef<Path>>(&self, path: P, format: ThemeFormat) -> Result<()> {
        let path = path.as_ref();
        
        let content = match format {
            ThemeFormat::Toml => {
                toml::to_string_pretty(self)
                    .with_context(|| "Failed to serialize theme to TOML")?
            },
            ThemeFormat::Json => {
                serde_json::to_string_pretty(self)
                    .with_context(|| "Failed to serialize theme to JSON")?
            },
        };
        
        fs::write(path, content)
            .with_context(|| format!("Failed to write theme to file: {}", path.display()))?;
        
        Ok(())
    }
    
    /// Merge with another theme
    pub fn merge(&mut self, other: &Theme) {
        // Merge colors
        for (key, value) in &other.colors {
            self.colors.insert(key.clone(), value.clone());
        }
        
        // Merge variables
        for (key, value) in &other.variables {
            self.variables.insert(key.clone(), value.clone());
        }
        
        // Merge metadata
        for (key, value) in &other.metadata {
            self.metadata.insert(key.clone(), value.clone());
        }
    }
    
    /// Get a color value by name
    pub fn get_color(&self, name: &str) -> Option<&String> {
        self.colors.get(name)
    }
    
    /// Get a variable value by name
    pub fn get_variable(&self, name: &str) -> Option<&String> {
        self.variables.get(name)
    }
}

/// Format for theme files
#[derive(Debug, Clone, Copy)]
pub enum ThemeFormat {
    Toml,
    Json,
}

/// Theme loader for managing theme file loading
#[derive(Debug)]
pub struct ThemeLoader {
    /// Directories to search for themes
    theme_dirs: Vec<PathBuf>,
}

impl ThemeLoader {
    /// Create a new theme loader
    pub fn new() -> Self {
        ThemeLoader {
            theme_dirs: vec![],
        }
    }
    
    /// Add a directory to search for themes
    pub fn add_theme_dir<P: AsRef<Path>>(&mut self, path: P) -> &mut Self {
        self.theme_dirs.push(path.as_ref().to_path_buf());
        self
    }
    
    /// Load a theme by name
    pub fn load_theme(&self, name: &str) -> Result<Theme> {
        for dir in &self.theme_dirs {
            // Try different extensions
            for ext in &["toml", "json"] {
                let path = dir.join(format!("{}.{}", name, ext));
                if path.exists() {
                    return Theme::from_file(path);
                }
            }
            
            // Look in subdirectories
            let subdir_path = dir.join(name);
            if subdir_path.exists() && subdir_path.is_dir() {
                for ext in &["toml", "json"] {
                    let path = subdir_path.join(format!("theme.{}", ext));
                    if path.exists() {
                        return Theme::from_file(path);
                    }
                }
            }
        }
        
        Err(color_eyre::eyre::eyre!("Theme not found: {}", name))
    }
    
    /// List all available themes
    pub fn list_themes(&self) -> Vec<String> {
        let mut themes = Vec::new();
        
        for dir in &self.theme_dirs {
            if !dir.exists() || !dir.is_dir() {
                continue;
            }
            
            // Walk the directory
            for entry in WalkDir::new(dir).max_depth(2).into_iter().filter_map(|e| e.ok()) {
                let path = entry.path();
                if !path.is_file() {
                    continue;
                }
                
                if let Some(ext) = path.extension().and_then(|ext| ext.to_str()) {
                    if ext == "toml" || ext == "json" {
                        if let Some(name) = path.file_stem().and_then(|name| name.to_str()) {
                            if name != "theme" {
                                themes.push(name.to_string());
                            } else if let Some(parent_dir) = path.parent() {
                                if let Some(parent_name) = parent_dir.file_name().and_then(|name| name.to_str()) {
                                    if parent_name != dir.file_name().and_then(|name| name.to_str()).unwrap_or("") {
                                        themes.push(parent_name.to_string());
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        
        // Remove duplicates
        themes.sort();
        themes.dedup();
        
        themes
    }
}

impl Default for ThemeLoader {
    fn default() -> Self {
        let mut loader = ThemeLoader::new();
        
        // Add default theme directories
        if let Some(config_dir) = dirs::config_dir() {
            loader.add_theme_dir(config_dir.join("hyprsupreme/themes"));
        }
        
        if let Some(data_dir) = dirs::data_dir() {
            loader.add_theme_dir(data_dir.join("hyprsupreme/themes"));
        }
        
        // Add local themes directory
        loader.add_theme_dir("./themes");
        
        loader
    }
}

/// Manager for handling themes
#[derive(Debug)]
pub struct ThemeManager {
    /// Theme loader
    loader: ThemeLoader,
    
    /// Currently active theme
    active_theme: Arc<RwLock<Option<Theme>>>,
    
    /// Cache of loaded themes
    theme_cache: HashMap<String, Theme>,
}

impl ThemeManager {
    /// Create a new theme manager
    pub fn new() -> Self {
        ThemeManager {
            loader: ThemeLoader::default(),
            active_theme: Arc::new(RwLock::new(None)),
            theme_cache: HashMap::new(),
        }
    }
    
    /// Load and set the active theme
    pub fn set_theme(&mut self, name: &str) -> Result<()> {
        let theme = if let Some(cached) = self.theme_cache.get(name) {
            cached.clone()
        } else {
            let theme = self.loader.load_theme(name)?;
            self.theme_cache.insert(name.to_string(), theme.clone());
            theme
        };
        
        // Set the active theme
        let mut active = self.active_theme.write().unwrap();
        *active = Some(theme);
        
        Ok(())
    }
    
    /// Get the currently active theme
    pub fn get_active_theme(&self) -> Option<Theme> {
        let active = self.active_theme.read().unwrap();
        active.clone()
    }
    
    /// Get the theme loader
    pub fn loader(&self) -> &ThemeLoader {
        &self.loader
    }
    
    /// Get a mutable reference to the theme loader
    pub fn loader_mut(&mut self) -> &mut ThemeLoader {
        &mut self.loader
    }
    
    /// List all available themes
    pub fn list_themes(&self) -> Vec<String> {
        self.loader.list_themes()
    }
    
    /// Create a new theme
    pub fn create_theme(&mut self, name: &str) -> Theme {
        Theme::new(name)
    }
    
    /// Get a color from the active theme
    pub fn get_theme_color(&self, color_name: &str) -> Result<String> {
        let active = self.active_theme.read().unwrap();
        if let Some(theme) = active.as_ref() {
            theme.get_color(color_name)
                .cloned()
                .ok_or_else(|| color_eyre::eyre::eyre!("Color not found: {}", color_name))
        } else {
            Err(color_eyre::eyre::eyre!("No active theme"))
        }
    }
    
    /// Get a variable from the active theme
    pub fn get_theme_variable(&self, var_name: &str) -> Result<String> {
        let active = self.active_theme.read().unwrap();
        if let Some(theme) = active.as_ref() {
            theme.get_variable(var_name)
                .cloned()
                .ok_or_else(|| color_eyre::eyre::eyre!("Variable not found: {}", var_name))
        } else {
            Err(color_eyre::eyre::eyre!("No active theme"))
        }
    }
    
    /// Get list of all themes
    pub fn get_themes(&self) -> Vec<String> {
        self.list_themes()
    }
    
    /// Reload the current theme
    pub fn reload_theme(&mut self) -> Result<()> {
        let active = self.active_theme.read().unwrap();
        if let Some(theme) = active.as_ref() {
            let theme_name = theme.name.clone();
            drop(active); // Release the read lock
            
            // Clear cache and reload
            self.theme_cache.remove(&theme_name);
            self.set_theme(&theme_name)
        } else {
            Err(color_eyre::eyre::eyre!("No active theme to reload"))
        }
    }
    
    /// Save a theme to disk
    pub fn save_theme(&mut self, theme: &Theme, format: ThemeFormat) -> Result<PathBuf> {
        if let Some(config_dir) = dirs::config_dir() {
            let theme_dir = config_dir.join("hyprsupreme/themes");
            
            // Create directory if it doesn't exist
            if !theme_dir.exists() {
                fs::create_dir_all(&theme_dir)
                    .with_context(|| format!("Failed to create theme directory: {}", theme_dir.display()))?;
            }
            
            // Determine file extension
            let ext = match format {
                ThemeFormat::Toml => "toml",
                ThemeFormat::Json => "json",
            };
            
            let path = theme_dir.join(format!("{}.{}", theme.name, ext));
            theme.save_to_file(&path, format)?;
            
            // Add to cache
            self.theme_cache.insert(theme.name.clone(), theme.clone());
            
            Ok(path)
        } else {
            Err(color_eyre::eyre::eyre!("Could not determine config directory"))
        }
    }
}

impl Default for ThemeManager {
    fn default() -> Self {
        Self::new()
    }
}

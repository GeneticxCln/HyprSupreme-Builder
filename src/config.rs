use color_eyre::{eyre::{Context, ContextCompat}, Result};
use serde::{Deserialize, Serialize};
use std::collections::{HashMap, HashSet};
use std::path::{Path, PathBuf};
use std::fs;
use regex::Regex;
use lazy_static::lazy_static;

/// Main configuration structure for HyprSupreme-Builder
#[derive(Debug, Serialize, Deserialize)]
pub struct Config {
    /// Project metadata
    #[serde(default)]
    pub metadata: Metadata,
    
    /// Global variables
    #[serde(default)]
    pub variables: HashMap<String, String>,
    
    /// Profiles for different environments
    #[serde(default)]
    pub profiles: HashMap<String, Profile>,
    
    /// Default profile to use
    #[serde(default = "default_profile")]
    pub default_profile: String,
    
    /// Imports and includes
    #[serde(default)]
    pub imports: Vec<Import>,
    
    /// Hyprland specific configuration
    #[serde(default)]
    pub hyprland: HyprlandConfig,
}

fn default_profile() -> String {
    "default".to_string()
}

/// Metadata about the configuration project
#[derive(Debug, Serialize, Deserialize, Default)]
pub struct Metadata {
    /// Name of the configuration
    #[serde(default = "default_name")]
    pub name: String,
    
    /// Author of the configuration
    #[serde(default)]
    pub author: Option<String>,
    
    /// Version of the configuration
    #[serde(default = "default_version")]
    pub version: String,
    
    /// Description of the configuration
    #[serde(default)]
    pub description: Option<String>,
}

fn default_name() -> String {
    "hyprsupreme-config".to_string()
}

fn default_version() -> String {
    "0.1.0".to_string()
}

/// Profile for different environments (e.g., laptop, desktop, work)
#[derive(Debug, Serialize, Deserialize, Default)]
pub struct Profile {
    /// Profile-specific variables that override global ones
    #[serde(default)]
    pub variables: HashMap<String, String>,
    
    /// Profile-specific imports
    #[serde(default)]
    pub imports: Vec<Import>,
    
    /// Profile-specific Hyprland configuration
    #[serde(default)]
    pub hyprland: Option<HyprlandConfig>,
}

/// Import or include other configuration files
#[derive(Debug, Serialize, Deserialize)]
pub struct Import {
    /// Path to the file to import
    pub path: PathBuf,
    
    /// Whether to merge with existing configuration or replace
    #[serde(default)]
    pub merge: bool,
}

/// Hyprland-specific configuration
#[derive(Debug, Serialize, Deserialize, Default)]
pub struct HyprlandConfig {
    /// Path to main Hyprland configuration file
    pub config_path: Option<PathBuf>,
    
    /// Custom modules to include
    #[serde(default)]
    pub modules: Vec<HyprlandModule>,
    
    /// Custom theme settings
    #[serde(default)]
    pub theme: HashMap<String, String>,
    
    /// Keybindings
    #[serde(default)]
    pub keybindings: Vec<Keybinding>,
    
    /// Autostart applications
    #[serde(default)]
    pub autostart: Vec<Autostart>,
}

/// Hyprland module for organization
#[derive(Debug, Serialize, Deserialize)]
pub struct HyprlandModule {
    /// Name of the module
    pub name: String,
    
    /// Path to the module file
    pub path: PathBuf,
    
    /// Whether to enable this module
    #[serde(default = "default_true")]
    pub enabled: bool,
}

fn default_true() -> bool {
    true
}

/// Keybinding configuration
#[derive(Debug, Serialize, Deserialize)]
pub struct Keybinding {
    /// Modifier keys (e.g., SUPER, ALT)
    pub modifiers: Vec<String>,
    
    /// Key to bind
    pub key: String,
    
    /// Command to execute
    pub command: String,
    
    /// Description of what this binding does
    #[serde(default)]
    pub description: Option<String>,
}

/// Autostart application configuration
#[derive(Debug, Serialize, Deserialize)]
pub struct Autostart {
    /// Command to execute
    pub command: String,
    
    /// Whether to wait for the command to complete
    #[serde(default)]
    pub wait: bool,
    
    /// Workspace to start the application in
    #[serde(default)]
    pub workspace: Option<String>,
}

impl Config {
    /// Load configuration from a file
    pub fn from_file<P: AsRef<Path>>(path: P) -> Result<Self> {
        let path = path.as_ref();
        let content = fs::read_to_string(path)
            .with_context(|| format!("Failed to read config file: {}", path.display()))?;
        
        let mut config: Config = toml::from_str(&content)
            .with_context(|| format!("Failed to parse config file: {}", path.display()))?;
        
        // Process imports
        config.process_imports(path.parent().unwrap_or_else(|| Path::new(".")))?;
        
        Ok(config)
    }
    
    /// Process imports recursively
    fn process_imports(&mut self, base_dir: &Path) -> Result<()> {
        let imports = std::mem::take(&mut self.imports);
        let mut processed = HashSet::new();
        
        for import in imports {
            self.process_import(&import, base_dir, &mut processed)?;
        }
        
        Ok(())
    }
    
    /// Process a single import
    fn process_import(&mut self, import: &Import, base_dir: &Path, processed: &mut HashSet<PathBuf>) -> Result<()> {
        let full_path = if import.path.is_absolute() {
            import.path.clone()
        } else {
            base_dir.join(&import.path)
        };
        
        // Avoid circular imports
        if processed.contains(&full_path) {
            return Ok(());
        }
        
        processed.insert(full_path.clone());
        
        let content = fs::read_to_string(&full_path)
            .with_context(|| format!("Failed to read import file: {}", full_path.display()))?;
        
        let imported_config: Config = toml::from_str(&content)
            .with_context(|| format!("Failed to parse import file: {}", full_path.display()))?;
        
        // Merge or replace configuration
        self.merge_config(imported_config, import.merge);
        
        Ok(())
    }
    
    /// Merge another configuration into this one
    fn merge_config(&mut self, other: Config, merge: bool) {
        // Merge variables
        for (key, value) in other.variables {
            if merge && self.variables.contains_key(&key) {
                continue;
            }
            self.variables.insert(key, value);
        }
        
        // Merge profiles
        for (name, profile) in other.profiles {
            if merge && self.profiles.contains_key(&name) {
                // Merge profiles
                if let Some(existing) = self.profiles.get_mut(&name) {
                    for (key, value) in profile.variables {
                        if !existing.variables.contains_key(&key) {
                            existing.variables.insert(key, value);
                        }
                    }
                    
                    existing.imports.extend(profile.imports);
                    
                    if existing.hyprland.is_none() {
                        existing.hyprland = profile.hyprland;
                    }
                }
            } else {
                self.profiles.insert(name, profile);
            }
        }
        
        // Add imports
        self.imports.extend(other.imports);
        
        // Merge Hyprland config
        if merge {
            // Merge modules
            self.hyprland.modules.extend(other.hyprland.modules);
            
            // Merge theme
            for (key, value) in other.hyprland.theme {
                if !self.hyprland.theme.contains_key(&key) {
                    self.hyprland.theme.insert(key, value);
                }
            }
            
            // Merge keybindings and autostart
            self.hyprland.keybindings.extend(other.hyprland.keybindings);
            self.hyprland.autostart.extend(other.hyprland.autostart);
        } else if self.hyprland.config_path.is_none() {
            self.hyprland = other.hyprland;
        }
    }
    
    /// Get the active profile
    pub fn get_active_profile(&self, profile_name: Option<&str>) -> Result<&Profile> {
        let name = profile_name.unwrap_or(&self.default_profile);
        self.profiles.get(name)
            .with_context(|| format!("Profile '{}' not found", name))
    }
    
    /// Resolve variables in a string
    pub fn resolve_variables(&self, input: &str, profile_name: Option<&str>) -> String {
        lazy_static! {
            static ref VAR_REGEX: Regex = Regex::new(r"\$\{([a-zA-Z0-9_.-]+)\}").unwrap();
        }
        
        let mut result = input.to_string();
        let profile = match self.get_active_profile(profile_name) {
            Ok(p) => p,
            Err(_) => return result,
        };
        
        // Keep track of variables we've tried to resolve to avoid infinite recursion
        let mut visited = HashSet::new();
        
        while let Some(captures) = VAR_REGEX.captures(&result) {
            let full_match = captures.get(0).unwrap().as_str();
            let var_name = captures.get(1).unwrap().as_str();
            
            // Avoid infinite recursion
            if visited.contains(var_name) {
                break;
            }
            visited.insert(var_name.to_string());
            
            // Look up in profile variables first, then global variables
            let replacement = profile.variables.get(var_name)
                .or_else(|| self.variables.get(var_name))
                .map(|s| s.as_str())
                .unwrap_or("");
            
            result = result.replace(full_match, replacement);
        }
        
        result
    }
    
    /// Create a default configuration
    pub fn default_config() -> Self {
        let mut config = Config {
            metadata: Metadata {
                name: default_name(),
                author: Some("HyprSupreme User".to_string()),
                version: default_version(),
                description: Some("A HyprSupreme configuration".to_string()),
            },
            variables: HashMap::new(),
            profiles: HashMap::new(),
            default_profile: default_profile(),
            imports: Vec::new(),
            hyprland: HyprlandConfig::default(),
        };
        
        // Add some default variables
        config.variables.insert("color.background".to_string(), "#1a1b26".to_string());
        config.variables.insert("color.foreground".to_string(), "#c0caf5".to_string());
        config.variables.insert("color.accent".to_string(), "#7aa2f7".to_string());
        
        // Create default profile
        let mut default_profile = Profile::default();
        
        // Add some profile-specific variables
        default_profile.variables.insert("terminal".to_string(), "kitty".to_string());
        default_profile.variables.insert("browser".to_string(), "firefox".to_string());
        
        // Add default profile to profiles
        config.profiles.insert("default".to_string(), default_profile);
        
        // Add a sample laptop profile
        let mut laptop_profile = Profile::default();
        laptop_profile.variables.insert("scale".to_string(), "1.5".to_string());
        config.profiles.insert("laptop".to_string(), laptop_profile);
        
        config
    }
}

use color_eyre::{eyre::Context, Result};
use serde::{Deserialize, Serialize};
use std::collections::HashMap;
use std::fs;
use std::path::{Path, PathBuf};
use std::process::Command;
use semver::{Version, VersionReq};

/// Plugin manifest structure
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct PluginManifest {
    /// Name of the plugin
    pub name: String,
    
    /// Display name for the plugin
    #[serde(default)]
    pub display_name: Option<String>,
    
    /// Plugin version
    #[serde(default = "default_version")]
    pub version: String,
    
    /// Author of the plugin
    #[serde(default)]
    pub author: Option<String>,
    
    /// Description of the plugin
    #[serde(default)]
    pub description: Option<String>,
    
    /// License of the plugin
    #[serde(default)]
    pub license: Option<String>,
    
    /// Repository URL
    #[serde(default)]
    pub repository: Option<String>,
    
    /// Plugin dependencies
    #[serde(default)]
    pub dependencies: HashMap<String, String>,
    
    /// Plugin hooks
    #[serde(default)]
    pub hooks: Vec<PluginHook>,
    
    /// Plugin commands
    #[serde(default)]
    pub commands: Vec<PluginCommand>,
    
    /// Configuration schema
    #[serde(default)]
    pub config_schema: Option<serde_json::Value>,
}

fn default_version() -> String {
    "0.1.0".to_string()
}

/// Plugin hook definition
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct PluginHook {
    /// Hook name
    pub name: String,
    
    /// Script to execute
    pub script: String,
    
    /// Priority of the hook (lower is higher priority)
    #[serde(default)]
    pub priority: i32,
}

/// Plugin command definition
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct PluginCommand {
    /// Command name
    pub name: String,
    
    /// Command description
    #[serde(default)]
    pub description: Option<String>,
    
    /// Script to execute
    pub script: String,
}

impl PluginManifest {
    /// Create a new plugin manifest
    pub fn new(name: &str) -> Self {
        PluginManifest {
            name: name.to_string(),
            display_name: None,
            version: default_version(),
            author: None,
            description: None,
            license: None,
            repository: None,
            dependencies: HashMap::new(),
            hooks: Vec::new(),
            commands: Vec::new(),
            config_schema: None,
        }
    }
    
    /// Load a plugin manifest from a file
    pub fn from_file<P: AsRef<Path>>(path: P) -> Result<Self> {
        let path = path.as_ref();
        let content = fs::read_to_string(path)
            .with_context(|| format!("Failed to read plugin manifest: {}", path.display()))?;
        
        let extension = path.extension()
            .and_then(|ext| ext.to_str())
            .unwrap_or("");
        
        match extension {
            "toml" => {
                toml::from_str(&content)
                    .with_context(|| format!("Failed to parse TOML plugin manifest: {}", path.display()))
            },
            "json" => {
                serde_json::from_str(&content)
                    .with_context(|| format!("Failed to parse JSON plugin manifest: {}", path.display()))
            },
            _ => {
                Err(color_eyre::eyre::eyre!("Unsupported plugin manifest format: {}", extension))
            }
        }
    }
    
    /// Save the manifest to a file
    pub fn save_to_file<P: AsRef<Path>>(&self, path: P) -> Result<()> {
        let path = path.as_ref();
        
        let extension = path.extension()
            .and_then(|ext| ext.to_str())
            .unwrap_or("");
        
        let content = match extension {
            "toml" => {
                toml::to_string_pretty(self)
                    .with_context(|| "Failed to serialize plugin manifest to TOML")?
            },
            "json" => {
                serde_json::to_string_pretty(self)
                    .with_context(|| "Failed to serialize plugin manifest to JSON")?
            },
            _ => {
                return Err(color_eyre::eyre::eyre!("Unsupported plugin manifest format: {}", extension));
            }
        };
        
        fs::write(path, content)
            .with_context(|| format!("Failed to write plugin manifest to: {}", path.display()))?;
        
        Ok(())
    }
    
    /// Check if a plugin satisfies a version requirement
    pub fn satisfies_requirement(&self, requirement: &str) -> Result<bool> {
        let req = VersionReq::parse(requirement)
            .with_context(|| format!("Invalid version requirement: {}", requirement))?;
        
        let version = Version::parse(&self.version)
            .with_context(|| format!("Invalid plugin version: {}", self.version))?;
        
        Ok(req.matches(&version))
    }
}

/// Plugin state
#[derive(Debug, Clone, PartialEq, Eq)]
pub enum PluginState {
    /// Plugin is not installed
    NotInstalled,
    
    /// Plugin is installed but not enabled
    Installed,
    
    /// Plugin is installed and enabled
    Enabled,
    
    /// Plugin has an error
    Error(String),
}

/// Plugin instance
#[derive(Debug)]
pub struct Plugin {
    /// Plugin manifest
    pub manifest: PluginManifest,
    
    /// Plugin directory
    pub directory: PathBuf,
    
    /// Plugin state
    pub state: PluginState,
}

impl Plugin {
    /// Create a new plugin instance
    pub fn new(manifest: PluginManifest, directory: PathBuf) -> Self {
        Plugin {
            manifest,
            directory,
            state: PluginState::Installed,
        }
    }
    
    /// Execute a plugin hook
    pub fn execute_hook(&self, hook_name: &str, args: &[&str]) -> Result<String> {
        if let Some(hook) = self.manifest.hooks.iter().find(|h| h.name == hook_name) {
            let script_path = self.directory.join(&hook.script);
            
            if !script_path.exists() {
                return Err(color_eyre::eyre::eyre!("Hook script not found: {}", script_path.display()));
            }
            
            let output = Command::new(&script_path)
                .args(args)
                .current_dir(&self.directory)
                .output()
                .with_context(|| format!("Failed to execute hook script: {}", script_path.display()))?;
            
            if !output.status.success() {
                let error = String::from_utf8_lossy(&output.stderr).to_string();
                return Err(color_eyre::eyre::eyre!("Hook script failed: {}", error));
            }
            
            let stdout = String::from_utf8_lossy(&output.stdout).to_string();
            Ok(stdout)
        } else {
            Err(color_eyre::eyre::eyre!("Hook not found: {}", hook_name))
        }
    }
    
    /// Execute a plugin command
    pub fn execute_command(&self, command_name: &str, args: &[&str]) -> Result<String> {
        if let Some(command) = self.manifest.commands.iter().find(|c| c.name == command_name) {
            let script_path = self.directory.join(&command.script);
            
            if !script_path.exists() {
                return Err(color_eyre::eyre::eyre!("Command script not found: {}", script_path.display()));
            }
            
            let output = Command::new(&script_path)
                .args(args)
                .current_dir(&self.directory)
                .output()
                .with_context(|| format!("Failed to execute command script: {}", script_path.display()))?;
            
            if !output.status.success() {
                let error = String::from_utf8_lossy(&output.stderr).to_string();
                return Err(color_eyre::eyre::eyre!("Command script failed: {}", error));
            }
            
            let stdout = String::from_utf8_lossy(&output.stdout).to_string();
            Ok(stdout)
        } else {
            Err(color_eyre::eyre::eyre!("Command not found: {}", command_name))
        }
    }
}

/// Plugin loader for discovering and loading plugins
#[derive(Debug)]
pub struct PluginLoader {
    /// Directories to search for plugins
    plugin_dirs: Vec<PathBuf>,
}

impl PluginLoader {
    /// Create a new plugin loader
    pub fn new() -> Self {
        PluginLoader {
            plugin_dirs: vec![],
        }
    }
    
    /// Add a directory to search for plugins
    pub fn add_plugin_dir<P: AsRef<Path>>(&mut self, path: P) -> &mut Self {
        self.plugin_dirs.push(path.as_ref().to_path_buf());
        self
    }
    
    /// Discover all plugins
    pub fn discover_plugins(&self) -> Result<Vec<Plugin>> {
        let mut plugins = Vec::new();
        
        for dir in &self.plugin_dirs {
            if !dir.exists() || !dir.is_dir() {
                continue;
            }
            
            for entry in fs::read_dir(dir)
                .with_context(|| format!("Failed to read plugin directory: {}", dir.display()))? {
                let entry = entry?;
                let path = entry.path();
                
                if !path.is_dir() {
                    continue;
                }
                
                // Look for manifest files
                for ext in &["toml", "json"] {
                    let manifest_path = path.join(format!("plugin.{}", ext));
                    if manifest_path.exists() {
                        match PluginManifest::from_file(&manifest_path) {
                            Ok(manifest) => {
                                plugins.push(Plugin::new(manifest, path.clone()));
                                break;
                            },
                            Err(err) => {
                                tracing::warn!("Failed to load plugin manifest: {}: {}", manifest_path.display(), err);
                            }
                        }
                    }
                }
            }
        }
        
        Ok(plugins)
    }
    
    /// Load a specific plugin by name
    pub fn load_plugin(&self, name: &str) -> Result<Plugin> {
        for dir in &self.plugin_dirs {
            if !dir.exists() || !dir.is_dir() {
                continue;
            }
            
            let plugin_dir = dir.join(name);
            if !plugin_dir.exists() || !plugin_dir.is_dir() {
                continue;
            }
            
            // Look for manifest files
            for ext in &["toml", "json"] {
                let manifest_path = plugin_dir.join(format!("plugin.{}", ext));
                if manifest_path.exists() {
                    let manifest = PluginManifest::from_file(&manifest_path)?;
                    return Ok(Plugin::new(manifest, plugin_dir));
                }
            }
        }
        
        Err(color_eyre::eyre::eyre!("Plugin not found: {}", name))
    }
}

impl Default for PluginLoader {
    fn default() -> Self {
        let mut loader = PluginLoader::new();
        
        // Add default plugin directories
        if let Some(config_dir) = dirs::config_dir() {
            loader.add_plugin_dir(config_dir.join("hyprsupreme/plugins"));
        }
        
        if let Some(data_dir) = dirs::data_dir() {
            loader.add_plugin_dir(data_dir.join("hyprsupreme/plugins"));
        }
        
        // Add local plugins directory
        loader.add_plugin_dir("./plugins");
        
        loader
    }
}

/// Plugin manager for handling plugin lifecycle
#[derive(Debug)]
pub struct PluginManager {
    /// Plugin loader
    loader: PluginLoader,
    
    /// Loaded plugins
    plugins: HashMap<String, Plugin>,
    
    /// Enabled plugins
    enabled_plugins: Vec<String>,
}

impl PluginManager {
    /// Create a new plugin manager
    pub fn new() -> Self {
        PluginManager {
            loader: PluginLoader::default(),
            plugins: HashMap::new(),
            enabled_plugins: Vec::new(),
        }
    }
    
    /// Initialize the plugin manager
    pub fn initialize(&mut self) -> Result<()> {
        // Discover plugins
        let plugins = self.loader.discover_plugins()?;
        
        for plugin in plugins {
            self.plugins.insert(plugin.manifest.name.clone(), plugin);
        }
        
        Ok(())
    }
    
    /// Get the plugin loader
    pub fn loader(&self) -> &PluginLoader {
        &self.loader
    }
    
    /// Get a mutable reference to the plugin loader
    pub fn loader_mut(&mut self) -> &mut PluginLoader {
        &mut self.loader
    }
    
    /// Get a plugin by name
    pub fn get_plugin(&self, name: &str) -> Option<&Plugin> {
        self.plugins.get(name)
    }
    
    /// Get a mutable reference to a plugin by name
    pub fn get_plugin_mut(&mut self, name: &str) -> Option<&mut Plugin> {
        self.plugins.get_mut(name)
    }
    
    /// Get all loaded plugins
    pub fn get_all_plugins(&self) -> Vec<&Plugin> {
        self.plugins.values().collect()
    }
    
    /// Get all enabled plugins
    pub fn get_enabled_plugins(&self) -> Vec<&Plugin> {
        self.enabled_plugins.iter()
            .filter_map(|name| self.plugins.get(name))
            .collect()
    }
    
    /// Enable a plugin
    pub fn enable_plugin(&mut self, name: &str) -> Result<()> {
        if !self.plugins.contains_key(name) {
            return Err(color_eyre::eyre::eyre!("Plugin not found: {}", name));
        }
        
        // Check if already enabled
        if self.enabled_plugins.contains(&name.to_string()) {
            return Ok(());
        }
        
        // Check dependencies
        let dependencies = {
            let plugin = self.plugins.get(name).unwrap();
            plugin.manifest.dependencies.clone()
        };
        
        for (dep_name, dep_req) in dependencies {
            match self.plugins.get(&dep_name) {
                Some(dep) => {
                    if !dep.manifest.satisfies_requirement(&dep_req)? {
                        return Err(color_eyre::eyre::eyre!("Dependency version mismatch: {} requires {} {}", name, dep_name, dep_req));
                    }
                    
                    // Enable dependency if not already enabled
                    if !self.enabled_plugins.contains(&dep_name) {
                        self.enable_plugin(&dep_name)?;
                    }
                },
                None => {
                    return Err(color_eyre::eyre::eyre!("Missing dependency: {} requires {}", name, dep_name));
                }
            }
        }
        
        // Set state
        if let Some(plugin) = self.plugins.get_mut(name) {
            plugin.state = PluginState::Enabled;
        }
        
        // Add to enabled plugins
        self.enabled_plugins.push(name.to_string());
        
        Ok(())
    }
    
    /// Disable a plugin
    pub fn disable_plugin(&mut self, name: &str) -> Result<()> {
        if !self.plugins.contains_key(name) {
            return Err(color_eyre::eyre::eyre!("Plugin not found: {}", name));
        }
        
        // Check if already disabled
        if !self.enabled_plugins.contains(&name.to_string()) {
            return Ok(());
        }
        
        // Check for dependent plugins
        let dependent_plugins: Vec<String> = self.plugins.iter()
            .filter(|(_, plugin)| {
                plugin.manifest.dependencies.contains_key(name)
            })
            .map(|(dep_name, _)| dep_name.clone())
            .collect();
        
        // Disable dependent plugins first
        for dep_name in dependent_plugins {
            self.disable_plugin(&dep_name)?;
        }
        
        // Set state
        if let Some(plugin) = self.plugins.get_mut(name) {
            plugin.state = PluginState::Installed;
        }
        
        // Remove from enabled plugins
        self.enabled_plugins.retain(|n| n != name);
        
        Ok(())
    }
    
    /// Install a plugin from a directory
    pub fn install_plugin<P: AsRef<Path>>(&mut self, source_dir: P) -> Result<()> {
        let source_dir = source_dir.as_ref();
        
        // Find manifest
        let mut manifest_path = None;
        for ext in &["toml", "json"] {
            let path = source_dir.join(format!("plugin.{}", ext));
            if path.exists() {
                manifest_path = Some(path);
                break;
            }
        }
        
        let manifest_path = manifest_path
            .ok_or_else(|| color_eyre::eyre::eyre!("Plugin manifest not found in: {}", source_dir.display()))?;
        
        // Load manifest
        let manifest = PluginManifest::from_file(&manifest_path)?;
        
        // Determine target directory
        let target_dir = if let Some(config_dir) = dirs::config_dir() {
            let plugins_dir = config_dir.join("hyprsupreme/plugins");
            
            // Create directory if it doesn't exist
            if !plugins_dir.exists() {
                fs::create_dir_all(&plugins_dir)
                    .with_context(|| format!("Failed to create plugins directory: {}", plugins_dir.display()))?;
            }
            
            plugins_dir.join(&manifest.name)
        } else {
            return Err(color_eyre::eyre::eyre!("Could not determine config directory"));
        };
        
        // Check if already installed
        if target_dir.exists() {
            return Err(color_eyre::eyre::eyre!("Plugin already installed: {}", manifest.name));
        }
        
        // Copy plugin files
        fs_extra::dir::copy(
            source_dir,
            target_dir.parent().unwrap(),
            &fs_extra::dir::CopyOptions::new().content_only(false),
        ).with_context(|| format!("Failed to copy plugin files from {} to {}", source_dir.display(), target_dir.display()))?;
        
        // Load the plugin
        let plugin = Plugin::new(manifest, target_dir);
        self.plugins.insert(plugin.manifest.name.clone(), plugin);
        
        Ok(())
    }
    
    /// Uninstall a plugin
    pub fn uninstall_plugin(&mut self, name: &str) -> Result<()> {
        if !self.plugins.contains_key(name) {
            return Err(color_eyre::eyre::eyre!("Plugin not found: {}", name));
        }
        
        // Disable the plugin first
        if self.enabled_plugins.contains(&name.to_string()) {
            self.disable_plugin(name)?;
        }
        
        // Get plugin directory
        let dir = {
            let plugin = self.plugins.get(name).unwrap();
            plugin.directory.clone()
        };
        
        // Remove plugin directory
        if dir.exists() {
            fs::remove_dir_all(&dir)
                .with_context(|| format!("Failed to remove plugin directory: {}", dir.display()))?;
        }
        
        // Remove from plugins map
        self.plugins.remove(name);
        
        Ok(())
    }
    
    /// Execute a command from a specific plugin
    pub fn execute_command(&self, plugin_name: &str, command_name: &str, args: &[&str]) -> Result<String> {
        let plugin = self.get_plugin(plugin_name)
            .ok_or_else(|| color_eyre::eyre::eyre!("Plugin not found: {}", plugin_name))?;
        
        if !self.enabled_plugins.contains(&plugin_name.to_string()) {
            return Err(color_eyre::eyre::eyre!("Plugin not enabled: {}", plugin_name));
        }
        
        plugin.execute_command(command_name, args)
    }
    
    /// Get list of plugin names
    pub fn get_plugins(&self) -> Vec<String> {
        self.plugins.keys().cloned().collect()
    }
    
    /// Execute a hook for all enabled plugins
    pub fn execute_hook(&self, hook_name: &str, args: &[&str]) -> Result<HashMap<String, String>> {
        let mut results = HashMap::new();
        
        // Get all enabled plugins with the hook
        let plugins_with_hook: Vec<&Plugin> = self.get_enabled_plugins().into_iter()
            .filter(|plugin| plugin.manifest.hooks.iter().any(|h| h.name == hook_name))
            .collect();
        
        // Sort by priority
        let mut plugins_sorted = plugins_with_hook;
        plugins_sorted.sort_by(|a, b| {
            let a_priority = a.manifest.hooks.iter()
                .find(|h| h.name == hook_name)
                .map(|h| h.priority)
                .unwrap_or(0);
            
            let b_priority = b.manifest.hooks.iter()
                .find(|h| h.name == hook_name)
                .map(|h| h.priority)
                .unwrap_or(0);
            
            a_priority.cmp(&b_priority)
        });
        
        // Execute hooks
        for plugin in plugins_sorted {
            match plugin.execute_hook(hook_name, args) {
                Ok(output) => {
                    results.insert(plugin.manifest.name.clone(), output);
                },
                Err(err) => {
                    tracing::warn!("Failed to execute hook {} for plugin {}: {}", hook_name, plugin.manifest.name, err);
                }
            }
        }
        
        Ok(results)
    }
}

impl Default for PluginManager {
    fn default() -> Self {
        PluginManager {
            loader: PluginLoader::new(),
            plugins: HashMap::new(),
            enabled_plugins: Vec::new(),
        }
    }
}

use clap::{Parser, Subcommand};
use color_eyre::{eyre::WrapErr, Result};
use std::path::PathBuf;

mod config;
mod themes;
mod plugins;

use config::Config;
use themes::{ThemeManager, ThemeFormat};
use plugins::{PluginManager, PluginState};

/// HyprSupreme-Builder: A tool for managing Hyprland configurations
#[derive(Parser)]
#[clap(author, version, about, long_about = None)]
struct Cli {
    /// Optional config file path
    #[clap(short, long, value_parser)]
    config: Option<PathBuf>,

    /// Enable verbose output
    #[clap(short, long)]
    verbose: bool,

    #[clap(subcommand)]
    command: Commands,
}

#[derive(Subcommand)]
enum Commands {
    /// Initialize a new Hyprland configuration
    Init {
        /// Directory to initialize the configuration in
        #[clap(short, long, value_parser, default_value = ".")]
        dir: PathBuf,
        
        /// Template to use for initialization
        #[clap(short, long, default_value = "default")]
        template: String,
    },
    
    /// Build/compile Hyprland configurations
    Build {
        /// Configuration file to build
        #[clap(short, long, value_parser)]
        config: Option<PathBuf>,
        
        /// Output directory for built configuration
        #[clap(short, long, value_parser)]
        output: Option<PathBuf>,
    },
    
    /// Update existing Hyprland configurations
    Update {
        /// Configuration file to update
        #[clap(short, long, value_parser)]
        config: Option<PathBuf>,
        
        /// Specific component to update
        #[clap(short = 'm', long)]
        component: Option<String>,
    },
    /// Theme management commands
    Theme {
        #[clap(subcommand)]
        command: ThemeCommands,
    },
    
    /// Plugin management commands
    Plugin {
        #[clap(subcommand)]
        command: PluginCommands,
    },
}

#[derive(Subcommand)]
enum ThemeCommands {
    /// List available themes
    List,
    
    /// Show details of a theme
    Show {
        /// Name of the theme
        name: String,
    },
    
    /// Create a new theme
    Create {
        /// Name of the theme
        name: String,
        
        /// Format to use (toml or json)
        #[clap(short, long, default_value = "toml")]
        format: String,
    },
    
    /// Apply a theme
    Apply {
        /// Name of the theme
        name: String,
    },
}

#[derive(Subcommand)]
enum PluginCommands {
    /// List available plugins
    List,
    
    /// Show details of a plugin
    Show {
        /// Name of the plugin
        name: String,
    },
    
    /// Install a plugin
    Install {
        /// Path to the plugin directory
        path: PathBuf,
    },
    
    /// Uninstall a plugin
    Uninstall {
        /// Name of the plugin
        name: String,
    },
    
    /// Enable a plugin
    Enable {
        /// Name of the plugin
        name: String,
    },
    
    /// Disable a plugin
    Disable {
        /// Name of the plugin
        name: String,
    },
}

/// Setup function for initializing logging and error handling
fn setup() -> Result<()> {
    // Setup color_eyre for error handling
    color_eyre::install()?;
    
    // Initialize environment logger if verbose output is requested
    if std::env::var("RUST_LOG").is_err() {
        std::env::set_var("RUST_LOG", "info");
    }
    
    // Setup logging
    tracing_subscriber::fmt::init();
    
    Ok(())
}

fn init_command(dir: PathBuf, template: String) -> Result<()> {
    println!("Initializing new configuration in {:?} using template '{}'", dir, template);
    
    // Create directory if it doesn't exist
    if !dir.exists() {
        std::fs::create_dir_all(&dir)
            .wrap_err_with(|| format!("Failed to create directory: {:?}", dir))?;
    }
    
    // Create default configuration
    let config = Config::default_config();
    
    // Write configuration to file
    let config_path = dir.join("hyprsupreme.toml");
    let toml_string = toml::to_string_pretty(&config)
        .wrap_err("Failed to serialize configuration")?;
    
    std::fs::write(&config_path, toml_string)
        .wrap_err_with(|| format!("Failed to write configuration to: {:?}", config_path))?;
    
    println!("Created new configuration at: {:?}", config_path);
    
    Ok(())
}

fn build_command(config: Option<PathBuf>, output: Option<PathBuf>) -> Result<()> {
    let config_path = config.unwrap_or_else(|| PathBuf::from("hyprsupreme.toml"));
    let output_dir = output.unwrap_or_else(|| PathBuf::from("build"));
    
    println!("Building configuration from {:?} to {:?}", config_path, output_dir);
    
    // Load configuration
    let config = Config::from_file(&config_path)
        .wrap_err_with(|| format!("Failed to load configuration from: {:?}", config_path))?;
    
    // Create output directory if it doesn't exist
    if !output_dir.exists() {
        std::fs::create_dir_all(&output_dir)
            .wrap_err_with(|| format!("Failed to create output directory: {:?}", output_dir))?;
    }
    
    // Get active profile
    let profile = config.get_active_profile(None)?;
    
    println!("Using profile: {}", config.default_profile);
    println!("Resolving variables and generating configuration files...");
    
    // Example of variable resolution
    if let Some(_) = profile.variables.get("terminal") {
        let resolved = config.resolve_variables(&format!("Terminal: ${{terminal}}"), None);
        println!("Example variable resolution: {}", resolved);
    }
    
    // TODO: Generate Hyprland configuration files
    
    println!("Build completed successfully!");
    
    Ok(())
}

fn update_command(config: Option<PathBuf>, component: Option<String>) -> Result<()> {
    let config_path = config.unwrap_or_else(|| PathBuf::from("hyprsupreme.toml"));
    
    match &component {
        Some(comp) => println!("Updating component '{}' in {:?}", comp, config_path),
        None => println!("Updating all components in {:?}", config_path),
    }
    
    // Load configuration
    let mut config = Config::from_file(&config_path)
        .wrap_err_with(|| format!("Failed to load configuration from: {:?}", config_path))?;
    
    // Check if we're updating a specific component
    if let Some(ref comp_name) = component {
        println!("Focusing on component: {}", comp_name);
        
        // Example of updating theme variables if the component is "theme"
        if comp_name == "theme" {
            println!("Updating theme variables...");
            config.variables.insert("color.accent".to_string(), "#7dcfff".to_string());
            
            // Save updated configuration
            let toml_string = toml::to_string_pretty(&config)
                .wrap_err("Failed to serialize updated configuration")?;
            
            std::fs::write(&config_path, toml_string)
                .wrap_err_with(|| format!("Failed to write updated configuration to: {:?}", config_path))?;
            
            println!("Theme updated successfully!");
        } else {
            println!("Component '{}' update not implemented yet", comp_name);
        }
    } else {
        println!("Full configuration update not implemented yet");
    }
    
    Ok(())
}

fn main() -> Result<()> {
    // Setup error handling and logging
    setup().wrap_err("Failed to setup application")?;
    
    // Parse command line arguments
    let cli = Cli::parse();
    
    // Set verbose logging if requested
    if cli.verbose {
        std::env::set_var("RUST_LOG", "debug");
    }
    
    // Handle commands
    match cli.command {
        Commands::Init { dir, template } => {
            init_command(dir, template)?;
        },
        Commands::Build { config, output } => {
            build_command(config, output)?;
        },
        Commands::Update { config, component } => {
            update_command(config, component)?;
        },
        Commands::Theme { command } => {
            match command {
                ThemeCommands::List => {
                    let theme_manager = ThemeManager::default();
                    let themes = theme_manager.list_themes();
                    
                    println!("Available themes:");
                    for theme in themes {
                        println!("  - {}", theme);
                    }
                },
                ThemeCommands::Show { name } => {
                    let theme_manager = ThemeManager::default();
                    match theme_manager.loader().load_theme(&name) {
                        Ok(theme) => {
                            println!("Theme: {}", theme.name);
                            if let Some(author) = &theme.author {
                                println!("Author: {}", author);
                            }
                            if let Some(description) = &theme.description {
                                println!("Description: {}", description);
                            }
                            println!("Version: {}", theme.version);
                            
                            println!("\nColors:");
                            for (name, value) in &theme.colors {
                                println!("  {}: {}", name, value);
                            }
                            
                            println!("\nVariables:");
                            for (name, value) in &theme.variables {
                                println!("  {}: {}", name, value);
                            }
                        },
                        Err(err) => {
                            println!("Error loading theme '{}': {}", name, err);
                        }
                    }
                },
                ThemeCommands::Create { name, format } => {
                    let mut theme_manager = ThemeManager::default();
                    let mut theme = theme_manager.create_theme(&name);
                    
                    // Add some default colors
                    theme.colors.insert("background".to_string(), "#1a1b26".to_string());
                    theme.colors.insert("foreground".to_string(), "#c0caf5".to_string());
                    theme.colors.insert("accent".to_string(), "#7aa2f7".to_string());
                    
                    // Add some metadata
                    theme.description = Some(format!("A theme for Hyprland"));
                    theme.author = Some("HyprSupreme Builder".to_string());
                    
                    // Determine format
                    let theme_format = match format.to_lowercase().as_str() {
                        "json" => ThemeFormat::Json,
                        _ => ThemeFormat::Toml,
                    };
                    
                    // Save the theme
                    match theme_manager.save_theme(&theme, theme_format) {
                        Ok(path) => {
                            println!("Created theme '{}' at: {}", name, path.display());
                        },
                        Err(err) => {
                            println!("Error creating theme '{}': {}", name, err);
                        }
                    }
                },
                ThemeCommands::Apply { name } => {
                    let mut theme_manager = ThemeManager::default();
                    match theme_manager.set_theme(&name) {
                        Ok(_) => {
                            println!("Applied theme: {}", name);
                            // TODO: Generate and apply Hyprland configuration
                        },
                        Err(err) => {
                            println!("Error applying theme '{}': {}", name, err);
                        }
                    }
                },
            }
        },
        Commands::Plugin { command } => {
            let mut plugin_manager = PluginManager::default();
            plugin_manager.initialize()?;
            
            match command {
                PluginCommands::List => {
                    let plugin_names = plugin_manager.get_plugins();
                    
                    println!("Available plugins:");
                    for plugin_name in plugin_names {
                        if let Some(plugin) = plugin_manager.get_plugin(&plugin_name) {
                            let status = match plugin.state {
                                PluginState::Enabled => "enabled",
                                PluginState::Installed => "installed",
                                PluginState::NotInstalled => "not installed",
                                PluginState::Error(_) => "error",
                            };
                            
                            println!("  - {} (v{}) [{}]", plugin.manifest.name, plugin.manifest.version, status);
                            if let Some(desc) = &plugin.manifest.description {
                                println!("    {}", desc);
                            }
                        }
                    }
                },
                PluginCommands::Show { name } => {
                    match plugin_manager.get_plugin(&name) {
                        Some(plugin) => {
                            println!("Plugin: {}", plugin.manifest.name);
                            if let Some(display_name) = &plugin.manifest.display_name {
                                println!("Display Name: {}", display_name);
                            }
                            if let Some(author) = &plugin.manifest.author {
                                println!("Author: {}", author);
                            }
                            if let Some(description) = &plugin.manifest.description {
                                println!("Description: {}", description);
                            }
                            println!("Version: {}", plugin.manifest.version);
                            
                            if !plugin.manifest.dependencies.is_empty() {
                                println!("\nDependencies:");
                                for (dep_name, dep_ver) in &plugin.manifest.dependencies {
                                    println!("  {}: {}", dep_name, dep_ver);
                                }
                            }
                            
                            if !plugin.manifest.hooks.is_empty() {
                                println!("\nHooks:");
                                for hook in &plugin.manifest.hooks {
                                    println!("  {}: {}", hook.name, hook.script);
                                }
                            }
                            
                            if !plugin.manifest.commands.is_empty() {
                                println!("\nCommands:");
                                for cmd in &plugin.manifest.commands {
                                    println!("  {}: {}", cmd.name, cmd.script);
                                    if let Some(desc) = &cmd.description {
                                        println!("    {}", desc);
                                    }
                                }
                            }
                        },
                        None => {
                            println!("Plugin '{}' not found", name);
                        }
                    }
                },
                PluginCommands::Install { path } => {
                    match plugin_manager.install_plugin(&path) {
                        Ok(_) => {
                            println!("Plugin installed successfully from: {}", path.display());
                        },
                        Err(err) => {
                            println!("Error installing plugin: {}", err);
                        }
                    }
                },
                PluginCommands::Uninstall { name } => {
                    match plugin_manager.uninstall_plugin(&name) {
                        Ok(_) => {
                            println!("Plugin '{}' uninstalled successfully", name);
                        },
                        Err(err) => {
                            println!("Error uninstalling plugin '{}': {}", name, err);
                        }
                    }
                },
                PluginCommands::Enable { name } => {
                    match plugin_manager.enable_plugin(&name) {
                        Ok(_) => {
                            println!("Plugin '{}' enabled successfully", name);
                        },
                        Err(err) => {
                            println!("Error enabling plugin '{}': {}", name, err);
                        }
                    }
                },
                PluginCommands::Disable { name } => {
                    match plugin_manager.disable_plugin(&name) {
                        Ok(_) => {
                            println!("Plugin '{}' disabled successfully", name);
                        },
                        Err(err) => {
                            println!("Error disabling plugin '{}': {}", name, err);
                        }
                    }
                },
            }
        },
    }
    
    Ok(())
}

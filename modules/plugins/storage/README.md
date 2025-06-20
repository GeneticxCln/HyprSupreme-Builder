# HyprSupreme Plugin Storage

This directory is used to store plugins for HyprSupreme-Builder. Plugins are organized into subdirectories by plugin name.

## Directory Structure

```
storage/
├── auto-theme/                 # Auto theme switcher plugin
│   ├── manifest.yaml           # Plugin manifest
│   ├── scripts/                # Plugin scripts
│   ├── config/                 # Plugin configuration
│   └── assets/                 # Plugin assets
├── workspace-manager/          # Workspace manager plugin
│   ├── manifest.yaml
│   ├── scripts/
│   ├── config/
│   └── assets/
└── ...
```

## Plugin Format

Each plugin is stored in its own directory and includes:

- Plugin manifest (manifest.yaml)
- Script directory containing plugin functionality
- Configuration directory for plugin settings
- Optional assets directory for resources

## Plugin State

Plugins can be in one of the following states:

- **Installed**: Plugin is installed but not enabled
- **Enabled**: Plugin is installed and active
- **Disabled**: Plugin is installed but disabled
- **Error**: Plugin is installed but has encountered an error

Plugin state is maintained by the PluginManager and stored in the state.yaml file.

## Adding Plugins

Plugins can be added to this directory through:

1. Installation from the community repository:
   ```
   hyprsupreme plugin install auto-theme
   ```

2. Manual installation:
   ```
   hyprsupreme plugin install --local /path/to/plugin
   ```

## Managing Plugins

To enable a plugin:
```
hyprsupreme plugin enable auto-theme
```

To disable a plugin:
```
hyprsupreme plugin disable auto-theme
```

To list installed plugins:
```
hyprsupreme plugin list
```

To show plugin details:
```
hyprsupreme plugin show auto-theme
```

To uninstall a plugin:
```
hyprsupreme plugin uninstall auto-theme
```

## Plugin Guidelines

- Each plugin should have a unique name
- Plugin names should use kebab-case (e.g., my-awesome-plugin)
- All scripts should be executable
- Plugin should clean up after itself when disabled or uninstalled
- Plugin should handle errors gracefully

## Note for Developers

This directory is managed by the PluginManager. Do not modify its contents directly, as this may cause unexpected behavior. Use the HyprSupreme CLI tools or API to manage plugins.

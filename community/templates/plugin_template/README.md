# HyprSupreme Plugin Template

This directory contains a template for creating plugins for HyprSupreme-Builder. Plugins extend the functionality of HyprSupreme and can provide additional features, integrations, and customizations.

## Getting Started

1. Copy this plugin template directory to start creating your plugin.
2. Rename the directory to your plugin name (use kebab-case, e.g., `my-awesome-plugin`).
3. Edit the `manifest.yaml` file with your plugin's information.
4. Implement your plugin's functionality in the `scripts` directory.
5. Add documentation in this README file.

## Plugin Structure

A well-organized plugin should have the following structure:

```
my-awesome-plugin/
├── manifest.yaml       # Plugin manifest with metadata and configuration
├── README.md           # Plugin documentation
├── LICENSE             # License file
├── scripts/            # Shell scripts for plugin functionality
│   ├── startup.sh      # Script executed at startup
│   ├── shutdown.sh     # Script executed at shutdown
│   └── commands/       # Plugin command scripts
│       ├── example.sh  # Example command implementation
│       └── toggle.sh   # Another command implementation
├── assets/             # Plugin assets (images, sounds, etc.)
├── config/             # Default configuration files
└── examples/           # Example configurations and usage
```

## Manifest File

The `manifest.yaml` file defines your plugin's metadata, dependencies, hooks, commands, and default configuration. It follows a structured format that HyprSupreme uses to integrate your plugin.

Key sections include:
- Basic information (name, version, author)
- Dependencies
- Hooks (scripts triggered by events)
- Commands (user-executable actions)
- Configuration defaults
- Hyprland integration

## Scripts

Your plugin's functionality is implemented through shell scripts in the `scripts` directory:

- Hook scripts are executed automatically on specific events
- Command scripts are executed when the user runs your plugin's commands
- All scripts should be executable (`chmod +x scripts/*.sh`)

## Testing Your Plugin

Test your plugin locally before sharing:

```bash
# Test plugin installation
hyprsupreme plugin install --local /path/to/my-awesome-plugin

# Test plugin commands
hyprsupreme plugin my-awesome-plugin example-command

# Check plugin status
hyprsupreme plugin status my-awesome-plugin
```

## Sharing Your Plugin

To share your plugin with the community:

1. Ensure your plugin follows the template structure.
2. Make sure all scripts are executable and well-documented.
3. Use the community sharing tool:

```bash
hyprsupreme community share-plugin /path/to/my-awesome-plugin
```

## Best Practices

- Make your plugin configurable
- Handle errors gracefully
- Provide meaningful feedback to users
- Document your plugin thoroughly
- Follow shell scripting best practices
- Test on multiple distributions

## Example Plugins

For inspiration, check out these example plugins:
- Auto Theme Switcher: Automatically changes themes based on time of day
- Dynamic Workspace Names: Displays the current app in workspace name
- System Monitor Integration: Shows system stats in Waybar

## Resources

- [HyprSupreme Plugin Development Guide](https://hyprsupreme.example.com/plugins)
- [Hyprland IPC Documentation](https://wiki.hyprland.org/IPC/)
- [Shell Scripting Best Practices](https://github.com/progrium/bashstyle)

## License

Plugins shared with the community should include a license. We recommend using MIT, BSD, or GPL licenses.

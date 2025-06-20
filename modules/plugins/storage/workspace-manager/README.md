# Workspace Manager Plugin

A plugin for HyprSupreme-Builder that provides dynamic workspace naming and layout management for Hyprland.

## Features

- Dynamic workspace naming based on active applications
- App icon support in workspace names
- Custom workspace layouts
- Per-workspace layout persistence
- Automatic workspace initialization
- Window count tracking
- Custom keybindings for workspace management

## Installation

```bash
hyprsupreme plugin install workspace-manager
```

## Configuration

The plugin can be configured by editing the configuration file:

```bash
hyprsupreme plugin config workspace-manager
```

### Configuration Options

- `dynamic_names`: Enable/disable dynamic workspace naming based on application
- `icon_support`: Enable/disable icons in workspace names
- `persist_names`: Remember custom workspace names
- `default_layout`: Default layout for new workspaces ("dwindle" or "master")
- `auto_arrange`: Automatically arrange windows for optimal layout
- `workspace_icons`: Custom icons for specific workspaces
- `app_icons`: Custom icons for specific applications

## Usage

### Rename a Workspace

```bash
hyprsupreme plugin workspace-manager rename 1 "Web"
```

### Set Workspace Layout

```bash
hyprsupreme plugin workspace-manager layout 2 master
```

### List Workspaces

```bash
hyprsupreme plugin workspace-manager list
```

### Create a New Workspace

```bash
hyprsupreme plugin workspace-manager create "Code" dwindle 0
```

## Keyboard Shortcuts

The plugin adds the following keyboard shortcuts:

- `SUPER + grave`: Rename current workspace
- `SUPER + ALT + l`: Set current workspace to dwindle layout
- `SUPER + ALT + m`: Set current workspace to master layout

## How It Works

The Workspace Manager plugin monitors Hyprland events through the Hyprland socket to track workspace changes, window openings, and window closures. It maintains state in a JSON file that tracks:

- Current workspaces and their custom names
- Layout for each workspace
- Windows in each workspace
- Active workspace

When events occur, it updates workspace names and layouts according to your configuration.

## Integration with Other Plugins

Workspace Manager works well with the following plugins:

- Auto Theme Switcher: Apply different themes to different workspace types
- Window Rules: Automatically assign applications to specific workspaces
- Status Bar Integration: Display custom workspace names in status bar

## Troubleshooting

If the plugin isn't working as expected:

1. Check the logs: `hyprsupreme logs plugin workspace-manager`
2. Verify the plugin is enabled: `hyprsupreme plugin list`
3. Make sure Hyprland IPC socket is accessible
4. Check that the required dependencies are installed

## License

This plugin is licensed under the MIT License.

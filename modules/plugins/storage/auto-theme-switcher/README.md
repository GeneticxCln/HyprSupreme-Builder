# Auto Theme Switcher Plugin

A plugin for HyprSupreme-Builder that automatically switches between light and dark themes based on time of day or sunrise/sunset.

## Features

- Automatically switch between light and dark themes
- Schedule changes based on fixed times
- Use geolocation for sunrise/sunset-based switching
- Smooth transitions between themes (optional)
- Manual override with easy toggle
- Status monitoring and notifications

## Installation

```bash
hyprsupreme plugin install auto-theme-switcher
```

## Configuration

The plugin can be configured by editing the configuration file:

```bash
hyprsupreme plugin config auto-theme-switcher
```

Or by using the plugin commands:

```bash
# Set light and dark themes
hyprsupreme plugin auto-theme-switcher set-themes catppuccin-latte tokyo-night

# Set switch times (24-hour format)
hyprsupreme plugin auto-theme-switcher set-times 07:00 19:00
```

### Configuration Options

- `light_theme`: Theme to use during daylight hours
- `dark_theme`: Theme to use during nighttime hours
- `day_starts`: Time when day begins (HH:MM, 24-hour format)
- `night_starts`: Time when night begins (HH:MM, 24-hour format)
- `use_location`: Whether to use geolocation for sunrise/sunset times
- `latitude`, `longitude`: Geographic coordinates (for sunrise/sunset calculation)
- `transition`: Theme transition style (instant, fade, smooth)

## Usage

### Toggle Automatic Switching

```bash
hyprsupreme plugin auto-theme-switcher toggle
```

### Check Current Status

```bash
hyprsupreme plugin auto-theme-switcher status
```

### Manually Apply Theme

```bash
# Force light theme
hyprsupreme theme apply $(hyprsupreme plugin auto-theme-switcher get-light-theme)

# Force dark theme
hyprsupreme theme apply $(hyprsupreme plugin auto-theme-switcher get-dark-theme)
```

## Keyboard Shortcuts

The plugin adds the following keyboard shortcuts:

- `SUPER+SHIFT+T`: Toggle automatic theme switching

## Integration with Other Plugins

Auto Theme Switcher works well with the following plugins:

- Wallpaper Manager: Coordinated wallpaper changes with theme switches
- System Integration: Sync themes with GTK, icons, and cursor themes
- Notification Center: Enhanced theme change notifications

## Troubleshooting

If the plugin isn't working as expected:

1. Check the logs: `hyprsupreme logs plugin auto-theme-switcher`
2. Verify the plugin is enabled: `hyprsupreme plugin list`
3. Test manual theme switching: `hyprsupreme theme apply tokyo-night`
4. Check for geolocation services if using location-based switching

## License

This plugin is licensed under the MIT License.

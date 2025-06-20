# Catppuccin Theme Collection

A collection of soothing pastel themes for HyprSupreme-Builder based on the popular Catppuccin color scheme.

## Variants

The Catppuccin collection includes four flavors:

- **Mocha**: Warm dark theme (default)
- **Macchiato**: Dark theme with medium contrast
- **Frappe**: Dark theme with lower contrast
- **Latte**: Light theme

## Features

- Carefully selected pastel color palette
- Four variants for different preferences and lighting conditions
- Fine-tuned for readability and eye comfort
- Consistent experience across applications
- Coordinated GTK, icon, and cursor themes

## Screenshots

![Catppuccin Mocha Screenshot](screenshot-mocha.png)

## Installation

You can install any variant using the HyprSupreme theme manager:

```bash
# Install the Mocha variant (default)
hyprsupreme theme install catppuccin-mocha

# Install other variants
hyprsupreme theme install catppuccin-macchiato
hyprsupreme theme install catppuccin-frappe
hyprsupreme theme install catppuccin-latte
```

## Usage

Apply a theme variant with:

```bash
hyprsupreme theme apply catppuccin-mocha
```

## Integration with Auto Theme Switcher

These themes work perfectly with the Auto Theme Switcher plugin. You can configure it to automatically switch between light and dark variants:

```bash
hyprsupreme plugin auto-theme-switcher set-themes catppuccin-latte catppuccin-mocha
```

## Color Palette

### Mocha Palette

| Color Name | Hex Code  | Description         |
|------------|-----------|---------------------|
| Base       | `#1e1e2e` | Background          |
| Text       | `#cdd6f4` | Foreground text     |
| Mauve      | `#cba6f7` | Primary accent      |
| Pink       | `#f5c2e7` | Secondary accent    |
| Red        | `#f38ba8` | Error/delete        |
| Green      | `#a6e3a1` | Success/add         |
| Yellow     | `#f9e2af` | Warning/modify      |
| Blue       | `#89b4fa` | Info/links          |
| Lavender   | `#b4befe` | Highlights          |
| Peach      | `#fab387` | Functions/keywords  |
| Sky        | `#89dceb` | Operators           |
| Teal       | `#94e2d5` | Variables           |

## Compatibility

These themes are designed to work with:

- Hyprland (>= 0.24.0)
- Waybar
- Rofi
- Kitty, Alacritty, and other terminal emulators
- GTK and Qt applications
- Dunst/Mako notifications

## Credits

- Based on the [Catppuccin](https://github.com/catppuccin/catppuccin) color scheme
- Wallpapers created by the Catppuccin community

## License

This theme collection is released under the MIT License.

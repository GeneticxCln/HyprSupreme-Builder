# HyprSupreme Theme Template

This directory contains templates for creating themes for HyprSupreme-Builder. Themes define the appearance of your Hyprland environment, including colors, fonts, and various visual settings.

## Creating a Theme

1. Start by copying either the `theme_template.toml` or `theme_template.json` file, depending on your preferred format.
2. Rename the file to your theme name (e.g., `mytheme.toml` or `mytheme.json`).
3. Edit the file and customize all the settings according to your preferences.
4. Add a screenshot of your theme to help others preview it.

## Theme Structure

A theme consists of the following sections:

### Metadata
Basic information about your theme, such as name, version, author, and description.

### Colors
A collection of color definitions used throughout the Hyprland environment, including:
- Background and foreground colors
- Accent colors
- Terminal colors
- Status colors (error, warning, success)

### Variables
Configuration variables that define sizes, fonts, and other stylistic elements:
- Font family and sizes
- Border properties
- Gaps
- Shadow properties
- Blur settings

### Hyprland Settings
Direct settings for Hyprland features such as animations, blur, shadows, and transparency.

### Advanced Settings
Additional configuration options for theme integration and compatibility.

## Testing Your Theme

You can test your theme using the HyprSupreme theme preview tool:

```
hyprsupreme theme preview mytheme.toml
```

## Submitting Your Theme

To share your theme with the community:

1. Ensure your theme follows the template structure.
2. Add a screenshot of your theme in action.
3. Use the community sharing tool:

```
hyprsupreme community share-theme mytheme.toml
```

## Example

See the `example.toml` file for a complete theme example with annotations.

## Resources

- [Color Palette Generator](https://coolors.co/)
- [Hyprland Documentation](https://wiki.hyprland.org/)
- [HyprSupreme Theming Guide](https://hyprsupreme.example.com/theming)

## License

Themes submitted to the community should include a license. We recommend using MIT, BSD, or CC licenses for maximum compatibility.

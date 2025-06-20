# HyprSupreme Theme Storage

This directory is used to store themes for HyprSupreme-Builder. Themes are organized into subdirectories by theme name.

## Directory Structure

```
storage/
├── default/            # Default theme
│   ├── theme.toml      # Theme configuration
│   ├── wallpaper.jpg   # Theme wallpaper
│   └── screenshot.png  # Theme screenshot
├── catppuccin-mocha/   # Another theme
│   ├── theme.toml
│   ├── wallpaper.jpg
│   └── screenshot.png
└── ...
```

## Theme Format

Themes can be stored in either TOML or JSON format, depending on the user's preference. Each theme is stored in its own directory and includes:

- Theme configuration file (theme.toml or theme.json)
- Wallpaper image(s)
- Screenshot for preview
- Optional additional assets

## Adding Themes

Themes can be added to this directory through:

1. Installation from the community repository:
   ```
   hyprsupreme theme install catppuccin-mocha
   ```

2. Manual addition:
   ```
   hyprsupreme theme add /path/to/theme.toml
   ```

3. Theme creation:
   ```
   hyprsupreme theme create mytheme
   ```

## Using Themes

To apply a theme, use:
```
hyprsupreme theme apply mytheme
```

To list available themes:
```
hyprsupreme theme list
```

To preview a theme:
```
hyprsupreme theme preview mytheme
```

## Theme Guidelines

- Each theme should have a unique name
- Theme names should use kebab-case (e.g., my-awesome-theme)
- Include a screenshot of the theme in action
- Provide a default wallpaper that complements the theme
- Document any special features or requirements

## Note for Developers

This directory is managed by the ThemeManager. Do not modify its contents directly, as this may cause unexpected behavior. Use the HyprSupreme CLI tools or API to manage themes.

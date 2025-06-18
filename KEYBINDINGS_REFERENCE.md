# 🎮 HyprSupreme Keybindings Reference

## 📝 Key Information
- **Main Modifier**: `SUPER` (Windows key)
- **Secondary Modifiers**: `CTRL`, `ALT`, `SHIFT`
- **Configuration Files**:
  - Main: `~/.config/hypr/configs/Keybinds.conf`
  - User: `~/.config/hypr/UserConfigs/UserKeybinds.conf`
  - Laptops: `~/.config/hypr/UserConfigs/Laptops.conf`

---

## 🚪 System & Session Management

| Keybinding | Action | Description |
|------------|--------|-------------|
| `CTRL + ALT + Delete` | Exit Hyprland | Close Hyprland session |
| `SUPER + Q` | Kill Active | Close focused window |
| `SUPER + SHIFT + Q` | Force Kill | Kill active process |
| `CTRL + ALT + L` | Lock Screen | Lock the screen |
| `CTRL + ALT + P` | Power Menu | Open logout/shutdown menu |

---

## 📱 Applications & Launchers

| Keybinding | Action | Description |
|------------|--------|-------------|
| `SUPER + D` | App Launcher | Open Rofi application menu |
| `SUPER + Return` | Terminal | Open default terminal |
| `SUPER + E` | File Manager | Open default file manager |
| `SUPER + B` | Browser | Open default web browser |
| `SUPER + A` | Desktop Overview | Open AGS desktop overview |

---

## 🖼️ Window Management

| Keybinding | Action | Description |
|------------|--------|-------------|
| `SUPER + SPACE` | Toggle Float | Toggle floating mode |
| `SUPER + SHIFT + F` | Fullscreen | Toggle fullscreen |
| `SUPER + CTRL + F` | Fake Fullscreen | Toggle fake fullscreen |
| `SUPER + ALT + SPACE` | All Float | Make all windows float |
| `SUPER + G` | Toggle Group | Toggle window grouping |
| `SUPER + CTRL + Tab` | Change Group | Switch focus in group |

### Window Movement
| Keybinding | Action | Description |
|------------|--------|-------------|
| `SUPER + ←/→/↑/↓` | Move Focus | Change window focus |
| `SUPER + CTRL + ←/→/↑/↓` | Move Window | Move window position |
| `SUPER + ALT + ←/→/↑/↓` | Swap Window | Swap window with neighbor |
| `SUPER + SHIFT + ←/→/↑/↓` | Resize Window | Resize window |

### Master Layout
| Keybinding | Action | Description |
|------------|--------|-------------|
| `SUPER + I` | Add Master | Add window to master |
| `SUPER + CTRL + D` | Remove Master | Remove from master |
| `SUPER + J` | Cycle Next | Cycle to next window |
| `SUPER + K` | Cycle Previous | Cycle to previous window |
| `SUPER + CTRL + Return` | Swap Master | Swap with master window |

### Dwindle Layout
| Keybinding | Action | Description |
|------------|--------|-------------|
| `SUPER + SHIFT + I` | Toggle Split | Toggle split direction |
| `SUPER + P` | Pseudo Mode | Toggle pseudo mode |
| `SUPER + M` | Split Ratio | Set split ratio to 0.3 |

---

## 🖥️ Workspace Management

### Basic Workspace Navigation
| Keybinding | Action | Description |
|------------|--------|-------------|
| `SUPER + 1-0` | Switch Workspace | Go to workspace 1-10 |
| `SUPER + Tab` | Next Workspace | Move to next workspace |
| `SUPER + SHIFT + Tab` | Previous Workspace | Move to previous workspace |
| `SUPER + ,/.` | Cycle Workspaces | Scroll through workspaces |

### Moving Windows Between Workspaces
| Keybinding | Action | Description |
|------------|--------|-------------|
| `SUPER + SHIFT + 1-0` | Move & Follow | Move window and follow |
| `SUPER + CTRL + 1-0` | Move Silent | Move window silently |
| `SUPER + SHIFT + [/]` | Move to Adjacent | Move to next/previous workspace |

### Special Workspace
| Keybinding | Action | Description |
|------------|--------|-------------|
| `SUPER + U` | Toggle Special | Show/hide special workspace |
| `SUPER + SHIFT + U` | Move to Special | Move window to special workspace |

---

## 📸 Screenshots

| Keybinding | Action | Description |
|------------|--------|-------------|
| `SUPER + Print` | Screenshot | Take full screenshot |
| `SUPER + SHIFT + Print` | Area Screenshot | Screenshot selected area |
| `SUPER + CTRL + Print` | Delayed (5s) | Screenshot with 5s delay |
| `SUPER + CTRL + SHIFT + Print` | Delayed (10s) | Screenshot with 10s delay |
| `ALT + Print` | Active Window | Screenshot active window only |
| `SUPER + SHIFT + S` | Swappy | Screenshot with Swappy editor |

---

## 🔊 Audio & Media Controls

### Volume Controls
| Keybinding | Action | Description |
|------------|--------|-------------|
| `XF86AudioRaiseVolume` | Volume Up | Increase system volume |
| `XF86AudioLowerVolume` | Volume Down | Decrease system volume |
| `XF86AudioMute` | Toggle Mute | Mute/unmute audio |
| `XF86AudioMicMute` | Mic Mute | Toggle microphone mute |

### Media Controls
| Keybinding | Action | Description |
|------------|--------|-------------|
| `XF86AudioPlayPause` | Play/Pause | Toggle media playback |
| `XF86AudioNext` | Next Track | Skip to next track |
| `XF86AudioPrev` | Previous Track | Go to previous track |
| `XF86AudioStop` | Stop | Stop media playback |

---

## 🎨 Features & Customization

### Interface Management
| Keybinding | Action | Description |
|------------|--------|-------------|
| `SUPER + SHIFT + N` | Notifications | Toggle notification panel |
| `SUPER + SHIFT + E` | Quick Settings | Open Hyprland settings |
| `SUPER + H` | Key Hints | Show keybinding cheat sheet |
| `SUPER + ALT + R` | Refresh UI | Refresh waybar/rofi/swaync |

### Visual Effects
| Keybinding | Action | Description |
|------------|--------|-------------|
| `SUPER + ALT + O` | Toggle Blur | Change blur settings |
| `SUPER + SHIFT + G` | Game Mode | Toggle animations |
| `SUPER + ALT + L` | Layout Toggle | Switch master/dwindle layout |
| `SUPER + CTRL + O` | Window Opacity | Toggle active window opacity |

### Waybar Controls
| Keybinding | Action | Description |
|------------|--------|-------------|
| `SUPER + CTRL + ALT + B` | Toggle Waybar | Hide/show waybar |
| `SUPER + CTRL + B` | Waybar Styles | Change waybar style |
| `SUPER + ALT + B` | Waybar Layout | Change waybar layout |

---

## 🔍 Search & Tools

| Keybinding | Action | Description |
|------------|--------|-------------|
| `SUPER + S` | Google Search | Search using Rofi |
| `SUPER + ALT + E` | Emoji Menu | Open emoji picker |
| `SUPER + ALT + V` | Clipboard | Clipboard manager |
| `SUPER + ALT + C` | Calculator | Open calculator |
| `SUPER + SHIFT + K` | Keybind Search | Search keybindings |

---

## 🎵 Entertainment & Themes

| Keybinding | Action | Description |
|------------|--------|-------------|
| `SUPER + SHIFT + M` | Music Player | Online music via Rofi |
| `SUPER + W` | Wallpaper Select | Choose wallpaper |
| `SUPER + SHIFT + W` | Wallpaper Effects | Apply wallpaper effects |
| `CTRL + ALT + W` | Random Wallpaper | Set random wallpaper |
| `SUPER + SHIFT + O` | ZSH Themes | Change terminal theme |

---

## 🎮 Advanced Features

### Rofi Themes
| Keybinding | Action | Description |
|------------|--------|-------------|
| `SUPER + CTRL + R` | Rofi Theme | Select Rofi theme |
| `SUPER + CTRL + SHIFT + R` | Modified Rofi | Modified theme selector |

### Desktop Zoom
| Keybinding | Action | Description |
|------------|--------|-------------|
| `SUPER + ALT + Mouse Up` | Zoom In | Increase cursor zoom |
| `SUPER + ALT + Mouse Down` | Zoom Out | Decrease cursor zoom |

### Window Cycling
| Keybinding | Action | Description |
|------------|--------|-------------|
| `ALT + Tab` | Cycle Windows | Cycle through windows |

### Mouse Actions
| Keybinding | Action | Description |
|------------|--------|-------------|
| `SUPER + Mouse Down` | Workspace Down | Next workspace (scroll) |
| `SUPER + Mouse Up` | Workspace Up | Previous workspace (scroll) |
| `SUPER + Left Click + Drag` | Move Window | Move window with mouse |
| `SUPER + Right Click + Drag` | Resize Window | Resize window with mouse |

---

## 🔧 Special Functions

### Keyboard Layout
| Keybinding | Action | Description |
|------------|--------|-------------|
| `ALT + SHIFT` | Switch Layout | Change keyboard layout |

### Special Terminals
| Keybinding | Action | Description |
|------------|--------|-------------|
| `SUPER + SHIFT + Return` | Dropdown Terminal | Floating terminal |

### Animations
| Keybinding | Action | Description |
|------------|--------|-------------|
| `SUPER + SHIFT + A` | Animation Menu | Configure animations |

---

## 💡 Tips

1. **Learning**: Use `SUPER + H` to see keybinding hints anytime
2. **Search**: Use `SUPER + SHIFT + K` to search for specific keybindings
3. **Customization**: Edit `~/.config/hypr/UserConfigs/UserKeybinds.conf` for personal keybindings
4. **Conflicts**: Check both main and user configs to avoid conflicts

---

## 🧪 Testing Your Keybindings

To test if your keybindings are working correctly, run:
```bash
./test_keybindings.sh
```

This will validate:
- ✅ Configuration file syntax
- ✅ Required scripts and applications
- ✅ Hyprland functionality
- ✅ Workspace management
- ✅ All dependencies

---

*Generated for HyprSupreme-Builder - The Ultimate Hyprland Configuration Suite*


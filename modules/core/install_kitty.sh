#!/bin/bash
# HyprSupreme-Builder - Kitty Terminal Installation Module

source "$(dirname "$0")/../common/functions.sh"

install_kitty() {
    log_info "Installing Kitty terminal and related packages..."
    
    # Kitty and dependencies
    local packages=(
        "kitty"
        "python-pillow"
        "imagemagick"
    )
    
    install_packages "${packages[@]}"
    
    # Create kitty config directory
    mkdir -p "$HOME/.config/kitty"
    
    # Create default kitty configuration
    create_default_kitty_config
    
    log_success "Kitty installation completed"
}

create_default_kitty_config() {
    log_info "Creating default Kitty configuration..."
    
    local config_file="$HOME/.config/kitty/kitty.conf"
    
    # Create main configuration
    cat > "$config_file" << 'EOF'
# HyprSupreme Kitty Configuration
# Based on Catppuccin Mocha theme

# Font configuration
font_family      JetBrainsMono Nerd Font
bold_font        JetBrainsMono Nerd Font Bold
italic_font      JetBrainsMono Nerd Font Italic
bold_italic_font JetBrainsMono Nerd Font Bold Italic
font_size        12.0

# Cursor configuration
cursor_shape               block
cursor_beam_thickness      1.5
cursor_underline_thickness 2.0
cursor_blink_interval      0.5
cursor_stop_blinking_after 15.0

# Scrollback
scrollback_lines 2000
scrollback_pager less --chop-long-lines --RAW-CONTROL-CHARS +INPUT_LINE_NUMBER
scrollback_pager_history_size 0
wheel_scroll_multiplier 5.0

# Mouse
mouse_hide_wait 3.0
url_color #89b4fa
url_style curly
open_url_modifiers kitty_mod
open_url_with default
url_prefixes http https file ftp
detect_urls yes

# Selection
copy_on_select no
strip_trailing_spaces never
select_by_word_characters @-./_~?&=%+#
click_interval -1.0
focus_follows_mouse no
pointer_shape_when_grabbed arrow

# Performance tuning
repaint_delay 10
input_delay 3
sync_to_monitor yes

# Terminal bell
enable_audio_bell no
visual_bell_duration 0.0
window_alert_on_bell yes
bell_on_tab yes
command_on_bell none

# Window layout
remember_window_size  yes
initial_window_width  640
initial_window_height 400
enabled_layouts *
window_resize_step_cells 2
window_resize_step_lines 2
window_border_width 0.5pt
draw_minimal_borders yes
window_margin_width 0
single_window_margin_width -1
window_padding_width 8
placement_strategy center
active_border_color #89b4fa
inactive_border_color #6c7086
bell_border_color #f9e2af
inactive_text_alpha 1.0

# Tab bar
tab_bar_edge bottom
tab_bar_margin_width 0.0
tab_bar_style powerline
tab_powerline_style slanted
tab_bar_min_tabs 2
tab_switch_strategy previous
tab_fade 0.25 0.5 0.75 1
tab_separator " ┇"
tab_title_template "{title}{' :{}:'.format(num_windows) if num_windows > 1 else ''}"
active_tab_title_template none
active_tab_foreground   #11111b
active_tab_background   #89b4fa
active_tab_font_style   bold-italic
inactive_tab_foreground #cdd6f4
inactive_tab_background #181825
inactive_tab_font_style normal

# Color scheme - Catppuccin Mocha
foreground #cdd6f4
background #1e1e2e
selection_foreground #1e1e2e
selection_background #f5e0dc

# Cursor colors
cursor #f5e0dc
cursor_text_color #1e1e2e

# URL underline color when hovering with mouse
url_color #89b4fa

# Kitty window border colors
active_border_color #b4befe
inactive_border_color #6c7086
bell_border_color #f9e2af

# OS Window titlebar colors
wayland_titlebar_color system
macos_titlebar_color system

# Tab bar colors
active_tab_foreground   #11111b
active_tab_background   #89b4fa
inactive_tab_foreground #cdd6f4
inactive_tab_background #181825
tab_bar_background      #11111b

# Colors for marks (marked text in the terminal)
mark1_foreground #1e1e2e
mark1_background #b4befe
mark2_foreground #1e1e2e
mark2_background #cba6f7
mark3_foreground #1e1e2e
mark3_background #74c7ec

# The 16 terminal colors

# normal
color0 #45475a
color1 #f38ba8
color2 #a6e3a1
color3 #f9e2af
color4 #89b4fa
color5 #f5c2e7
color6 #94e2d5
color7 #bac2de

# bright
color8  #585b70
color9  #f38ba8
color10 #a6e3a1
color11 #f9e2af
color12 #89b4fa
color13 #f5c2e7
color14 #94e2d5
color15 #a6adc8

# Advanced settings
shell .
editor .
close_on_child_death no
allow_remote_control no
update_check_interval 24
startup_session none
clipboard_control write-clipboard write-primary
allow_hyperlinks yes
shell_integration enabled
term xterm-kitty

# Keybindings
kitty_mod ctrl+shift

# Window management
map kitty_mod+enter new_window
map kitty_mod+n new_os_window
map kitty_mod+w close_window
map kitty_mod+] next_window
map kitty_mod+[ previous_window
map kitty_mod+f move_window_forward
map kitty_mod+b move_window_backward
map kitty_mod+` move_window_to_top
map kitty_mod+r start_resizing_window
map kitty_mod+1 first_window
map kitty_mod+2 second_window
map kitty_mod+3 third_window
map kitty_mod+4 fourth_window
map kitty_mod+5 fifth_window
map kitty_mod+6 sixth_window
map kitty_mod+7 seventh_window
map kitty_mod+8 eighth_window
map kitty_mod+9 ninth_window
map kitty_mod+0 tenth_window

# Tab management
map kitty_mod+right next_tab
map kitty_mod+left  previous_tab
map kitty_mod+t     new_tab
map kitty_mod+q     close_tab
map kitty_mod+.     move_tab_forward
map kitty_mod+,     move_tab_backward
map kitty_mod+alt+t set_tab_title

# Layout management
map kitty_mod+l next_layout

# Font sizes
map kitty_mod+equal  change_font_size all +2.0
map kitty_mod+minus  change_font_size all -2.0
map kitty_mod+0      change_font_size all 0

# Select and act on visible text
map kitty_mod+e kitten hints
map kitty_mod+p>f kitten hints --type path --program -
map kitty_mod+p>shift+f kitten hints --type path
map kitty_mod+p>l kitten hints --type line --program -
map kitty_mod+p>w kitten hints --type word --program -
map kitty_mod+p>h kitten hints --type hash --program -
map kitty_mod+p>n kitten hints --type linenum

# Miscellaneous
map kitty_mod+f11    toggle_fullscreen
map kitty_mod+f10    toggle_maximized
map kitty_mod+u      kitten unicode_input
map kitty_mod+f2     edit_config_file
map kitty_mod+escape kitty_shell window

# Clipboard
map kitty_mod+c copy_to_clipboard
map kitty_mod+v paste_from_clipboard
map kitty_mod+s paste_from_selection
map shift+insert paste_from_selection
map kitty_mod+o pass_selection_to_program

# Scrolling
map kitty_mod+up        scroll_line_up
map kitty_mod+k         scroll_line_up
map kitty_mod+down      scroll_line_down
map kitty_mod+j         scroll_line_down
map kitty_mod+page_up   scroll_page_up
map kitty_mod+page_down scroll_page_down
map kitty_mod+home      scroll_home
map kitty_mod+end       scroll_end
map kitty_mod+h         show_scrollback
EOF
    
    log_success "Default Kitty configuration created"
}

# Run if called directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    install_kitty
fi


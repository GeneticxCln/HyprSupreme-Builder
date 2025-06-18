#!/usr/bin/env python3
"""
HyprSupreme-Builder GUI Installer
Modern GTK4-based graphical installer with preview capabilities
"""

import gi
import os
import sys
import json
import threading
import subprocess
from pathlib import Path
from typing import Dict, List, Optional

gi.require_version('Gtk', '4.0')
gi.require_version('Adw', '1')

from gi.repository import Gtk, Adw, GLib, Gio, Gdk, GdkPixbuf

class HyprSupremeGUI(Adw.Application):
    def __init__(self):
        super().__init__(application_id='com.hyprsupreme.builder')
        self.main_window = None
        self.config = {
            'selected_configs': [],
            'selected_components': [],
            'selected_features': [],
            'preset': 'custom'
        }
        self.preview_mode = False
        
    def do_activate(self):
        if not self.main_window:
            self.main_window = HyprSupremeWindow(application=self)
        self.main_window.present()

class HyprSupremeWindow(Adw.ApplicationWindow):
    def __init__(self, **kwargs):
        super().__init__(**kwargs)
        
        self.set_title("HyprSupreme Builder")
        self.set_default_size(1200, 800)
        
        # Main layout
        self.setup_ui()
        
        # Load data
        self.load_configurations()
        
    def setup_ui(self):
        """Setup the main user interface"""
        # Header bar
        header = Adw.HeaderBar()
        header.set_title_widget(Adw.WindowTitle(title="HyprSupreme Builder", subtitle="Ultimate Hyprland Configuration"))
        
        # Menu button
        menu_button = Gtk.MenuButton()
        menu_button.set_icon_name("open-menu-symbolic")
        menu_button.set_tooltip_text("Main Menu")
        header.pack_end(menu_button)
        
        # Install button
        self.install_button = Gtk.Button(label="Install Configuration")
        self.install_button.add_css_class("suggested-action")
        self.install_button.connect("clicked", self.on_install_clicked)
        header.pack_end(self.install_button)
        
        # Preview toggle
        preview_toggle = Gtk.ToggleButton(label="Preview Mode")
        preview_toggle.connect("toggled", self.on_preview_toggled)
        header.pack_start(preview_toggle)
        
        self.set_titlebar(header)
        
        # Main content
        self.main_stack = Adw.ViewStack()
        
        # Welcome page
        self.setup_welcome_page()
        
        # Configuration pages
        self.setup_preset_page()
        self.setup_config_page()
        self.setup_component_page()
        self.setup_feature_page()
        self.setup_preview_page()
        self.setup_install_page()
        
        # Sidebar navigation
        self.setup_sidebar()
        
        # Main layout with sidebar
        self.main_content = Adw.OverlaySplitView()
        self.main_content.set_sidebar(self.sidebar)
        self.main_content.set_content(self.main_stack)
        self.main_content.set_sidebar_width_fraction(0.25)
        
        self.set_content(self.main_content)
        
    def setup_welcome_page(self):
        """Setup welcome/landing page"""
        welcome_page = Adw.StatusPage()
        welcome_page.set_icon_name("applications-system-symbolic")
        welcome_page.set_title("Welcome to HyprSupreme Builder")
        welcome_page.set_description("Build your ultimate Hyprland configuration by combining the best features from popular setups")
        
        # Feature cards
        features_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=20)
        features_box.set_halign(Gtk.Align.CENTER)
        features_box.set_margin_top(30)
        
        # JaKooLit card
        jakoolit_card = self.create_feature_card(
            "JaKooLit Setup",
            "Comprehensive package management & AGS integration",
            "dialog-information-symbolic"
        )
        
        # ML4W card  
        ml4w_card = self.create_feature_card(
            "ML4W Workflow",
            "Professional productivity tools & automation",
            "applications-office-symbolic"
        )
        
        # HyDE card
        hyde_card = self.create_feature_card(
            "HyDE Theming",
            "Dynamic themes & wallpaper-based colors",
            "applications-graphics-symbolic"
        )
        
        features_box.append(jakoolit_card)
        features_box.append(ml4w_card)
        features_box.append(hyde_card)
        
        # Get Started button
        start_button = Gtk.Button(label="Get Started")
        start_button.add_css_class("pill")
        start_button.add_css_class("suggested-action")
        start_button.set_halign(Gtk.Align.CENTER)
        start_button.set_margin_top(30)
        start_button.connect("clicked", lambda x: self.main_stack.set_visible_child_name("preset"))
        
        # Welcome content box
        welcome_content = Gtk.Box(orientation=Gtk.Orientation.VERTICAL)
        welcome_content.append(welcome_page)
        welcome_content.append(features_box)
        welcome_content.append(start_button)
        
        self.main_stack.add_titled(welcome_content, "welcome", "Welcome")
        
    def create_feature_card(self, title: str, description: str, icon: str) -> Gtk.Widget:
        """Create a feature showcase card"""
        card = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=10)
        card.add_css_class("card")
        card.set_size_request(200, 150)
        card.set_margin_top(10)
        card.set_margin_bottom(10)
        card.set_margin_start(10)
        card.set_margin_end(10)
        
        # Icon
        icon_widget = Gtk.Image.new_from_icon_name(icon)
        icon_widget.set_pixel_size(48)
        icon_widget.set_margin_top(20)
        
        # Title
        title_label = Gtk.Label(label=title)
        title_label.add_css_class("title-3")
        title_label.set_margin_top(10)
        
        # Description
        desc_label = Gtk.Label(label=description)
        desc_label.add_css_class("caption")
        desc_label.set_wrap(True)
        desc_label.set_margin_start(10)
        desc_label.set_margin_end(10)
        desc_label.set_margin_bottom(20)
        
        card.append(icon_widget)
        card.append(title_label)
        card.append(desc_label)
        
        return card
        
    def setup_preset_page(self):
        """Setup preset selection page"""
        preset_page = Adw.PreferencesPage()
        preset_page.set_title("Choose Preset")
        preset_page.set_description("Select a pre-configured setup or create custom")
        
        # Preset group
        preset_group = Adw.PreferencesGroup()
        preset_group.set_title("Configuration Presets")
        preset_group.set_description("Quick setup options optimized for different use cases")
        
        # Preset options
        presets = [
            ("showcase", "Showcase", "Maximum eye-candy with all effects", "applications-graphics-symbolic"),
            ("gaming", "Gaming", "Performance optimized for gaming", "applications-games-symbolic"), 
            ("work", "Productivity", "Professional workflow focused", "applications-office-symbolic"),
            ("minimal", "Minimal", "Lightweight essential features only", "applications-utilities-symbolic"),
            ("hybrid", "Hybrid", "Balanced mix of all configurations", "applications-system-symbolic"),
            ("custom", "Custom", "Manual selection of components", "preferences-other-symbolic")
        ]
        
        preset_radio_group = None
        for preset_id, name, desc, icon in presets:
            row = Adw.ActionRow()
            row.set_title(name)
            row.set_subtitle(desc)
            
            # Icon
            preset_icon = Gtk.Image.new_from_icon_name(icon)
            row.add_prefix(preset_icon)
            
            # Radio button
            radio = Gtk.CheckButton()
            if preset_radio_group is None:
                preset_radio_group = radio
            else:
                radio.set_group(preset_radio_group)
                
            radio.connect("toggled", self.on_preset_selected, preset_id)
            row.add_suffix(radio)
            
            if preset_id == "custom":
                radio.set_active(True)
                
            preset_group.add(row)
            
        preset_page.add(preset_group)
        self.main_stack.add_titled(preset_page, "preset", "Presets")
        
    def setup_config_page(self):
        """Setup configuration sources page"""
        config_page = Adw.PreferencesPage()
        config_page.set_title("Configuration Sources")
        config_page.set_description("Choose which configurations to integrate")
        
        # Config sources group
        config_group = Adw.PreferencesGroup()
        config_group.set_title("Available Configurations")
        
        configurations = [
            ("jakoolit", "JaKooLit's Setup", "Comprehensive Arch-Hyprland configuration with AGS", True),
            ("ml4w", "ML4W Dotfiles", "Professional workflow and productivity tools", False),
            ("hyde", "HyDE Configuration", "Dynamic theming and wallpaper system", False),
            ("end4", "End-4 Modern Setup", "Modern widgets and advanced animations", False),
            ("prasanta", "Prasanta Themes", "Beautiful themes and smooth transitions", False)
        ]
        
        self.config_switches = {}
        for config_id, name, desc, default in configurations:
            row = Adw.ActionRow()
            row.set_title(name)
            row.set_subtitle(desc)
            
            switch = Gtk.Switch()
            switch.set_active(default)
            switch.connect("state-set", self.on_config_toggled, config_id)
            row.add_suffix(switch)
            
            self.config_switches[config_id] = switch
            config_group.add(row)
            
        config_page.add(config_group)
        self.main_stack.add_titled(config_page, "configs", "Configurations")
        
    def setup_component_page(self):
        """Setup component selection page"""
        component_page = Adw.PreferencesPage()
        component_page.set_title("Components")
        component_page.set_description("Select components to install")
        
        # Core components
        core_group = Adw.PreferencesGroup()
        core_group.set_title("Core Components")
        
        core_components = [
            ("hyprland", "Hyprland", "Window manager", True),
            ("waybar", "Waybar", "Status bar", True),
            ("rofi", "Rofi", "Application launcher", True),
            ("kitty", "Kitty", "Terminal emulator", True)
        ]
        
        self.component_switches = {}
        for comp_id, name, desc, default in core_components:
            row = Adw.ActionRow()
            row.set_title(name)
            row.set_subtitle(desc)
            
            switch = Gtk.Switch()
            switch.set_active(default)
            switch.connect("state-set", self.on_component_toggled, comp_id)
            row.add_suffix(switch)
            
            self.component_switches[comp_id] = switch
            core_group.add(row)
            
        # Optional components
        optional_group = Adw.PreferencesGroup()
        optional_group.set_title("Optional Components")
        
        optional_components = [
            ("ags", "AGS Widgets", "Aylur's GTK Shell", False),
            ("sddm", "SDDM", "Display manager", False),
            ("themes", "Themes", "GTK and icon themes", True),
            ("fonts", "Fonts", "Font collection", True),
            ("wallpapers", "Wallpapers", "Wallpaper collection", True),
            ("scripts", "Scripts", "Utility scripts", True),
            ("nvidia", "NVIDIA", "NVIDIA optimizations", False)
        ]
        
        for comp_id, name, desc, default in optional_components:
            row = Adw.ActionRow()
            row.set_title(name)
            row.set_subtitle(desc)
            
            switch = Gtk.Switch()
            switch.set_active(default)
            switch.connect("state-set", self.on_component_toggled, comp_id)
            row.add_suffix(switch)
            
            self.component_switches[comp_id] = switch
            optional_group.add(row)
            
        component_page.add(core_group)
        component_page.add(optional_group)
        self.main_stack.add_titled(component_page, "components", "Components")
        
    def setup_feature_page(self):
        """Setup advanced features page"""
        feature_page = Adw.PreferencesPage()
        feature_page.set_title("Advanced Features")
        feature_page.set_description("Configure visual effects and optimizations")
        
        # Visual effects
        visual_group = Adw.PreferencesGroup()
        visual_group.set_title("Visual Effects")
        
        visual_features = [
            ("animations", "Animations", "Advanced animations and effects", True),
            ("blur", "Background Blur", "Blur effects for transparency", True),
            ("shadows", "Window Shadows", "Drop shadows for windows", True),
            ("rounded", "Rounded Corners", "Rounded window corners", True),
            ("transparency", "Transparency", "Window transparency effects", True)
        ]
        
        self.feature_switches = {}
        for feat_id, name, desc, default in visual_features:
            row = Adw.ActionRow()
            row.set_title(name)
            row.set_subtitle(desc)
            
            switch = Gtk.Switch()
            switch.set_active(default)
            switch.connect("state-set", self.on_feature_toggled, feat_id)
            row.add_suffix(switch)
            
            self.feature_switches[feat_id] = switch
            visual_group.add(row)
            
        # System features
        system_group = Adw.PreferencesGroup()
        system_group.set_title("System Features")
        
        system_features = [
            ("workspace_swipe", "Workspace Gestures", "Gesture navigation between workspaces", True),
            ("auto_theme", "Auto Theme Switching", "Automatic theme changes", False),
            ("performance", "Performance Mode", "Optimize for performance", True)
        ]
        
        for feat_id, name, desc, default in system_features:
            row = Adw.ActionRow()
            row.set_title(name)
            row.set_subtitle(desc)
            
            switch = Gtk.Switch()
            switch.set_active(default)
            switch.connect("state-set", self.on_feature_toggled, feat_id)
            row.add_suffix(switch)
            
            self.feature_switches[feat_id] = switch
            system_group.add(row)
            
        feature_page.add(visual_group)
        feature_page.add(system_group)
        self.main_stack.add_titled(feature_page, "features", "Features")
        
    def setup_preview_page(self):
        """Setup configuration preview page"""
        preview_page = Adw.PreferencesPage()
        preview_page.set_title("Preview")
        preview_page.set_description("Preview your configuration before installation")
        
        # Configuration summary
        summary_group = Adw.PreferencesGroup()
        summary_group.set_title("Configuration Summary")
        
        self.summary_labels = {
            'configs': Adw.ActionRow(),
            'components': Adw.ActionRow(),
            'features': Adw.ActionRow()
        }
        
        self.summary_labels['configs'].set_title("Selected Configurations")
        self.summary_labels['components'].set_title("Selected Components") 
        self.summary_labels['features'].set_title("Selected Features")
        
        for row in self.summary_labels.values():
            summary_group.add(row)
            
        # Live preview (placeholder)
        preview_group = Adw.PreferencesGroup()
        preview_group.set_title("Live Preview")
        
        preview_placeholder = Adw.ActionRow()
        preview_placeholder.set_title("Desktop Preview")
        preview_placeholder.set_subtitle("Preview functionality coming soon")
        preview_group.add(preview_placeholder)
        
        preview_page.add(summary_group)
        preview_page.add(preview_group)
        self.main_stack.add_titled(preview_page, "preview", "Preview")
        
    def setup_install_page(self):
        """Setup installation progress page"""
        install_page = Adw.StatusPage()
        install_page.set_icon_name("emblem-synchronizing-symbolic")
        install_page.set_title("Installing HyprSupreme")
        install_page.set_description("Please wait while we install your configuration...")
        
        # Progress bar
        self.progress_bar = Gtk.ProgressBar()
        self.progress_bar.set_margin_start(50)
        self.progress_bar.set_margin_end(50)
        self.progress_bar.set_margin_top(20)
        
        # Status label
        self.status_label = Gtk.Label(label="Preparing installation...")
        self.status_label.set_margin_top(10)
        
        # Install content
        install_content = Gtk.Box(orientation=Gtk.Orientation.VERTICAL)
        install_content.append(install_page)
        install_content.append(self.progress_bar)
        install_content.append(self.status_label)
        
        self.main_stack.add_titled(install_content, "install", "Installing")
        
    def setup_sidebar(self):
        """Setup navigation sidebar"""
        self.sidebar = Gtk.Box(orientation=Gtk.Orientation.VERTICAL)
        self.sidebar.add_css_class("sidebar")
        
        # Sidebar header
        sidebar_header = Adw.HeaderBar()
        sidebar_header.add_css_class("flat")
        
        # Logo/title
        title_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=8)
        logo = Gtk.Image.new_from_icon_name("applications-system-symbolic")
        title_label = Gtk.Label(label="HyprSupreme")
        title_label.add_css_class("title-4")
        title_box.append(logo)
        title_box.append(title_label)
        
        sidebar_header.set_title_widget(title_box)
        self.sidebar.append(sidebar_header)
        
        # Navigation stack switcher
        self.stack_switcher = Adw.ViewSwitcherBar()
        self.stack_switcher.set_stack(self.main_stack)
        self.sidebar.append(self.stack_switcher)
        
        # Cloud sync section (placeholder)
        cloud_group = Adw.PreferencesGroup()
        cloud_group.set_title("Cloud Sync")
        cloud_group.set_margin_top(20)
        
        sync_row = Adw.ActionRow()
        sync_row.set_title("Sync Configurations")
        sync_row.set_subtitle("Save to cloud")
        
        sync_button = Gtk.Button(label="Connect")
        sync_button.add_css_class("flat")
        sync_button.connect("clicked", self.on_cloud_sync)
        sync_row.add_suffix(sync_button)
        
        cloud_group.add(sync_row)
        self.sidebar.append(cloud_group)
        
    def load_configurations(self):
        """Load available configurations and update UI"""
        # This would load from actual config files
        pass
        
    def update_preview(self):
        """Update the preview with current selections"""
        configs = [k for k, v in self.config_switches.items() if v.get_active()]
        components = [k for k, v in self.component_switches.items() if v.get_active()]
        features = [k for k, v in self.feature_switches.items() if v.get_active()]
        
        self.summary_labels['configs'].set_subtitle(f"{len(configs)} selected: {', '.join(configs)}")
        self.summary_labels['components'].set_subtitle(f"{len(components)} selected: {', '.join(components)}")
        self.summary_labels['features'].set_subtitle(f"{len(features)} selected: {', '.join(features)}")
        
    def on_preset_selected(self, radio, preset_id):
        """Handle preset selection"""
        if radio.get_active():
            self.config['preset'] = preset_id
            self.load_preset(preset_id)
            
    def load_preset(self, preset_id):
        """Load preset configuration"""
        preset_configs = {
            'showcase': {
                'configs': ['jakoolit', 'hyde', 'end4', 'prasanta'],
                'components': ['hyprland', 'waybar', 'rofi', 'kitty', 'ags', 'sddm', 'themes', 'fonts', 'wallpapers', 'scripts'],
                'features': ['animations', 'blur', 'shadows', 'rounded', 'transparency', 'workspace_swipe', 'auto_theme']
            },
            'gaming': {
                'configs': ['jakoolit', 'ml4w'],
                'components': ['hyprland', 'waybar', 'rofi', 'kitty', 'themes', 'fonts', 'scripts'],
                'features': ['performance', 'workspace_swipe']
            },
            'work': {
                'configs': ['ml4w', 'jakoolit'],
                'components': ['hyprland', 'waybar', 'rofi', 'kitty', 'themes', 'fonts', 'scripts'],
                'features': ['rounded', 'transparency', 'workspace_swipe', 'performance']
            },
            'minimal': {
                'configs': ['jakoolit'],
                'components': ['hyprland', 'waybar', 'rofi', 'kitty', 'fonts'],
                'features': ['performance']
            },
            'hybrid': {
                'configs': ['jakoolit', 'ml4w', 'hyde'],
                'components': ['hyprland', 'waybar', 'rofi', 'kitty', 'ags', 'themes', 'fonts', 'wallpapers', 'scripts'],
                'features': ['animations', 'blur', 'rounded', 'transparency', 'workspace_swipe']
            }
        }
        
        if preset_id in preset_configs:
            preset = preset_configs[preset_id]
            
            # Update switches
            for config_id, switch in self.config_switches.items():
                switch.set_active(config_id in preset['configs'])
                
            for comp_id, switch in self.component_switches.items():
                switch.set_active(comp_id in preset['components'])
                
            for feat_id, switch in self.feature_switches.items():
                switch.set_active(feat_id in preset['features'])
                
            self.update_preview()
        
    def on_config_toggled(self, switch, state, config_id):
        """Handle configuration toggle"""
        if state:
            if config_id not in self.config['selected_configs']:
                self.config['selected_configs'].append(config_id)
        else:
            if config_id in self.config['selected_configs']:
                self.config['selected_configs'].remove(config_id)
        self.update_preview()
        
    def on_component_toggled(self, switch, state, comp_id):
        """Handle component toggle"""
        if state:
            if comp_id not in self.config['selected_components']:
                self.config['selected_components'].append(comp_id)
        else:
            if comp_id in self.config['selected_components']:
                self.config['selected_components'].remove(comp_id)
        self.update_preview()
        
    def on_feature_toggled(self, switch, state, feat_id):
        """Handle feature toggle"""
        if state:
            if feat_id not in self.config['selected_features']:
                self.config['selected_features'].append(feat_id)
        else:
            if feat_id in self.config['selected_features']:
                self.config['selected_features'].remove(feat_id)
        self.update_preview()
        
    def on_preview_toggled(self, toggle):
        """Handle preview mode toggle"""
        self.preview_mode = toggle.get_active()
        # Would implement live preview here
        
    def on_cloud_sync(self, button):
        """Handle cloud sync button"""
        dialog = Adw.MessageDialog.new(self, "Cloud Sync", "Cloud sync functionality will be available in a future update.")
        dialog.add_response("ok", "OK")
        dialog.present()
        
    def on_install_clicked(self, button):
        """Handle install button click"""
        self.main_stack.set_visible_child_name("install")
        self.start_installation()
        
    def start_installation(self):
        """Start the installation process"""
        def run_installation():
            # Build command arguments
            configs = [k for k, v in self.config_switches.items() if v.get_active()]
            components = [k for k, v in self.component_switches.items() if v.get_active()]
            features = [k for k, v in self.feature_switches.items() if v.get_active()]
            
            # Update UI on main thread
            GLib.idle_add(self.update_progress, 0.1, "Preparing installation...")
            
            try:
                # Run the actual installer
                base_dir = Path(__file__).parent.parent
                install_script = base_dir / "install.sh"
                
                if self.config['preset'] != 'custom':
                    cmd = [str(install_script), "--preset", self.config['preset']]
                else:
                    cmd = [str(install_script), "--gui-mode"]
                    # Would pass selected options via environment or temp file
                
                GLib.idle_add(self.update_progress, 0.3, "Installing components...")
                
                # Run installation
                process = subprocess.run(cmd, capture_output=True, text=True, cwd=str(base_dir))
                
                GLib.idle_add(self.update_progress, 0.8, "Finalizing installation...")
                
                if process.returncode == 0:
                    GLib.idle_add(self.installation_complete, True, "Installation completed successfully!")
                else:
                    GLib.idle_add(self.installation_complete, False, f"Installation failed: {process.stderr}")
                    
            except Exception as e:
                GLib.idle_add(self.installation_complete, False, f"Installation error: {str(e)}")
        
        # Run installation in background thread
        thread = threading.Thread(target=run_installation)
        thread.daemon = True
        thread.start()
        
    def update_progress(self, fraction, status):
        """Update installation progress"""
        self.progress_bar.set_fraction(fraction)
        self.status_label.set_text(status)
        return False  # Don't repeat
        
    def installation_complete(self, success, message):
        """Handle installation completion"""
        if success:
            dialog = Adw.MessageDialog.new(self, "Installation Complete", message)
            dialog.add_response("restart", "Restart Now")
            dialog.add_response("later", "Restart Later")
            dialog.set_default_response("restart")
            dialog.connect("response", self.on_installation_dialog_response)
        else:
            dialog = Adw.MessageDialog.new(self, "Installation Failed", message)
            dialog.add_response("ok", "OK")
            
        dialog.present()
        return False  # Don't repeat
        
    def on_installation_dialog_response(self, dialog, response):
        """Handle installation dialog response"""
        if response == "restart":
            subprocess.run(["systemctl", "reboot"])
        dialog.close()

def main():
    """Main entry point"""
    # Ensure we're in the right directory
    script_dir = Path(__file__).parent.parent
    os.chdir(script_dir)
    
    app = HyprSupremeGUI()
    return app.run(sys.argv)

if __name__ == "__main__":
    main()


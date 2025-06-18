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
import tempfile
import time
from pathlib import Path
from typing import Dict, List, Optional, Tuple
from dataclasses import dataclass
import yaml

gi.require_version('Gtk', '4.0')
gi.require_version('Adw', '1')
gi.require_version('WebKit', '6.0')

from gi.repository import Gtk, Adw, GLib, Gio, Gdk, GdkPixbuf, WebKit

@dataclass
class ConfigPreview:
    """Data class for preview information"""
    wallpaper: str = ""
    colorscheme: str = ""
    theme: str = ""
    effects: Dict[str, bool] = None
    components: List[str] = None
    
    def __post_init__(self):
        if self.effects is None:
            self.effects = {}
        if self.components is None:
            self.components = []

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
        self.preview_data = ConfigPreview()
        self.preview_templates = self.load_preview_templates()
        self.component_impacts = self.load_component_impacts()
        
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
        """Setup advanced configuration preview page"""
        # Main preview container with paned layout
        preview_paned = Gtk.Paned(orientation=Gtk.Orientation.HORIZONTAL)
        preview_paned.set_position(600)
        preview_paned.set_resize_start_child(True)
        preview_paned.set_resize_end_child(True)
        
        # Left side - Configuration summary and controls
        left_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL)
        left_box.set_spacing(10)
        left_box.set_margin_start(10)
        left_box.set_margin_end(10)
        left_box.set_margin_top(10)
        left_box.set_margin_bottom(10)
        
        # Preview controls
        controls_group = Adw.PreferencesGroup()
        controls_group.set_title("Preview Controls")
        
        # Preview mode selector
        preview_mode_row = Adw.ComboRow()
        preview_mode_row.set_title("Preview Mode")
        preview_mode_row.set_subtitle("Choose what to preview")
        
        preview_modes = Gtk.StringList()
        preview_modes.append("Desktop Overview")
        preview_modes.append("Component Impact")
        preview_modes.append("Theme Comparison")
        preview_modes.append("Performance Impact")
        preview_mode_row.set_model(preview_modes)
        preview_mode_row.connect("notify::selected", self.on_preview_mode_changed)
        controls_group.add(preview_mode_row)
        
        # Live update toggle
        live_update_row = Adw.ActionRow()
        live_update_row.set_title("Live Updates")
        live_update_row.set_subtitle("Auto-update preview on changes")
        self.live_update_switch = Gtk.Switch()
        self.live_update_switch.set_active(True)
        live_update_row.add_suffix(self.live_update_switch)
        controls_group.add(live_update_row)
        
        left_box.append(controls_group)
        
        # Configuration summary
        summary_group = Adw.PreferencesGroup()
        summary_group.set_title("Configuration Summary")
        
        self.summary_labels = {
            'preset': Adw.ActionRow(),
            'configs': Adw.ActionRow(),
            'components': Adw.ActionRow(),
            'features': Adw.ActionRow(),
            'estimated_size': Adw.ActionRow(),
            'install_time': Adw.ActionRow()
        }
        
        self.summary_labels['preset'].set_title("Active Preset")
        self.summary_labels['configs'].set_title("Configurations")
        self.summary_labels['components'].set_title("Components") 
        self.summary_labels['features'].set_title("Visual Features")
        self.summary_labels['estimated_size'].set_title("Estimated Download")
        self.summary_labels['install_time'].set_title("Estimated Install Time")
        
        for row in self.summary_labels.values():
            summary_group.add(row)
            
        left_box.append(summary_group)
        
        # Component impact analysis
        impact_group = Adw.PreferencesGroup()
        impact_group.set_title("Component Impact Analysis")
        
        self.impact_list = Gtk.ListBox()
        self.impact_list.set_selection_mode(Gtk.SelectionMode.NONE)
        self.impact_list.add_css_class("boxed-list")
        impact_group.add(self.impact_list)
        
        left_box.append(impact_group)
        
        preview_paned.set_start_child(left_box)
        
        # Right side - Visual preview area
        right_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL)
        right_box.set_spacing(10)
        right_box.set_margin_start(10)
        right_box.set_margin_end(10)
        right_box.set_margin_top(10)
        right_box.set_margin_bottom(10)
        
        # Preview header
        preview_header = Adw.HeaderBar()
        preview_header.add_css_class("flat")
        preview_title = Adw.WindowTitle(title="Live Preview", subtitle="Desktop visualization")
        preview_header.set_title_widget(preview_title)
        
        # Preview toolbar
        preview_toolbar = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=5)
        preview_toolbar.set_halign(Gtk.Align.END)
        
        # Refresh button
        refresh_btn = Gtk.Button.new_from_icon_name("view-refresh-symbolic")
        refresh_btn.set_tooltip_text("Refresh Preview")
        refresh_btn.connect("clicked", self.refresh_preview)
        preview_toolbar.append(refresh_btn)
        
        # Screenshot button
        screenshot_btn = Gtk.Button.new_from_icon_name("applets-screenshooter-symbolic")
        screenshot_btn.set_tooltip_text("Save Preview")
        screenshot_btn.connect("clicked", self.save_preview)
        preview_toolbar.append(screenshot_btn)
        
        preview_header.pack_end(preview_toolbar)
        right_box.append(preview_header)
        
        # Preview stack for different view modes
        self.preview_stack = Adw.ViewStack()
        
        # Desktop preview (WebKit view for rich content)
        self.desktop_preview = self.create_desktop_preview()
        self.preview_stack.add_titled(self.desktop_preview, "desktop", "Desktop")
        
        # Component preview
        self.component_preview = self.create_component_preview()
        self.preview_stack.add_titled(self.component_preview, "components", "Components")
        
        # Theme comparison
        self.theme_preview = self.create_theme_preview()
        self.preview_stack.add_titled(self.theme_preview, "themes", "Themes")
        
        # Performance preview
        self.performance_preview = self.create_performance_preview()
        self.preview_stack.add_titled(self.performance_preview, "performance", "Performance")
        
        right_box.append(self.preview_stack)
        
        preview_paned.set_end_child(right_box)
        
        self.main_stack.add_titled(preview_paned, "preview", "Preview")
        
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
        
    # Preview functionality methods
    def load_preview_templates(self) -> Dict[str, str]:
        """Load HTML templates for preview rendering"""
        templates = {
            'desktop': '''
            <!DOCTYPE html>
            <html>
            <head>
                <style>
                    body { margin: 0; padding: 20px; font-family: 'Inter', sans-serif; background: linear-gradient(135deg, {bg_color_1}, {bg_color_2}); }
                    .desktop { width: 800px; height: 600px; position: relative; border-radius: 12px; overflow: hidden; box-shadow: 0 20px 40px rgba(0,0,0,0.3); }
                    .wallpaper { width: 100%; height: 100%; background-image: url('{wallpaper}'); background-size: cover; background-position: center; }
                    .bar { position: absolute; top: 0; left: 0; right: 0; height: 40px; background: rgba(0,0,0,0.8); backdrop-filter: blur(10px); display: flex; align-items: center; padding: 0 15px; color: white; }
                    .window { position: absolute; background: rgba(255,255,255,{transparency}); border-radius: {corner_radius}px; backdrop-filter: blur({blur_strength}px); box-shadow: 0 8px 16px rgba(0,0,0,0.2); }
                    .window.terminal { width: 400px; height: 300px; top: 150px; left: 200px; background: rgba(30,30,30,0.9); color: #00ff41; }
                    .window.browser { width: 500px; height: 350px; top: 100px; left: 100px; }
                    .effects-overlay { position: absolute; inset: 0; background: radial-gradient(circle at 50% 50%, transparent 40%, rgba({accent_r},{accent_g},{accent_b},0.1) 100%); }
                </style>
            </head>
            <body>
                <div class="desktop">
                    <div class="wallpaper"></div>
                    <div class="bar">
                        <span>🏠 Workspace 1</span>
                        <div style="margin-left: auto;">🔊 📶 🔋 {time}</div>
                    </div>
                    <div class="window browser"></div>
                    <div class="window terminal">
                        <div style="padding: 10px; font-family: monospace;">$ neofetch<br/>user@hyprland<br/>--------------<br/>OS: Arch Linux<br/>WM: Hyprland</div>
                    </div>
                    <div class="effects-overlay"></div>
                </div>
            </body>
            </html>
            ''',
            'component_graph': '''
            <!DOCTYPE html>
            <html>
            <head>
                <script src="https://d3js.org/d3.v7.min.js"></script>
                <style>
                    body { margin: 0; padding: 20px; background: #1a1a1a; color: white; font-family: 'Inter', sans-serif; }
                    .node { cursor: pointer; }
                    .link { stroke: #666; stroke-width: 2px; }
                    .tooltip { position: absolute; background: rgba(0,0,0,0.9); padding: 10px; border-radius: 8px; pointer-events: none; }
                </style>
            </head>
            <body>
                <div id="graph"></div>
                <script>
                    // Component dependency visualization would go here
                    const data = {component_data};
                    // D3.js graph rendering logic
                </script>
            </body>
            </html>
            '''
        }
        return templates
        
    def load_component_impacts(self) -> Dict[str, Dict]:
        """Load component impact data for analysis"""
        return {
            'hyprland': {
                'memory': 50,  # MB
                'startup_time': 0.8,  # seconds
                'features': ['window_management', 'animations'],
                'dependencies': ['wayland', 'mesa']
            },
            'waybar': {
                'memory': 25,
                'startup_time': 0.3,
                'features': ['status_bar', 'widgets'],
                'dependencies': ['gtk3', 'gtkmm']
            },
            'ags': {
                'memory': 80,
                'startup_time': 1.2,
                'features': ['widgets', 'animations', 'customization'],
                'dependencies': ['gjs', 'gtk4']
            },
            'blur': {
                'memory': 20,
                'gpu_usage': 15,  # percent
                'features': ['transparency_effects'],
                'performance_impact': 'medium'
            },
            'animations': {
                'memory': 10,
                'gpu_usage': 25,
                'features': ['visual_effects'],
                'performance_impact': 'high'
            }
        }
        
    def create_desktop_preview(self) -> Gtk.Widget:
        """Create desktop preview widget with WebKit"""
        scroll = Gtk.ScrolledWindow()
        scroll.set_policy(Gtk.PolicyType.AUTOMATIC, Gtk.PolicyType.AUTOMATIC)
        
        self.webkit_view = WebKit.WebView()
        self.webkit_view.set_size_request(800, 600)
        
        # Enable developer tools and modern features
        settings = self.webkit_view.get_settings()
        settings.set_enable_developer_extras(True)
        settings.set_enable_webgl(True)
        settings.set_hardware_acceleration_policy(WebKit.HardwareAccelerationPolicy.ALWAYS)
        
        scroll.set_child(self.webkit_view)
        return scroll
        
    def create_component_preview(self) -> Gtk.Widget:
        """Create component impact visualization"""
        box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=10)
        
        # Component list with impact indicators
        component_scroll = Gtk.ScrolledWindow()
        component_scroll.set_policy(Gtk.PolicyType.NEVER, Gtk.PolicyType.AUTOMATIC)
        component_scroll.set_min_content_height(400)
        
        self.component_list = Gtk.ListBox()
        self.component_list.set_selection_mode(Gtk.SelectionMode.NONE)
        self.component_list.add_css_class("boxed-list")
        
        component_scroll.set_child(self.component_list)
        box.append(component_scroll)
        
        # Impact summary
        summary_frame = Gtk.Frame()
        summary_frame.set_label("System Impact Summary")
        
        self.impact_summary = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=5)
        self.impact_summary.set_margin_start(10)
        self.impact_summary.set_margin_end(10)
        self.impact_summary.set_margin_top(10)
        self.impact_summary.set_margin_bottom(10)
        
        summary_frame.set_child(self.impact_summary)
        box.append(summary_frame)
        
        return box
        
    def create_theme_preview(self) -> Gtk.Widget:
        """Create theme comparison preview"""
        paned = Gtk.Paned(orientation=Gtk.Orientation.HORIZONTAL)
        paned.set_position(400)
        
        # Before preview
        before_frame = Gtk.Frame()
        before_frame.set_label("Current/Default")
        self.before_preview = Gtk.Picture()
        self.before_preview.set_size_request(400, 300)
        before_frame.set_child(self.before_preview)
        
        # After preview
        after_frame = Gtk.Frame()
        after_frame.set_label("With Selected Configuration")
        self.after_preview = Gtk.Picture()
        self.after_preview.set_size_request(400, 300)
        after_frame.set_child(self.after_preview)
        
        paned.set_start_child(before_frame)
        paned.set_end_child(after_frame)
        
        return paned
        
    def create_performance_preview(self) -> Gtk.Widget:
        """Create performance impact visualization"""
        box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=15)
        
        # Performance metrics
        metrics_group = Adw.PreferencesGroup()
        metrics_group.set_title("Performance Metrics")
        
        # Memory usage
        memory_row = Adw.ActionRow()
        memory_row.set_title("Memory Usage")
        self.memory_bar = Gtk.ProgressBar()
        self.memory_bar.set_hexpand(True)
        self.memory_label = Gtk.Label()
        memory_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=10)
        memory_box.append(self.memory_bar)
        memory_box.append(self.memory_label)
        memory_row.add_suffix(memory_box)
        metrics_group.add(memory_row)
        
        # GPU usage
        gpu_row = Adw.ActionRow()
        gpu_row.set_title("GPU Usage")
        self.gpu_bar = Gtk.ProgressBar()
        self.gpu_bar.set_hexpand(True)
        self.gpu_label = Gtk.Label()
        gpu_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=10)
        gpu_box.append(self.gpu_bar)
        gpu_box.append(self.gpu_label)
        gpu_row.add_suffix(gpu_box)
        metrics_group.add(gpu_row)
        
        # Startup time
        startup_row = Adw.ActionRow()
        startup_row.set_title("Startup Time")
        self.startup_label = Gtk.Label()
        startup_row.add_suffix(self.startup_label)
        metrics_group.add(startup_row)
        
        box.append(metrics_group)
        
        # Performance recommendations
        recommendations_group = Adw.PreferencesGroup()
        recommendations_group.set_title("Performance Recommendations")
        
        self.recommendations_list = Gtk.ListBox()
        self.recommendations_list.set_selection_mode(Gtk.SelectionMode.NONE)
        self.recommendations_list.add_css_class("boxed-list")
        
        recommendations_group.add(self.recommendations_list)
        box.append(recommendations_group)
        
        return box
        
    def on_preview_mode_changed(self, combo, *args):
        """Handle preview mode change"""
        selected = combo.get_selected()
        modes = ["desktop", "components", "themes", "performance"]
        if selected < len(modes):
            self.preview_stack.set_visible_child_name(modes[selected])
            self.update_preview_content(modes[selected])
            
    def update_preview_content(self, mode: str):
        """Update preview content based on mode"""
        if not self.live_update_switch.get_active():
            return
            
        if mode == "desktop":
            self.update_desktop_preview()
        elif mode == "components":
            self.update_component_preview()
        elif mode == "themes":
            self.update_theme_preview()
        elif mode == "performance":
            self.update_performance_preview()
            
    def update_desktop_preview(self):
        """Update desktop visualization"""
        # Gather current configuration
        configs = [k for k, v in self.config_switches.items() if v.get_active()]
        features = [k for k, v in self.feature_switches.items() if v.get_active()]
        
        # Generate color scheme based on selections
        color_schemes = {
            'hyde': ('#1a1a2e', '#16213e', '#0f4c75'),
            'jakoolit': ('#0d1117', '#161b22', '#21262d'),
            'ml4w': ('#282a36', '#44475a', '#6272a4'),
            'default': ('#1e1e2e', '#313244', '#45475a')
        }
        
        primary_config = configs[0] if configs else 'default'
        bg_colors = color_schemes.get(primary_config, color_schemes['default'])
        
        # Calculate effect values
        transparency = 0.9 if 'transparency' in features else 0.95
        corner_radius = 12 if 'rounded' in features else 2
        blur_strength = 20 if 'blur' in features else 0
        
        # Generate HTML content
        html_content = self.preview_templates['desktop'].format(
            bg_color_1=bg_colors[0],
            bg_color_2=bg_colors[1],
            wallpaper=self.get_wallpaper_for_config(primary_config),
            transparency=transparency,
            corner_radius=corner_radius,
            blur_strength=blur_strength,
            accent_r=100, accent_g=149, accent_b=237,  # Default accent
            time=time.strftime("%H:%M")
        )
        
        self.webkit_view.load_html(html_content, "file:///")
        
    def update_component_preview(self):
        """Update component impact visualization"""
        # Clear existing components
        while child := self.component_list.get_first_child():
            self.component_list.remove(child)
            
        # Get selected components
        selected_components = [k for k, v in self.component_switches.items() if v.get_active()]
        selected_features = [k for k, v in self.feature_switches.items() if v.get_active()]
        
        all_selected = selected_components + selected_features
        
        total_memory = 0
        total_gpu_usage = 0
        total_startup = 0
        
        for comp_id in all_selected:
            if comp_id not in self.component_impacts:
                continue
                
            impact = self.component_impacts[comp_id]
            
            # Create component row
            row = Adw.ActionRow()
            row.set_title(comp_id.title().replace('_', ' '))
            
            # Memory usage
            memory = impact.get('memory', 0)
            total_memory += memory
            
            # GPU usage
            gpu = impact.get('gpu_usage', 0)
            total_gpu_usage += gpu
            
            # Startup time
            startup = impact.get('startup_time', 0)
            total_startup += startup
            
            # Impact level indicator
            impact_level = impact.get('performance_impact', 'low')
            impact_colors = {
                'low': 'success',
                'medium': 'warning',
                'high': 'error'
            }
            
            impact_pill = Gtk.Label(label=impact_level.title())
            impact_pill.add_css_class('pill')
            impact_pill.add_css_class(impact_colors.get(impact_level, 'neutral'))
            
            info_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=10)
            if memory > 0:
                mem_label = Gtk.Label(label=f"{memory}MB")
                mem_label.add_css_class('caption')
                info_box.append(mem_label)
            
            info_box.append(impact_pill)
            row.add_suffix(info_box)
            
            self.component_list.append(row)
            
        # Update summary
        while child := self.impact_summary.get_first_child():
            self.impact_summary.remove(child)
            
        summary_items = [
            f"Total Memory: {total_memory}MB",
            f"GPU Usage: {total_gpu_usage}%",
            f"Startup Time: {total_startup:.1f}s",
            f"Components: {len(all_selected)}"
        ]
        
        for item in summary_items:
            label = Gtk.Label(label=item)
            label.set_halign(Gtk.Align.START)
            self.impact_summary.append(label)
            
    def update_theme_preview(self):
        """Update theme comparison preview"""
        # Generate before/after preview images
        configs = [k for k, v in self.config_switches.items() if v.get_active()]
        
        # Load sample images (would be actual screenshots in production)
        default_image = self.create_sample_desktop_image("default")
        configured_image = self.create_sample_desktop_image(configs[0] if configs else "custom")
        
        # Set preview images
        self.before_preview.set_paintable(default_image)
        self.after_preview.set_paintable(configured_image)
        
    def update_performance_preview(self):
        """Update performance metrics preview"""
        selected_components = [k for k, v in self.component_switches.items() if v.get_active()]
        selected_features = [k for k, v in self.feature_switches.items() if v.get_active()]
        
        all_selected = selected_components + selected_features
        
        # Calculate metrics
        total_memory = sum(self.component_impacts.get(comp, {}).get('memory', 0) for comp in all_selected)
        total_gpu = sum(self.component_impacts.get(comp, {}).get('gpu_usage', 0) for comp in all_selected)
        total_startup = sum(self.component_impacts.get(comp, {}).get('startup_time', 0) for comp in all_selected)
        
        # Update progress bars
        self.memory_bar.set_fraction(min(total_memory / 1000, 1.0))  # Assume 1GB max
        self.memory_label.set_text(f"{total_memory}MB")
        
        self.gpu_bar.set_fraction(min(total_gpu / 100, 1.0))
        self.gpu_label.set_text(f"{total_gpu}%")
        
        self.startup_label.set_text(f"{total_startup:.1f}s")
        
        # Generate recommendations
        self.update_performance_recommendations(total_memory, total_gpu, total_startup)
        
    def update_performance_recommendations(self, memory: int, gpu: int, startup: float):
        """Generate performance recommendations"""
        # Clear existing recommendations
        while child := self.recommendations_list.get_first_child():
            self.recommendations_list.remove(child)
            
        recommendations = []
        
        if memory > 500:
            recommendations.append(("High memory usage detected", "Consider disabling some visual effects", "warning"))
            
        if gpu > 50:
            recommendations.append(("High GPU usage", "Disable animations or blur for better performance", "error"))
            
        if startup > 3.0:
            recommendations.append(("Slow startup time", "Reduce the number of startup components", "warning"))
            
        if not recommendations:
            recommendations.append(("Optimal performance", "Your configuration looks good!", "success"))
            
        for title, desc, level in recommendations:
            row = Adw.ActionRow()
            row.set_title(title)
            row.set_subtitle(desc)
            
            icon_names = {
                'success': 'emblem-ok-symbolic',
                'warning': 'dialog-warning-symbolic',
                'error': 'dialog-error-symbolic'
            }
            
            icon = Gtk.Image.new_from_icon_name(icon_names.get(level, 'dialog-information-symbolic'))
            row.add_prefix(icon)
            
            self.recommendations_list.append(row)
            
    def get_wallpaper_for_config(self, config: str) -> str:
        """Get wallpaper URL for configuration"""
        wallpapers = {
            'hyde': 'data:image/svg+xml;base64,PHN2ZyB3aWR0aD0iODAwIiBoZWlnaHQ9IjYwMCIgeG1sbnM9Imh0dHA6Ly93d3cudzMub3JnLzIwMDAvc3ZnIj48ZGVmcz48bGluZWFyR3JhZGllbnQgaWQ9ImEiIHgxPSIwJSIgeTE9IjAlIiB4Mj0iMTAwJSIgeTI9IjEwMCUiPjxzdG9wIG9mZnNldD0iMCUiIHN0b3AtY29sb3I9IiMxYTFhMmUiLz48c3RvcCBvZmZzZXQ9IjEwMCUiIHN0b3AtY29sb3I9IiMwZjRjNzUiLz48L2xpbmVhckdyYWRpZW50PjwvZGVmcz48cmVjdCB3aWR0aD0iMTAwJSIgaGVpZ2h0PSIxMDAlIiBmaWxsPSJ1cmwoI2EpIi8+PC9zdmc+',
            'jakoolit': 'data:image/svg+xml;base64,PHN2ZyB3aWR0aD0iODAwIiBoZWlnaHQ9IjYwMCIgeG1sbnM9Imh0dHA6Ly93d3cudzMub3JnLzIwMDAvc3ZnIj48ZGVmcz48bGluZWFyR3JhZGllbnQgaWQ9ImEiIHgxPSIwJSIgeTE9IjAlIiB4Mj0iMTAwJSIgeTI9IjEwMCUiPjxzdG9wIG9mZnNldD0iMCUiIHN0b3AtY29sb3I9IiMwZDExMTciLz48c3RvcCBvZmZzZXQ9IjEwMCUiIHN0b3AtY29sb3I9IiMyMTI2MmQiLz48L2xpbmVhckdyYWRpZW50PjwvZGVmcz48cmVjdCB3aWR0aD0iMTAwJSIgaGVpZ2h0PSIxMDAlIiBmaWxsPSJ1cmwoI2EpIi8+PC9zdmc+',
            'default': 'data:image/svg+xml;base64,PHN2ZyB3aWR0aD0iODAwIiBoZWlnaHQ9IjYwMCIgeG1sbnM9Imh0dHA6Ly93d3cudzMub3JnLzIwMDAvc3ZnIj48ZGVmcz48bGluZWFyR3JhZGllbnQgaWQ9ImEiIHgxPSIwJSIgeTE9IjAlIiB4Mj0iMTAwJSIgeTI9IjEwMCUiPjxzdG9wIG9mZnNldD0iMCUiIHN0b3AtY29sb3I9IiMxZTFlMmUiLz48c3RvcCBvZmZzZXQ9IjEwMCUiIHN0b3AtY29sb3I9IiM0NTQ3NWEiLz48L2xpbmVhckdyYWRpZW50PjwvZGVmcz48cmVjdCB3aWR0aD0iMTAwJSIgaGVpZ2h0PSIxMDAlIiBmaWxsPSJ1cmwoI2EpIi8+PC9zdmc+'
        }
        return wallpapers.get(config, wallpapers['default'])
        
    def create_sample_desktop_image(self, config: str) -> GdkPixbuf.Pixbuf:
        """Create sample desktop image for theme preview"""
        # This would generate actual preview images in a real implementation
        # For now, create a simple colored rectangle
        width, height = 400, 300
        
        colors = {
            'default': (30, 30, 46),
            'hyde': (26, 26, 46),
            'jakoolit': (13, 17, 23),
            'ml4w': (40, 42, 54),
            'custom': (69, 71, 90)
        }
        
        color = colors.get(config, colors['default'])
        
        # Create a simple pixbuf (in real app, this would be actual screenshots)
        pixbuf = GdkPixbuf.Pixbuf.new(GdkPixbuf.Colorspace.RGB, False, 8, width, height)
        pixbuf.fill((color[0] << 24) | (color[1] << 16) | (color[2] << 8) | 0xFF)
        
        return pixbuf
        
    def refresh_preview(self, button):
        """Refresh the current preview"""
        current_page = self.preview_stack.get_visible_child_name()
        if current_page:
            self.update_preview_content(current_page)
            
    def save_preview(self, button):
        """Save current preview as image"""
        dialog = Gtk.FileChooserNative.new(
            "Save Preview",
            self,
            Gtk.FileChooserAction.SAVE,
            "Save",
            "Cancel"
        )
        
        # Add PNG filter
        png_filter = Gtk.FileFilter()
        png_filter.set_name("PNG Images")
        png_filter.add_mime_type("image/png")
        dialog.add_filter(png_filter)
        
        dialog.set_current_name(f"hyprsupreme-preview-{int(time.time())}.png")
        
        def on_response(dialog, response):
            if response == Gtk.ResponseType.ACCEPT:
                file = dialog.get_file()
                if file:
                    # Save preview (implementation would depend on preview type)
                    self.save_preview_to_file(file.get_path())
            dialog.destroy()
            
        dialog.connect("response", on_response)
        dialog.show()
        
    def save_preview_to_file(self, filepath: str):
        """Save preview content to file"""
        try:
            # This would implement actual preview saving
            # For now, just show a success message
            toast = Adw.Toast.new(f"Preview saved to {filepath}")
            toast.set_timeout(3)
            # Would need a toast overlay in the main window
            
        except Exception as e:
            dialog = Adw.MessageDialog.new(self, "Save Failed", f"Could not save preview: {str(e)}")
            dialog.add_response("ok", "OK")
            dialog.present()

def main():
    """Main entry point"""
    # Ensure we're in the right directory
    script_dir = Path(__file__).parent.parent
    os.chdir(script_dir)
    
    app = HyprSupremeGUI()
    return app.run(sys.argv)

if __name__ == "__main__":
    main()


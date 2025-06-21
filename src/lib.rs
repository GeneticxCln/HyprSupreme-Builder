use pyo3::prelude::*;
use pyo3::exceptions::PyRuntimeError;

mod plugins;
mod themes;

use plugins::PluginManager as RustPluginManager;
use themes::ThemeManager as RustThemeManager;

/// Python wrapper for PluginManager
#[pyclass]
struct PluginManager {
    inner: RustPluginManager,
}

#[pymethods]
impl PluginManager {
    #[new]
    fn new() -> Self {
        PluginManager {
            inner: RustPluginManager::new(),
        }
    }

    fn enable_plugin(&mut self, name: &str) -> PyResult<()> {
        self.inner.enable_plugin(name)
            .map_err(|e| PyRuntimeError::new_err(format!("Failed to enable plugin: {}", e)))
    }

    fn disable_plugin(&mut self, name: &str) -> PyResult<()> {
        self.inner.disable_plugin(name)
            .map_err(|e| PyRuntimeError::new_err(format!("Failed to disable plugin: {}", e)))
    }

    fn execute_command(&self, plugin_name: &str, command_name: &str, args: Vec<String>) -> PyResult<String> {
        let args_refs: Vec<&str> = args.iter().map(|s| s.as_str()).collect();
        self.inner.execute_command(plugin_name, command_name, &args_refs)
            .map_err(|e| PyRuntimeError::new_err(format!("Failed to execute command: {}", e)))
    }

    fn execute_hook(&self, hook_name: &str, context: &str) -> PyResult<String> {
        let results = self.inner.execute_hook(hook_name, &[context])
            .map_err(|e| PyRuntimeError::new_err(format!("Failed to execute hook: {}", e)))?;
        
        // Convert HashMap to JSON string for Python consumption
        let json_result = serde_json::to_string(&results)
            .map_err(|e| PyRuntimeError::new_err(format!("Failed to serialize results: {}", e)))?;
        
        Ok(json_result)
    }

    fn get_plugins(&self) -> PyResult<Vec<String>> {
        Ok(self.inner.get_plugins())
    }

    fn get_plugin(&self, name: &str) -> PyResult<String> {
        if let Some(plugin) = self.inner.get_plugin(name) {
            // Convert plugin info to JSON for Python consumption
            let plugin_info = serde_json::json!({
                "name": plugin.manifest.name,
                "version": plugin.manifest.version,
                "description": plugin.manifest.description,
                "author": plugin.manifest.author
            });
            
            serde_json::to_string(&plugin_info)
                .map_err(|e| PyRuntimeError::new_err(format!("Failed to serialize plugin info: {}", e)))
        } else {
            Err(PyRuntimeError::new_err(format!("Plugin not found: {}", name)))
        }
    }
}

/// Python wrapper for ThemeManager
#[pyclass]
struct ThemeManager {
    inner: RustThemeManager,
}

#[pymethods]
impl ThemeManager {
    #[new]
    fn new() -> Self {
        ThemeManager {
            inner: RustThemeManager::new(),
        }
    }

    fn set_theme(&mut self, name: &str) -> PyResult<()> {
        self.inner.set_theme(name)
            .map_err(|e| PyRuntimeError::new_err(format!("Failed to set theme: {}", e)))
    }

    fn get_theme_color(&self, color_name: &str) -> PyResult<String> {
        self.inner.get_theme_color(color_name)
            .map_err(|e| PyRuntimeError::new_err(format!("Failed to get theme color: {}", e)))
    }

    fn get_theme_variable(&self, var_name: &str) -> PyResult<String> {
        self.inner.get_theme_variable(var_name)
            .map_err(|e| PyRuntimeError::new_err(format!("Failed to get theme variable: {}", e)))
    }

    fn get_themes(&self) -> PyResult<Vec<String>> {
        Ok(self.inner.get_themes())
    }

    fn reload_theme(&mut self) -> PyResult<()> {
        self.inner.reload_theme()
            .map_err(|e| PyRuntimeError::new_err(format!("Failed to reload theme: {}", e)))
    }
}

/// Config Generator wrapper
#[pyclass]
struct ConfigGenerator {
    
}

#[pymethods]
impl ConfigGenerator {
    #[new]
    fn new() -> Self {
        ConfigGenerator {}
    }

    fn generate_config(&self, theme: &str, plugins: Vec<&str>, _additional_config: &str) -> PyResult<String> {
        // Mock implementation for now
        Ok(format!("Generated config for theme: {}, plugins: {:?}", theme, plugins))
    }

    fn detect_conflicts(&self, _config1: &str, _config2: &str) -> PyResult<Vec<String>> {
        // Mock implementation for now
        Ok(vec!["No conflicts detected".to_string()])
    }
}

/// A Python module implemented in Rust.
#[pymodule]
fn hyprsupreme_core(_py: Python, m: &PyModule) -> PyResult<()> {
    m.add_class::<PluginManager>()?;
    m.add_class::<ThemeManager>()?;
    m.add_class::<ConfigGenerator>()?;
    Ok(())
}

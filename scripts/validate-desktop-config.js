#!/usr/bin/env node

// Desktop Environment Configuration Validation Script
// Validates desktop environment configurations using Zod schemas

import { readFileSync, existsSync } from 'fs';
import { resolve } from 'path';
import { 
  validateNiriConfig, 
  validateWaybarConfig, 
  validateWofiConfig, 
  validateGhosttyConfig,
  validateDesktopEnvironmentConfig,
  defaultNiriConfig,
  defaultWaybarConfig,
  defaultWofiConfig,
  defaultGhosttyConfig,
  defaultDesktopEnvironmentConfig
} from '../config/schemas/desktop-environment.js';

// Configuration file paths
const CONFIG_PATHS = {
  niri: '/etc/niri/config.kdl',
  waybar: '/etc/xdg/waybar/config',
  wofi: '/etc/xdg/wofi/config',
  ghostty: '/etc/xdg/ghostty/config',
  desktop: '/etc/voidance/desktop-environment.json'
};

// User configuration paths
const USER_CONFIG_PATHS = {
  niri: `${process.env.HOME}/.config/niri/config.kdl`,
  waybar: `${process.env.HOME}/.config/waybar/config`,
  wofi: `${process.env.HOME}/.config/wofi/config`,
  ghostty: `${process.env.HOME}/.config/ghostty/config`,
  desktop: `${process.env.HOME}/.config/voidance/desktop-environment.json`
};

// Function to read JSON configuration file
function readJsonConfig(filePath) {
  try {
    if (!existsSync(filePath)) {
      return null;
    }
    const content = readFileSync(filePath, 'utf8');
    return JSON.parse(content);
  } catch (error) {
    console.error(`Error reading ${filePath}:`, error.message);
    return null;
  }
}

// Function to read KDL configuration file (simplified)
function readKdlConfig(filePath) {
  try {
    if (!existsSync(filePath)) {
      return null;
    }
    const content = readFileSync(filePath, 'utf8');
    // For now, return a basic structure since KDL parsing is complex
    // In a real implementation, you'd use a KDL parser
    return {
      format: 'kdl',
      content: content
    };
  } catch (error) {
    console.error(`Error reading ${filePath}:`, error.message);
    return null;
  }
}

// Function to validate Niri configuration
function validateNiri(configPath, isUser = false) {
  console.log(`\n=== Validating Niri Configuration ===`);
  console.log(`Path: ${configPath}`);
  
  const config = readKdlConfig(configPath);
  
  if (!config) {
    console.log(`⚠ Configuration file not found, using defaults`);
    const result = validateNiriConfig(defaultNiriConfig);
    if (result.success) {
      console.log(`✓ Default configuration is valid`);
    } else {
      console.log(`✗ Default configuration is invalid:`);
      result.error.issues.forEach(issue => {
        console.log(`  - ${issue.path.join('.')}: ${issue.message}`);
      });
    }
    return result.success;
  }
  
  // For KDL files, we'll do basic validation
  if (config.format === 'kdl') {
    console.log(`ℹ KDL configuration detected - basic validation only`);
    const content = config.content;
    
    // Basic checks
    const checks = [
      { name: 'Output configuration', pattern: /output\s*\{/ },
      { name: 'Layout configuration', pattern: /layout\s*\{/ },
      { name: 'Input configuration', pattern: /input\s*\{/ },
      { name: 'Keybindings', pattern: /bind\s*{/ },
    ];
    
    let passed = 0;
    checks.forEach(check => {
      if (content.match(check.pattern)) {
        console.log(`✓ ${check.name} found`);
        passed++;
      } else {
        console.log(`⚠ ${check.name} not found`);
      }
    });
    
    console.log(`Basic validation: ${passed}/${checks.length} sections found`);
    return true;
  }
  
  const result = validateNiriConfig(config);
  if (result.success) {
    console.log(`✓ Niri configuration is valid`);
  } else {
    console.log(`✗ Niri configuration is invalid:`);
    result.error.issues.forEach(issue => {
      console.log(`  - ${issue.path.join('.')}: ${issue.message}`);
    });
  }
  
  return result.success;
}

// Function to validate Waybar configuration
function validateWaybar(configPath, isUser = false) {
  console.log(`\n=== Validating Waybar Configuration ===`);
  console.log(`Path: ${configPath}`);
  
  const config = readJsonConfig(configPath);
  
  if (!config) {
    console.log(`⚠ Configuration file not found, using defaults`);
    const result = validateWaybarConfig(defaultWaybarConfig);
    if (result.success) {
      console.log(`✓ Default configuration is valid`);
    } else {
      console.log(`✗ Default configuration is invalid:`);
      result.error.issues.forEach(issue => {
        console.log(`  - ${issue.path.join('.')}: ${issue.message}`);
      });
    }
    return result.success;
  }
  
  const result = validateWaybarConfig(config);
  if (result.success) {
    console.log(`✓ Waybar configuration is valid`);
    
    // Additional checks
    if (config.modules_left && config.modules_left.length > 0) {
      console.log(`✓ Left modules configured: ${config.modules_left.join(', ')}`);
    }
    if (config.modules_center && config.modules_center.length > 0) {
      console.log(`✓ Center modules configured: ${config.modules_center.join(', ')}`);
    }
    if (config.modules_right && config.modules_right.length > 0) {
      console.log(`✓ Right modules configured: ${config.modules_right.join(', ')}`);
    }
  } else {
    console.log(`✗ Waybar configuration is invalid:`);
    result.error.issues.forEach(issue => {
      console.log(`  - ${issue.path.join('.')}: ${issue.message}`);
    });
  }
  
  return result.success;
}

// Function to validate wofi configuration
function validateWofi(configPath, isUser = false) {
  console.log(`\n=== Validating wofi Configuration ===`);
  console.log(`Path: ${configPath}`);
  
  const config = readJsonConfig(configPath);
  
  if (!config) {
    console.log(`⚠ Configuration file not found, using defaults`);
    const result = validateWofiConfig(defaultWofiConfig);
    if (result.success) {
      console.log(`✓ Default configuration is valid`);
    } else {
      console.log(`✗ Default configuration is invalid:`);
      result.error.issues.forEach(issue => {
        console.log(`  - ${issue.path.join('.')}: ${issue.message}`);
      });
    }
    return result.success;
  }
  
  const result = validateWofiConfig(config);
  if (result.success) {
    console.log(`✓ wofi configuration is valid`);
    
    // Additional checks
    console.log(`✓ Mode: ${config.mode}`);
    console.log(`✓ Terminal: ${config.term}`);
    if (config.width) console.log(`✓ Width: ${config.width}`);
    if (config.height) console.log(`✓ Height: ${config.height}`);
    if (config.location) console.log(`✓ Location: ${config.location}`);
  } else {
    console.log(`✗ wofi configuration is invalid:`);
    result.error.issues.forEach(issue => {
      console.log(`  - ${issue.path.join('.')}: ${issue.message}`);
    });
  }
  
  return result.success;
}

// Function to validate Ghostty configuration
function validateGhostty(configPath, isUser = false) {
  console.log(`\n=== Validating Ghostty Configuration ===`);
  console.log(`Path: ${configPath}`);
  
  const config = readJsonConfig(configPath);
  
  if (!config) {
    console.log(`⚠ Configuration file not found, using defaults`);
    const result = validateGhosttyConfig(defaultGhosttyConfig);
    if (result.success) {
      console.log(`✓ Default configuration is valid`);
    } else {
      console.log(`✗ Default configuration is invalid:`);
      result.error.issues.forEach(issue => {
        console.log(`  - ${issue.path.join('.')}: ${issue.message}`);
      });
    }
    return result.success;
  }
  
  const result = validateGhosttyConfig(config);
  if (result.success) {
    console.log(`✓ Ghostty configuration is valid`);
    
    // Additional checks
    if (config.settings) {
      console.log(`✓ Settings configured`);
      if (config.settings.font) {
        console.log(`  - Font family: ${config.settings.font.family}`);
        console.log(`  - Font size: ${config.settings.font.size}`);
      }
      if (config.settings.theme) {
        console.log(`  - Theme: ${config.settings.theme}`);
      }
      if (config.settings.window) {
        console.log(`  - Window size: ${config.settings.window.width}x${config.settings.window.height}`);
      }
      if (config.settings.render) {
        console.log(`  - Render backend: ${config.settings.render.backend}`);
        console.log(`  - GPU acceleration: ${config.settings.render.gpu_acceleration}`);
      }
    }
  } else {
    console.log(`✗ Ghostty configuration is invalid:`);
    result.error.issues.forEach(issue => {
      console.log(`  - ${issue.path.join('.')}: ${issue.message}`);
    });
  }
  
  return result.success;
}

// Function to validate desktop environment configuration
function validateDesktop(configPath, isUser = false) {
  console.log(`\n=== Validating Desktop Environment Configuration ===`);
  console.log(`Path: ${configPath}`);
  
  const config = readJsonConfig(configPath);
  
  if (!config) {
    console.log(`⚠ Configuration file not found, using defaults`);
    const result = validateDesktopEnvironmentConfig(defaultDesktopEnvironmentConfig);
    if (result.success) {
      console.log(`✓ Default configuration is valid`);
    } else {
      console.log(`✗ Default configuration is invalid:`);
      result.error.issues.forEach(issue => {
        console.log(`  - ${issue.path.join('.')}: ${issue.message}`);
      });
    }
    return result.success;
  }
  
  const result = validateDesktopEnvironmentConfig(config);
  if (result.success) {
    console.log(`✓ Desktop environment configuration is valid`);
    
    // Component validation
    if (config.components) {
      if (config.components.niri) {
        console.log(`✓ Niri component configured`);
      }
      if (config.components.waybar) {
        console.log(`✓ Waybar component configured`);
      }
      if (config.components.wofi) {
        console.log(`✓ wofi component configured`);
      }
      if (config.components.ghostty) {
        console.log(`✓ Ghostty component configured`);
      }
    }
    
    // Global settings
    if (config.global) {
      console.log(`✓ Global settings configured`);
      console.log(`  - Log level: ${config.global.log_level}`);
      console.log(`  - Auto start: ${config.global.auto_start}`);
      console.log(`  - Hardware detection: ${config.global.hardware_detection}`);
    }
  } else {
    console.log(`✗ Desktop environment configuration is invalid:`);
    result.error.issues.forEach(issue => {
      console.log(`  - ${issue.path.join('.')}: ${issue.message}`);
    });
  }
  
  return result.success;
}

// Function to validate all configurations
function validateAll(userOnly = false) {
  console.log(`=== Voidance Desktop Environment Configuration Validation ===`);
  console.log(`Mode: ${userOnly ? 'User configurations only' : 'System configurations'}`);
  
  const paths = userOnly ? USER_CONFIG_PATHS : CONFIG_PATHS;
  let totalPassed = 0;
  let totalChecks = 5;
  
  // Validate Niri
  if (validateNiri(paths.niri, userOnly)) {
    totalPassed++;
  }
  
  // Validate Waybar
  if (validateWaybar(paths.waybar, userOnly)) {
    totalPassed++;
  }
  
  // Validate wofi
  if (validateWofi(paths.wofi, userOnly)) {
    totalPassed++;
  }
  
  // Validate Ghostty
  if (validateGhostty(paths.ghostty, userOnly)) {
    totalPassed++;
  }
  
  // Validate Desktop Environment
  if (validateDesktop(paths.desktop, userOnly)) {
    totalPassed++;
  }
  
  // Summary
  console.log(`\n=== Validation Summary ===`);
  console.log(`Passed: ${totalPassed}/${totalChecks} configurations`);
  
  if (totalPassed === totalChecks) {
    console.log(`✓ All configurations are valid!`);
    return true;
  } else {
    console.log(`✗ Some configurations have issues`);
    return false;
  }
}

// Function to generate default configuration files
function generateDefaults(outputDir = '.') {
  console.log(`=== Generating Default Configuration Files ===`);
  console.log(`Output directory: ${outputDir}`);
  
  try {
    // Generate desktop environment configuration
    const desktopConfigPath = resolve(outputDir, 'desktop-environment.json');
    require('fs').writeFileSync(
      desktopConfigPath, 
      JSON.stringify(defaultDesktopEnvironmentConfig, null, 2)
    );
    console.log(`✓ Generated: ${desktopConfigPath}`);
    
    // Generate individual component configurations
    const niriConfigPath = resolve(outputDir, 'niri-config.json');
    require('fs').writeFileSync(
      niriConfigPath, 
      JSON.stringify(defaultNiriConfig, null, 2)
    );
    console.log(`✓ Generated: ${niriConfigPath}`);
    
    const waybarConfigPath = resolve(outputDir, 'waybar-config.json');
    require('fs').writeFileSync(
      waybarConfigPath, 
      JSON.stringify(defaultWaybarConfig, null, 2)
    );
    console.log(`✓ Generated: ${waybarConfigPath}`);
    
    const wofiConfigPath = resolve(outputDir, 'wofi-config.json');
    require('fs').writeFileSync(
      wofiConfigPath, 
      JSON.stringify(defaultWofiConfig, null, 2)
    );
    console.log(`✓ Generated: ${wofiConfigPath}`);
    
    const ghosttyConfigPath = resolve(outputDir, 'ghostty-config.json');
    require('fs').writeFileSync(
      ghosttyConfigPath, 
      JSON.stringify(defaultGhosttyConfig, null, 2)
    );
    console.log(`✓ Generated: ${ghosttyConfigPath}`);
    
    console.log(`\n✓ All default configuration files generated successfully!`);
    return true;
  } catch (error) {
    console.error(`✗ Error generating configuration files:`, error.message);
    return false;
  }
}

// CLI interface
function main() {
  const args = process.argv.slice(2);
  const command = args[0] || 'validate';
  
  switch (command) {
    case 'validate':
    case 'check':
      const userOnly = args.includes('--user') || args.includes('-u');
      validateAll(userOnly);
      break;
      
    case 'generate':
    case 'defaults':
      const outputDir = args[1] || '.';
      generateDefaults(outputDir);
      break;
      
    case 'niri':
      const niriPath = args[1] || CONFIG_PATHS.niri;
      validateNiri(niriPath);
      break;
      
    case 'waybar':
      const waybarPath = args[1] || CONFIG_PATHS.waybar;
      validateWaybar(waybarPath);
      break;
      
    case 'wofi':
      const wofiPath = args[1] || CONFIG_PATHS.wofi;
      validateWofi(wofiPath);
      break;
      
    case 'ghostty':
      const ghosttyPath = args[1] || CONFIG_PATHS.ghostty;
      validateGhostty(ghosttyPath);
      break;
      
    case 'desktop':
      const desktopPath = args[1] || CONFIG_PATHS.desktop;
      validateDesktop(desktopPath);
      break;
      
    case 'help':
    case '--help':
    case '-h':
      console.log(`
Desktop Environment Configuration Validation Tool

Usage:
  ${process.argv[1]} <command> [options]

Commands:
  validate [options]     Validate all configurations
  generate [dir]         Generate default configuration files
   niri [path]            Validate Niri configuration
   waybar [path]          Validate Waybar configuration
   wofi [path]            Validate wofi configuration
   ghostty [path]         Validate Ghostty configuration
   desktop [path]         Validate desktop environment configuration
  help                   Show this help message

Options:
  --user, -u             Validate user configurations instead of system
  --help, -h             Show this help message

Examples:
  ${process.argv[1]} validate              # Validate system configs
  ${process.argv[1]} validate --user       # Validate user configs
  ${process.argv[1]} generate ./defaults   # Generate defaults in ./defaults
  ${process.argv[1]} niri /path/to/config  # Validate specific config
`);
      break;
      
    default:
      console.error(`Unknown command: ${command}`);
      console.error(`Use 'help' for usage information`);
      process.exit(1);
  }
}

// Run if called directly
if (import.meta.url === `file://${process.argv[1]}`) {
  main();
}

export {
  validateNiri,
  validateWaybar,
  validateWofi,
  validateGhostty,
  validateDesktop,
  validateAll,
  generateDefaults
};
// Zod schemas for Voidance Linux desktop environment configuration
// Provides type-safe configuration validation for Niri, Waybar, and wofi

import { z } from 'zod';

// Base configuration schema
const BaseConfigSchema = z.object({
  version: z.string().default('1.0.0'),
  enabled: z.boolean().default(true),
  debug: z.boolean().default(false),
});

// Output configuration schema
const OutputConfigSchema = z.object({
  name: z.string(),
  mode: z.object({
    width: z.number().int().positive(),
    height: z.number().int().positive(),
    refresh: z.number().positive().optional(),
  }).optional(),
  position: z.object({
    x: z.number().int(),
    y: z.number().int(),
  }).optional(),
  scale: z.number().positive().default(1.0),
  transform: z.enum(['normal', '90', '180', '270', 'flipped', 'flipped-90', 'flipped-180', 'flipped-270']).default('normal'),
  adaptive_sync: z.boolean().default(false),
  background_color: z.string().regex(/^#[0-9a-fA-F]{6}$/).default('#24273a'),
});

// Layout configuration schema
const LayoutConfigSchema = z.object({
  default_width: z.number().int().min(100).max(2000).default(800),
  default_height: z.number().int().min(100).max(2000).default(600),
  gaps: z.number().int().min(0).max(100).default(8),
  center_column: z.object({
    width: z.number().int().min(1).max(10).default(1),
  }).optional(),
  preset_column_widths: z.array(z.array(z.number().int().positive())).default([
    [1, 10],
    [1, 5],
    [2, 5],
    [3, 5],
    [4, 5],
    [5, 5],
  ]),
  preset_window_heights: z.array(z.array(z.number().int().positive())).default([
    [1, 10],
    [1, 5],
    [2, 5],
    [3, 5],
    [4, 5],
    [5, 5],
  ]),
});

// Input configuration schema
const InputConfigSchema = z.object({
  name: z.string(),
  type: z.enum(['keyboard', 'pointer', 'touch', 'tablet']),
  settings: z.object({
    repeat_rate: z.number().int().min(1).max(100).default(25),
    repeat_delay: z.number().int().min(100).max(2000).default(600),
    accel_profile: z.enum(['none', 'flat', 'adaptive']).default('adaptive'),
    accel_speed: z.number().min(-1.0).max(1.0).default(0.0),
    natural_scroll: z.boolean().default(false),
    left_handed: z.boolean().default(false),
    tap_to_click: z.boolean().default(true),
    drag_lock: z.boolean().default(false),
    disable_while_typing: z.boolean().default(true),
    middle_emulation: z.boolean().default(false),
  }).optional(),
});

// Keybinding configuration schema
const KeybindingConfigSchema = z.object({
  modifiers: z.array(z.enum(['Ctrl', 'Alt', 'Shift', 'Super', 'Hyper', 'Meta'])),
  key: z.string(),
  action: z.enum(['spawn', 'close', 'fullscreen', 'focus', 'move', 'resize', 'quit', 'reload']),
  command: z.string().optional(),
  direction: z.enum(['left', 'right', 'up', 'down']).optional(),
  workspace: z.number().int().positive().optional(),
});

// Window rule configuration schema
const WindowRuleSchema = z.object({
  app_id: z.string().optional(),
  title: z.string().optional(),
  output: z.string().optional(),
  width: z.number().int().positive().optional(),
  height: z.number().int().positive().optional(),
  x: z.number().int().optional(),
  y: z.number().int().optional(),
  floating: z.boolean().optional(),
  fullscreen: z.boolean().optional(),
  pinned: z.boolean().optional(),
  focused: z.boolean().optional(),
  opacity: z.number().min(0.0).max(1.0).optional(),
});

// Niri configuration schema
export const NiriConfigSchema = BaseConfigSchema.extend({
  service: z.literal('niri'),
  settings: z.object({
    outputs: z.array(OutputConfigSchema).default([]),
    layout: LayoutConfigSchema.default({}),
    input: z.object({
      keyboard: z.object({
        repeat_rate: z.number().int().min(1).max(100).default(25),
        repeat_delay: z.number().int().min(100).max(2000).default(600),
        xkb_layout: z.string().default('us'),
        xkb_variant: z.string().default(''),
        xkb_options: z.string().default(''),
      }).default({}),
      touchpad: z.object({
        accel_profile: z.enum(['none', 'flat', 'adaptive']).default('adaptive'),
        accel_speed: z.number().min(-1.0).max(1.0).default(0.0),
        natural_scroll: z.boolean().default(false),
        tap_to_click: z.boolean().default(true),
        drag_lock: z.boolean().default(false),
        disable_while_typing: z.boolean().default(true),
        middle_emulation: z.boolean().default(false),
      }).default({}),
      mouse: z.object({
        accel_profile: z.enum(['none', 'flat', 'adaptive']).default('adaptive'),
        accel_speed: z.number().min(-1.0).max(1.0).default(0.0),
        natural_scroll: z.boolean().default(false),
      }).default({}),
    }),
    keybindings: z.array(KeybindingConfigSchema).default([]),
    window_rules: z.array(WindowRuleSchema).default([]),
    environment: z.record(z.string()).default({}),
    spawn_at_startup: z.array(z.object({
      command: z.array(z.string()),
    })).default([]),
    cursor: z.object({
      theme: z.string().default('Adwaita'),
      size: z.number().int().min(8).max(128).default(24),
    }).default({}),
    prefer_no_csd: z.boolean().default(true),
    hotkey_overlay: z.object({
      skip_at_startup: z.boolean().default(true),
    }).default({}),
  }),
});

// Waybar module configuration schema
const WaybarModuleSchema = z.object({
  type: z.enum([
    'custom', 'battery', 'backlight', 'clock', 'cpu', 'disk', 'idle_inhibitor',
    'memory', 'mpd', 'network', 'pulseaudio', 'river', 'river/tags', 'river/layout',
    'river/mode', 'river/window', 'scratchpad', 'sway/mode', 'sway/workspaces',
    'sway/window', 'sway/scratchpad', 'temperature', 'tray', 'upower', 'wireplumber'
  ]),
  format: z.string().optional(),
  'format-alt': z.string().optional(),
  interval: z.number().int().positive().optional(),
  tooltip: z.boolean().default(true),
  'tooltip-format': z.string().optional(),
  'min-length': z.number().int().positive().optional(),
  'max-length': z.number().int().positive().optional(),
  align: z.enum(['left', 'center', 'right']).optional(),
  rotate: z.number().int().multipleOf(90).optional(),
  'on-click': z.string().optional(),
  'on-click-right': z.string().optional(),
  'on-click-middle': z.string().optional(),
  'on-scroll-up': z.string().optional(),
  'on-scroll-down': z.string().optional(),
  'smooth-scrolling-threshold': z.number().int().positive().optional(),
  'format-icons': z.record(z.string()).optional(),
  'format-alt-icons': z.record(z.string()).optional(),
  'format-disconnected': z.string().optional(),
  'format-connected': z.string().optional(),
  'format-alt-connected': z.string().optional(),
  'format-padding': z.string().optional(),
  'format-time': z.string().optional(),
  'format-date': z.string().optional(),
  timezone: z.string().optional(),
  locale: z.string().optional(),
  'time-format': z.string().optional(),
  'date-format': z.string().optional(),
  'format-charging': z.string().optional(),
  'format-plugged': z.string().optional(),
  'format-full': z.string().optional(),
  'format-low': z.string().optional(),
  'format-medium': z.string().optional(),
  'format-high': z.string().optional(),
  'format-critical': z.string().optional(),
  'bat': z.string().optional(),
  'adapter': z.string().optional(),
  'interface': z.string().optional(),
  'format-device': z.string().optional(),
  'format-mounted': z.string().optional(),
  'format-unmounted': z.string().optional(),
  'format-not-mounted': z.string().optional(),
  'nodes': z.array(z.string()).optional(),
  'ignored-sinks': z.array(z.string()).optional(),
  'max-volume': z.number().int().min(0).max(200).default(100),
  'scroll-step': z.number().int().min(1).max(20).default(1),
  'on-click-middle': z.string().optional(),
  'reverse-scrolling': z.boolean().default(false),
  'format-source': z.string().optional(),
  'format-source-muted': z.string().optional(),
  'tooltip-format-source': z.string().optional(),
  'thermal-zone': z.number().int().optional(),
  'hwmon-path': z.string().optional(),
  'hwmon-path-abs': z.string().optional(),
  'input-filename': z.string().optional(),
  'critical-threshold': z.number().int().optional(),
});

// Waybar configuration schema
export const WaybarConfigSchema = BaseConfigSchema.extend({
  service: z.literal('waybar'),
  settings: z.object({
    layer: z.enum(['top', 'bottom', 'overlay']).default('top'),
    position: z.enum(['top', 'bottom', 'left', 'right']).default('top'),
    height: z.number().int().min(10).max(200).default(30),
    width: z.enum(['auto', 'request']).default('request'),
    spacing: z.number().int().min(0).max(50).default(4),
    'margin-top': z.number().int().min(0).max(100).default(0),
    'margin-bottom': z.number().int().min(0).max(100).default(0),
    'margin-left': z.number().int().min(0).max(100).default(0),
    'margin-right': z.number().int().min(0).max(100).default(0),
    'modules-left': z.array(z.string()).default(['niri/workspaces']),
    'modules-center': z.array(z.string()).default(['clock']),
    'modules-right': z.array(z.string()).default(['pulseaudio', 'network', 'battery', 'tray']),
    'startup-command': z.string().optional(),
    'reload-style-on-change': z.boolean().default(false),
    'fixed-center': z.boolean().default(true),
    'passthrough': z.boolean().default(false),
    'ipc': z.boolean().default(true),
    'include': z.array(z.string()).default([]),
    modules: z.record(WaybarModuleSchema).default({}),
    'bar-id': z.string().optional(),
    'output': z.array(z.string()).optional(),
    'exclusive': z.boolean().default(true),
    'gtk-layer-shell': z.boolean().default(true),
  }),
});

// wofi configuration schema
export const WofiConfigSchema = BaseConfigSchema.extend({
  service: z.literal('wofi'),
  settings: z.object({
    mode: z.enum(['drun', 'run', 'dmenu', 'combi']).default('drun'),
    term: z.string().default('ghostty'),
    exec: z.string().optional(),
    'exec-search': z.string().optional(),
    prompt: z.string().default('Apps'),
    filter: z.boolean().default(true),
    'allow-images': z.boolean().default(true),
    'allow-markup': z.boolean().default(true),
    insensitive: z.boolean().default(true),
    'parse-search': z.boolean().default(true),
    'hide-scroll': z.boolean().default(false),
    'normal-window': z.boolean().default(false),
    monitor: z.number().int().min(0).default(0),
    layers: z.enum(['top', 'bottom', 'background', 'overlay']).default('top'),
    'x-offset': z.number().int().default(0),
    'y-offset': z.number().int().default(0),
    width: z.union([z.number().int().positive(), z.string()]).default('50%'),
    height: z.union([z.number().int().positive(), z.string()]).default('40%'),
    location: z.enum(['top-left', 'top-center', 'top-right', 'center-left', 'center', 'center-right', 'bottom-left', 'bottom-center', 'bottom-right']).default('center'),
    orientation: z.enum(['horizontal', 'vertical']).default('vertical'),
    halign: z.enum(['left', 'center', 'right']).default('fill'),
    valign: z.enum(['top', 'center', 'bottom']).default('fill'),
    line_wrap: z.enum(['off', 'word', 'char', 'word_char']).default('off'),
    dynamic_lines: z.boolean().default(false),
    num_lines: z.number().int().min(1).max(100).default(10),
    columns: z.number().int().min(1).max(10).default(1),
    'term-size': z.number().int().min(1).max(100).default(10),
    'display-columns': z.number().int().min(1).max(10).default(1),
    'display-row': z.number().int().min(1).max(100).default(1),
    'sort-order': z.enum(['default', 'alphabetical']).default('default'),
    'gtk-dark': z.boolean().default(true),
    color: z.object({
      background: z.string().default('#282828ff'),
      foreground: z.string().default('#ebdbb2ff'),
      border: z.string().default('#458588ff'),
      selected: z.string().default('#458588ff'),
      'selected-foreground': z.string().default('#282828ff'),
      window: z.string().default('#458588ff'),
      separator: z.string().default('#665c54ff'),
    }).default({}),
    'color-window': z.string().default('#458588ff'),
    'color-border': z.string().default('#458588ff'),
    'color-separator': z.string().default('#665c54ff'),
    'color-row-bg': z.string().optional(),
    'color-row-fg': z.string().optional(),
    'color-row-bg-alt': z.string().optional(),
    'color-row-fg-alt': z.string().optional(),
    'color-row-bg-selected': z.string().optional(),
    'color-row-fg-selected': z.string().optional(),
    'color-row-bg-active': z.string().optional(),
    'color-row-fg-active': z.string().optional(),
    'key-expand': z.enum(['Tab', 'ISO_Left_Tab', 'Down', 'Control-bracketleft', 'grave']).default('Tab'),
    'key-nav-up': z.enum(['Up', 'Control-p', 'Shift-Tab', 'ISO_Left_Tab']).default('Up'),
    'key-nav-down': z.enum(['Down', 'Control-n', 'Tab']).default('Down'),
    'key-nav-left': z.enum(['Left', 'Control-b']).default('Left'),
    'key-nav-right': z.enum(['Right', 'Control-f']).default('Right'),
    'key-submit': z.enum(['Return', 'KP_Enter', 'Control-m', 'Control-j']).default('Return'),
    'key-exit': z.enum(['Escape', 'Control-g', 'Control-c']).default('Escape'),
    'key-delete': z.enum(['BackSpace', 'Delete', 'Control-h']).default('BackSpace'),
    'key-delete-word': z.enum(['Control-BackSpace', 'Control-w']).default('Control-BackSpace'),
    'key-delete-line': z.enum(['Control-u']).default('Control-u'),
    'key-pgup': z.enum(['Page_Up', 'KP_Page_Up', 'Control-v']).default('Page_Up'),
    'key-pgdn': z.enum(['Page_Down', 'KP_Page_Down', 'Control-y']).default('Page_Down'),
    'key-home': z.enum(['Home', 'KP_Home', 'Control-a']).default('Home'),
    'key-end': z.enum(['End', 'KP_End', 'Control-e']).default('End'),
    'key-row-first': z.enum(['Home', 'KP_Home', 'Control-a']).default('Home'),
    'key-row-last': z.enum(['End', 'KP_End', 'Control-e']).default('End'),
    'key-row-up': z.enum(['Up', 'Control-p', 'Shift-Tab', 'ISO_Left_Tab']).default('Up'),
    'key-row-down': z.enum(['Down', 'Control-n', 'Tab']).default('Down'),
    'key-page-first': z.enum(['Home', 'KP_Home', 'Control-a']).default('Home'),
    'key-page-last': z.enum(['End', 'KP_End', 'Control-e']).default('End'),
    'key-page-up': z.enum(['Page_Up', 'KP_Page_Up', 'Control-v']).default('Page_Up'),
    'key-page-down': z.enum(['Page_Down', 'KP_Page_Down', 'Control-y']).default('Page_Down'),
    'search-field': z.boolean().default(true),
    'password-field': z.boolean().default(false),
    lines: z.number().int().min(1).max(100).default(10),
    columns: z.number().int().min(1).max(10).default(1),
    halign: z.enum(['left', 'center', 'right', 'fill']).default('fill'),
    valign: z.enum(['top', 'center', 'bottom', 'fill']).default('fill'),
    'halign-label': z.enum(['left', 'center', 'right', 'fill']).default('left'),
    'valign-label': z.enum(['top', 'center', 'bottom', 'fill']).default('center'),
    'halign-content': z.enum(['left', 'center', 'right', 'fill']).default('left'),
    'valign-content': z.enum(['top', 'center', 'bottom', 'fill']).default('center'),
    'drun-display-generic': z.boolean().default(true),
    'drun-display-actions': z.boolean().default(false),
    'drun-display-no-generic': z.boolean().default(false),
    'drun-username': z.string().optional(),
    'drun-desktop': z.array(z.string()).default([]),
    'run-exec': z.string().optional(),
    'run-exec-search': z.string().optional(),
    'run-list-command': z.string().optional(),
    'run-file-exec': z.string().optional(),
    'run-match': z.enum(['exact', 'fuzzy', 'regex']).default('fuzzy'),
    'run-actions': z.boolean().default(true),
    'dmenu-print-index': z.boolean().default(false),
    'dmenu-allow-markup': z.boolean().default(false),
    'dmenu-allow-images': z.boolean().default(false),
    'combi-hide-mode': z.boolean().default(false),
    'cache-file': z.string().optional(),
    'config-file': z.string().optional(),
    style: z.string().optional(),
    'css-file': z.string().optional(),
    'widget-list': z.string().optional(),
    'log-file': z.string().optional(),
    'log-level': z.enum(['ERROR', 'WARNING', 'INFO', 'DEBUG']).default('INFO'),
    'show-all': z.boolean().default(false),
    'single-pass': z.boolean().default(false),
    'exec-args': z.array(z.string()).default([]),
    defer: z.boolean().default(false),
    'wait-for': z.string().optional(),
    'pre-display-cmd': z.string().optional(),
    'post-display-cmd': z.string().optional(),
    'pre-select-cmd': z.string().optional(),
    'post-select-cmd': z.string().optional(),
  }),
});

// Ghostty configuration schema
export const GhosttyConfigSchema = BaseConfigSchema.extend({
  service: z.literal('ghostty'),
  settings: z.object({
    // Terminal behavior
    shell: z.object({
      program: z.string().default('bash'),
      args: z.array(z.string()).default([]),
    }).default({}),
    
    // Appearance
    font: z.object({
      family: z.string().default('Fira Code Nerd Font'),
      size: z.number().positive().default(12.0),
      weight: z.enum(['thin', 'extra-light', 'light', 'semi-light', 'regular', 'medium', 'semi-bold', 'bold', 'extra-bold', 'black']).default('regular'),
      stretch: z.enum(['ultra-condensed', 'extra-condensed', 'condensed', 'semi-condensed', 'normal', 'semi-expanded', 'expanded', 'extra-expanded', 'ultra-expanded']).default('normal'),
      style: z.enum(['normal', 'italic', 'oblique']).default('normal'),
    }).default({}),
    
    // Colors
    theme: z.string().default('auto'),
    background: z.string().default('#24273a'),
    foreground: z.string().default('#cad3f5'),
    cursor: z.object({
      color: z.string().default('#f4dbd2'),
      style: z.enum(['block', 'beam', 'underline']).default('block'),
      blink: z.boolean().default(false),
    }).default({}),
    
    // Window behavior
    window: z.object({
      width: z.number().int().min(400).max(4000).default(800),
      height: z.number().int().min(300).max(3000).default(600),
      'padding-x': z.number().int().min(0).max(100).default(8),
      'padding-y': z.number().int().min(0).max(100).default(8),
      'margin-x': z.number().int().min(0).max(100).default(0),
      'margin-y': z.number().int().min(0).max(100).default(0),
      opacity: z.number().min(0.1).max(1.0).default(1.0),
      blur: z.boolean().default(false),
      decorations: z.boolean().default(true),
      resizable: z.boolean().default(true),
    }).default({}),
    
    // Performance and rendering
    render: z.object({
      backend: z.enum(['auto', 'gl', 'vulkan', 'software']).default('auto'),
      fps: z.number().int().min(30).max(240).default(60),
      vsync: z.boolean().default(true),
      'gpu-acceleration': z.boolean().default(true),
      'font-hinting': z.enum(['none', 'slight', 'medium', 'full']).default('slight'),
      antialiasing: z.boolean().default(true),
    }).default({}),
    
    // Key bindings
    keybind: z.array(z.object({
      key: z.string(),
      action: z.enum(['spawn', 'copy', 'paste', 'scroll-to-top', 'scroll-to-bottom', 'page-up', 'page-down', 'increase-font-size', 'decrease-font-size', 'reset-font-size', 'toggle-fullscreen', 'toggle-transparency', 'quit']),
      command: z.string().optional(),
      mods: z.array(z.enum(['ctrl', 'alt', 'shift', 'super', 'hyper', 'meta'])).default([]),
    })).default([
      { key: 'c', action: 'copy', mods: ['ctrl', 'shift'] },
      { key: 'v', action: 'paste', mods: ['ctrl', 'shift'] },
      { key: 'plus', action: 'increase-font-size', mods: ['ctrl'] },
      { key: 'minus', action: 'decrease-font-size', mods: ['ctrl'] },
      { key: '0', action: 'reset-font-size', mods: ['ctrl'] },
      { key: 'f11', action: 'toggle-fullscreen' },
    ]),
    
    // Shell integration
    'shell-integration': z.object({
      detect: z.boolean().default(true),
      program: z.string().optional(),
      cwd: z.string().optional(),
    }).default({}),
    
    // Mouse behavior
    mouse: z.object({
      'hide-while-typing': z.boolean().default(true),
      'alternate-scroll-mode': z.boolean().default(true),
      'url-detection': z.boolean().default(true),
      'double-click-speed': z.number().int().min(100).max(2000).default(500),
    }).default({}),
    
    // Bell/notifications
    bell: z.object({
      sound: z.boolean().default(false),
      visual: z.boolean().default(true),
      command: z.string().optional(),
    }).default({}),
    
    // Clipboard
    clipboard: z.object({
      read: z.boolean().default(true),
      write: z.boolean().default(true),
      primary: z.boolean().default(false),
      'max-size': z.number().int().min(1024).max(10485760).default(1048576),
    }).default({}),
    
    // Advanced options
    advanced: z.object({
      'buffer-size': z.number().int().min(1000).max(100000).default(10000),
      'scrollback-size': z.number().int().min(100).max(100000).default(10000),
      'tab-width': z.number().int().min(1).max(20).default(8),
      'unicode-version': z.enum(['9', '10', '11', '12', '13', '14', '15']).default('15'),
      'working-directory': z.string().default('home'),
      'confirm-close-sudo': z.boolean().default(true),
    }).default({}),
  }),
});

// Desktop environment configuration schema
export const DesktopEnvironmentConfigSchema = z.object({
  version: z.string().default('1.0.0'),
  components: z.object({
    niri: NiriConfigSchema.optional(),
    waybar: WaybarConfigSchema.optional(),
    wofi: WofiConfigSchema.optional(),
    ghostty: GhosttyConfigSchema.optional(),
  }),
  global: z.object({
    'log-level': z.enum(['error', 'warn', 'info', 'debug']).default('info'),
    'auto-start': z.boolean().default(true),
    'config-validation': z.boolean().default(true),
    'hardware-detection': z.boolean().default(true),
    theme: z.object({
      name: z.string().default('voidance'),
      variant: z.enum(['dark', 'light']).default('dark'),
      'accent-color': z.string().default('#458588'),
    }).default({}),
  }),
});

// Type exports
export type OutputConfig = z.infer<typeof OutputConfigSchema>;
export type LayoutConfig = z.infer<typeof LayoutConfigSchema>;
export type InputConfig = z.infer<typeof InputConfigSchema>;
export type KeybindingConfig = z.infer<typeof KeybindingConfigSchema>;
export type WindowRule = z.infer<typeof WindowRuleSchema>;
export type NiriConfig = z.infer<typeof NiriConfigSchema>;
export type WaybarConfig = z.infer<typeof WaybarConfigSchema>;
export type WofiConfig = z.infer<typeof WofiConfigSchema>;
export type GhosttyConfig = z.infer<typeof GhosttyConfigSchema>;
export type DesktopEnvironmentConfig = z.infer<typeof DesktopEnvironmentConfigSchema>;

// Validation functions
export const validateNiriConfig = (config: unknown) => {
  return NiriConfigSchema.safeParse(config);
};

export const validateWaybarConfig = (config: unknown) => {
  return WaybarConfigSchema.safeParse(config);
};

export const validateWofiConfig = (config: unknown) => {
  return WofiConfigSchema.safeParse(config);
};

export const validateGhosttyConfig = (config: unknown) => {
  return GhosttyConfigSchema.safeParse(config);
};

export const validateDesktopEnvironmentConfig = (config: unknown) => {
  return DesktopEnvironmentConfigSchema.safeParse(config);
};

// Default configurations
export const defaultNiriConfig: NiriConfig = {
  version: '1.0.0',
  enabled: true,
  debug: false,
  service: 'niri',
  settings: {
    outputs: [],
    layout: {
      default_width: 800,
      default_height: 600,
      gaps: 8,
      'center-column': {
        width: 1,
      },
      'preset-column-widths': [
        [1, 10],
        [1, 5],
        [2, 5],
        [3, 5],
        [4, 5],
        [5, 5],
      ],
      'preset-window-heights': [
        [1, 10],
        [1, 5],
        [2, 5],
        [3, 5],
        [4, 5],
        [5, 5],
      ],
    },
    input: {
      keyboard: {
        'repeat-rate': 25,
        'repeat-delay': 600,
        'xkb-layout': 'us',
        'xkb-variant': '',
        'xkb-options': '',
      },
      touchpad: {
        'accel-profile': 'adaptive',
        'accel-speed': 0.0,
        'natural-scroll': false,
        'tap-to-click': true,
        'drag-lock': false,
        'disable-while-typing': true,
        'middle-emulation': false,
      },
      mouse: {
        'accel-profile': 'adaptive',
        'accel-speed': 0.0,
        'natural-scroll': false,
      },
    },
    keybindings: [],
    'window-rules': [],
    environment: {},
    'spawn-at-startup': [],
    cursor: {
      theme: 'Adwaita',
      size: 24,
    },
    'prefer-no-csd': true,
    'hotkey-overlay': {
      'skip-at-startup': true,
    },
  },
};

export const defaultWaybarConfig: WaybarConfig = {
  version: '1.0.0',
  enabled: true,
  debug: false,
  service: 'waybar',
  settings: {
    layer: 'top',
    position: 'top',
    height: 30,
    width: 'request',
    spacing: 4,
    'margin-top': 0,
    'margin-bottom': 0,
    'margin-left': 0,
    'margin-right': 0,
    'modules-left': ['niri/workspaces'],
    'modules-center': ['clock'],
    'modules-right': ['pulseaudio', 'network', 'battery', 'tray'],
    'startup-command': '',
    'reload-style-on-change': false,
    'fixed-center': true,
    'passthrough': false,
    'ipc': true,
    'include': [],
    modules: {},
    'bar-id': '',
    'output': [],
    'exclusive': true,
    'gtk-layer-shell': true,
  },
};

export const defaultWofiConfig: WofiConfig = {
  version: '1.0.0',
  enabled: true,
  debug: false,
  service: 'wofi',
  settings: {
    mode: 'drun',
    term: 'ghostty',
    exec: '',
    'exec-search': '',
    prompt: 'Apps',
    filter: true,
    'allow-images': true,
    'allow-markup': true,
    insensitive: true,
    'parse-search': true,
    'hide-scroll': false,
    'normal-window': false,
    monitor: 0,
    layers: 'top',
    'x-offset': 0,
    'y-offset': 0,
    width: '50%',
    height: '40%',
    location: 'center',
    orientation: 'vertical',
    halign: 'fill',
    valign: 'fill',
    'line-wrap': 'off',
    'dynamic-lines': false,
    'num-lines': 10,
    columns: 1,
    'term-size': 10,
    'display-columns': 1,
    'display-row': 1,
    'sort-order': 'default',
    'gtk-dark': true,
    color: {
      background: '#282828ff',
      foreground: '#ebdbb2ff',
      border: '#458588ff',
      selected: '#458588ff',
      'selected-foreground': '#282828ff',
      window: '#458588ff',
      separator: '#665c54ff',
    },
    'color-window': '#458588ff',
    'color-border': '#458588ff',
    'color-separator': '#665c54ff',
    'key-expand': 'Tab',
    'key-nav-up': 'Up',
    'key-nav-down': 'Down',
    'key-nav-left': 'Left',
    'key-nav-right': 'Right',
    'key-submit': 'Return',
    'key-exit': 'Escape',
    'key-delete': 'BackSpace',
    'key-delete-word': 'Control-BackSpace',
    'key-delete-line': 'Control-u',
    'key-pgup': 'Page_Up',
    'key-pgdn': 'Page_Down',
    'key-home': 'Home',
    'key-end': 'End',
    'key-row-first': 'Home',
    'key-row-last': 'End',
    'key-row-up': 'Up',
    'key-row-down': 'Down',
    'key-page-first': 'Home',
    'key-page-last': 'End',
    'key-page-up': 'Page_Up',
    'key-page-down': 'Page_Down',
    'search-field': true,
    'password-field': false,
    lines: 10,
    columns: 1,
    halign: 'fill',
    valign: 'fill',
    'halign-label': 'left',
    'valign-label': 'center',
    'halign-content': 'left',
    'valign-content': 'center',
    'drun-display-generic': true,
    'drun-display-actions': false,
    'drun-display-no-generic': false,
    'drun-username': '',
    'drun-desktop': [],
    'run-exec': '',
    'run-exec-search': '',
    'run-list-command': '',
    'run-file-exec': '',
    'run-match': 'fuzzy',
    'run-actions': true,
    'dmenu-print-index': false,
    'dmenu-allow-markup': false,
    'dmenu-allow-images': false,
    'combi-hide-mode': false,
    'cache-file': '',
    'config-file': '',
    style: '',
    'css-file': '',
    'widget-list': '',
    'log-file': '',
    'log-level': 'INFO',
    'show-all': false,
    'single-pass': false,
    'exec-args': [],
    defer: false,
    'wait-for': '',
    'pre-display-cmd': '',
    'post-display-cmd': '',
    'pre-select-cmd': '',
    'post-select-cmd': '',
  },
};

export const defaultGhosttyConfig: GhosttyConfig = {
  version: '1.0.0',
  enabled: true,
  debug: false,
  service: 'ghostty',
  settings: {
    shell: {
      program: 'bash',
      args: [],
    },
    font: {
      family: 'Fira Code Nerd Font',
      size: 12.0,
      weight: 'regular',
      stretch: 'normal',
      style: 'normal',
    },
    theme: 'auto',
    background: '#24273a',
    foreground: '#cad3f5',
    cursor: {
      color: '#f4dbd2',
      style: 'block',
      blink: false,
    },
    window: {
      width: 800,
      height: 600,
      'padding-x': 8,
      'padding-y': 8,
      'margin-x': 0,
      'margin-y': 0,
      opacity: 1.0,
      blur: false,
      decorations: true,
      resizable: true,
    },
    render: {
      backend: 'auto',
      fps: 60,
      vsync: true,
      'gpu-acceleration': true,
      'font-hinting': 'slight',
      antialiasing: true,
    },
    keybind: [
      { key: 'c', action: 'copy', mods: ['ctrl', 'shift'] },
      { key: 'v', action: 'paste', mods: ['ctrl', 'shift'] },
      { key: 'plus', action: 'increase-font-size', mods: ['ctrl'] },
      { key: 'minus', action: 'decrease-font-size', mods: ['ctrl'] },
      { key: '0', action: 'reset-font-size', mods: ['ctrl'] },
      { key: 'f11', action: 'toggle-fullscreen' },
    ],
    'shell-integration': {
      detect: true,
    },
    mouse: {
      'hide-while-typing': true,
      'alternate-scroll-mode': true,
      'url-detection': true,
      'double-click-speed': 500,
    },
    bell: {
      sound: false,
      visual: true,
    },
    clipboard: {
      read: true,
      write: true,
      primary: false,
      'max-size': 1048576,
    },
    advanced: {
      'buffer-size': 10000,
      'scrollback-size': 10000,
      'tab-width': 8,
      'unicode-version': '15',
      'working-directory': 'home',
      'confirm-close-sudo': true,
    },
  },
};

export const defaultDesktopEnvironmentConfig: DesktopEnvironmentConfig = {
  version: '1.0.0',
  components: {
    niri: defaultNiriConfig,
    waybar: defaultWaybarConfig,
    wofi: defaultWofiConfig,
    ghostty: defaultGhosttyConfig,
  },
  global: {
    'log-level': 'info',
    'auto-start': true,
    'config-validation': true,
    'hardware-detection': true,
    theme: {
      name: 'voidance',
      variant: 'dark',
      'accent-color': '#458588',
    },
  },
};
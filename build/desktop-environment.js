"use strict";
// Zod schemas for Voidance Linux desktop environment configuration
// Provides type-safe configuration validation for Niri, Waybar, and wofi
Object.defineProperty(exports, "__esModule", { value: true });
exports.defaultDesktopEnvironmentConfig = exports.defaultGhosttyConfig = exports.defaultWofiConfig = exports.defaultWaybarConfig = exports.defaultNiriConfig = exports.validateDesktopEnvironmentConfig = exports.validateGhosttyConfig = exports.validateWofiConfig = exports.validateWaybarConfig = exports.validateNiriConfig = exports.DesktopEnvironmentConfigSchema = exports.GhosttyConfigSchema = exports.WofiConfigSchema = exports.WaybarConfigSchema = exports.NiriConfigSchema = void 0;
const zod_1 = require("zod");
// Base configuration schema
const BaseConfigSchema = zod_1.z.object({
    version: zod_1.z.string().default('1.0.0'),
    enabled: zod_1.z.boolean().default(true),
    debug: zod_1.z.boolean().default(false),
});
// Output configuration schema
const OutputConfigSchema = zod_1.z.object({
    name: zod_1.z.string(),
    mode: zod_1.z.object({
        width: zod_1.z.number().int().positive(),
        height: zod_1.z.number().int().positive(),
        refresh: zod_1.z.number().positive().optional(),
    }).optional(),
    position: zod_1.z.object({
        x: zod_1.z.number().int(),
        y: zod_1.z.number().int(),
    }).optional(),
    scale: zod_1.z.number().positive().default(1.0),
    transform: zod_1.z.enum(['normal', '90', '180', '270', 'flipped', 'flipped-90', 'flipped-180', 'flipped-270']).default('normal'),
    adaptive_sync: zod_1.z.boolean().default(false),
    background_color: zod_1.z.string().regex(/^#[0-9a-fA-F]{6}$/).default('#24273a'),
});
// Layout configuration schema
const LayoutConfigSchema = zod_1.z.object({
    default_width: zod_1.z.number().int().min(100).max(2000).default(800),
    default_height: zod_1.z.number().int().min(100).max(2000).default(600),
    gaps: zod_1.z.number().int().min(0).max(100).default(8),
    center_column: zod_1.z.object({
        width: zod_1.z.number().int().min(1).max(10).default(1),
    }).optional(),
    preset_column_widths: zod_1.z.array(zod_1.z.array(zod_1.z.number().int().positive())).default([
        [1, 10],
        [1, 5],
        [2, 5],
        [3, 5],
        [4, 5],
        [5, 5],
    ]),
    preset_window_heights: zod_1.z.array(zod_1.z.array(zod_1.z.number().int().positive())).default([
        [1, 10],
        [1, 5],
        [2, 5],
        [3, 5],
        [4, 5],
        [5, 5],
    ]),
});
// Input configuration schema
const InputConfigSchema = zod_1.z.object({
    name: zod_1.z.string(),
    type: zod_1.z.enum(['keyboard', 'pointer', 'touch', 'tablet']),
    settings: zod_1.z.object({
        repeat_rate: zod_1.z.number().int().min(1).max(100).default(25),
        repeat_delay: zod_1.z.number().int().min(100).max(2000).default(600),
        accel_profile: zod_1.z.enum(['none', 'flat', 'adaptive']).default('adaptive'),
        accel_speed: zod_1.z.number().min(-1.0).max(1.0).default(0.0),
        natural_scroll: zod_1.z.boolean().default(false),
        left_handed: zod_1.z.boolean().default(false),
        tap_to_click: zod_1.z.boolean().default(true),
        drag_lock: zod_1.z.boolean().default(false),
        disable_while_typing: zod_1.z.boolean().default(true),
        middle_emulation: zod_1.z.boolean().default(false),
    }).optional(),
});
// Keybinding configuration schema
const KeybindingConfigSchema = zod_1.z.object({
    modifiers: zod_1.z.array(zod_1.z.enum(['Ctrl', 'Alt', 'Shift', 'Super', 'Hyper', 'Meta'])),
    key: zod_1.z.string(),
    action: zod_1.z.enum(['spawn', 'close', 'fullscreen', 'focus', 'move', 'resize', 'quit', 'reload']),
    command: zod_1.z.string().optional(),
    direction: zod_1.z.enum(['left', 'right', 'up', 'down']).optional(),
    workspace: zod_1.z.number().int().positive().optional(),
});
// Window rule configuration schema
const WindowRuleSchema = zod_1.z.object({
    app_id: zod_1.z.string().optional(),
    title: zod_1.z.string().optional(),
    output: zod_1.z.string().optional(),
    width: zod_1.z.number().int().positive().optional(),
    height: zod_1.z.number().int().positive().optional(),
    x: zod_1.z.number().int().optional(),
    y: zod_1.z.number().int().optional(),
    floating: zod_1.z.boolean().optional(),
    fullscreen: zod_1.z.boolean().optional(),
    pinned: zod_1.z.boolean().optional(),
    focused: zod_1.z.boolean().optional(),
    opacity: zod_1.z.number().min(0.0).max(1.0).optional(),
});
// Niri configuration schema
exports.NiriConfigSchema = BaseConfigSchema.extend({
    service: zod_1.z.literal('niri'),
    settings: zod_1.z.object({
        outputs: zod_1.z.array(OutputConfigSchema).default([]),
        layout: LayoutConfigSchema.default({}),
        input: zod_1.z.object({
            keyboard: zod_1.z.object({
                repeat_rate: zod_1.z.number().int().min(1).max(100).default(25),
                repeat_delay: zod_1.z.number().int().min(100).max(2000).default(600),
                xkb_layout: zod_1.z.string().default('us'),
                xkb_variant: zod_1.z.string().default(''),
                xkb_options: zod_1.z.string().default(''),
            }).default({}),
            touchpad: zod_1.z.object({
                accel_profile: zod_1.z.enum(['none', 'flat', 'adaptive']).default('adaptive'),
                accel_speed: zod_1.z.number().min(-1.0).max(1.0).default(0.0),
                natural_scroll: zod_1.z.boolean().default(false),
                tap_to_click: zod_1.z.boolean().default(true),
                drag_lock: zod_1.z.boolean().default(false),
                disable_while_typing: zod_1.z.boolean().default(true),
                middle_emulation: zod_1.z.boolean().default(false),
            }).default({}),
            mouse: zod_1.z.object({
                accel_profile: zod_1.z.enum(['none', 'flat', 'adaptive']).default('adaptive'),
                accel_speed: zod_1.z.number().min(-1.0).max(1.0).default(0.0),
                natural_scroll: zod_1.z.boolean().default(false),
            }).default({}),
        }),
        keybindings: zod_1.z.array(KeybindingConfigSchema).default([]),
        window_rules: zod_1.z.array(WindowRuleSchema).default([]),
        environment: zod_1.z.record(zod_1.z.string()).default({}),
        spawn_at_startup: zod_1.z.array(zod_1.z.object({
            command: zod_1.z.array(zod_1.z.string()),
        })).default([]),
        cursor: zod_1.z.object({
            theme: zod_1.z.string().default('Adwaita'),
            size: zod_1.z.number().int().min(8).max(128).default(24),
        }).default({}),
        prefer_no_csd: zod_1.z.boolean().default(true),
        hotkey_overlay: zod_1.z.object({
            skip_at_startup: zod_1.z.boolean().default(true),
        }).default({}),
    }),
});
// Waybar module configuration schema
const WaybarModuleSchema = zod_1.z.object({
    type: zod_1.z.enum([
        'custom', 'battery', 'backlight', 'clock', 'cpu', 'disk', 'idle_inhibitor',
        'memory', 'mpd', 'network', 'pulseaudio', 'river', 'river/tags', 'river/layout',
        'river/mode', 'river/window', 'scratchpad', 'sway/mode', 'sway/workspaces',
        'sway/window', 'sway/scratchpad', 'temperature', 'tray', 'upower', 'wireplumber'
    ]),
    format: zod_1.z.string().optional(),
    format
} - alt, zod_1.z.string().optional(), interval, zod_1.z.number().int().positive().optional(), tooltip, zod_1.z.boolean().default(true), tooltip - format, zod_1.z.string().optional(), 'min-length', zod_1.z.number().int().positive().optional(), 'max-length', zod_1.z.number().int().positive().optional(), align, zod_1.z.enum(['left', 'center', 'right']).optional(), rotate, zod_1.z.number().int().multipleOf(90).optional(), 'on-click', zod_1.z.string().optional(), 'on-click-right', zod_1.z.string().optional(), 'on-click-middle', zod_1.z.string().optional(), 'on-scroll-up', zod_1.z.string().optional(), 'on-scroll-down', zod_1.z.string().optional(), 'smooth-scrolling-threshold', zod_1.z.number().int().positive().optional(), 'format-icons', zod_1.z.record(zod_1.z.string()).optional(), 'format-alt-icons', zod_1.z.record(zod_1.z.string()).optional(), 'format-disconnected', zod_1.z.string().optional(), 'format-connected', zod_1.z.string().optional(), 'format-alt-connected', zod_1.z.string().optional(), 'format-padding', zod_1.z.string().optional(), 'format-time', zod_1.z.string().optional(), 'format-date', zod_1.z.string().optional(), timezone, zod_1.z.string().optional(), locale, zod_1.z.string().optional(), 'time-format', zod_1.z.string().optional(), 'date-format', zod_1.z.string().optional(), 'format-charging', zod_1.z.string().optional(), 'format-plugged', zod_1.z.string().optional(), 'format-full', zod_1.z.string().optional(), 'format-low', zod_1.z.string().optional(), 'format-medium', zod_1.z.string().optional(), 'format-high', zod_1.z.string().optional(), 'format-critical', zod_1.z.string().optional(), 'bat', zod_1.z.string().optional(), 'adapter', zod_1.z.string().optional(), 'interface', zod_1.z.string().optional(), 'format-device', zod_1.z.string().optional(), 'format-mounted', zod_1.z.string().optional(), 'format-unmounted', zod_1.z.string().optional(), 'format-not-mounted', zod_1.z.string().optional(), 'nodes', zod_1.z.array(zod_1.z.string()).optional(), 'ignored-sinks', zod_1.z.array(zod_1.z.string()).optional(), 'max-volume', zod_1.z.number().int().min(0).max(200).default(100), 'scroll-step', zod_1.z.number().int().min(1).max(20).default(1), 'on-click-middle', zod_1.z.string().optional(), 'reverse-scrolling', zod_1.z.boolean().default(false), 'format-source', zod_1.z.string().optional(), 'format-source-muted', zod_1.z.string().optional(), 'tooltip-format-source', zod_1.z.string().optional(), 'thermal-zone', zod_1.z.number().int().optional(), 'hwmon-path', zod_1.z.string().optional(), 'hwmon-path-abs', zod_1.z.string().optional(), 'input-filename', zod_1.z.string().optional(), 'critical-threshold', zod_1.z.number().int().optional());
;
// Waybar configuration schema
exports.WaybarConfigSchema = BaseConfigSchema.extend({
    service: zod_1.z.literal('waybar'),
    settings: zod_1.z.object({
        layer: zod_1.z.enum(['top', 'bottom', 'overlay']).default('top'),
        position: zod_1.z.enum(['top', 'bottom', 'left', 'right']).default('top'),
        height: zod_1.z.number().int().min(10).max(200).default(30),
        width: zod_1.z.enum(['auto', 'request']).default('request'),
        spacing: zod_1.z.number().int().min(0).max(50).default(4),
        'margin-top': zod_1.z.number().int().min(0).max(100).default(0),
        'margin-bottom': zod_1.z.number().int().min(0).max(100).default(0),
        'margin-left': zod_1.z.number().int().min(0).max(100).default(0),
        'margin-right': zod_1.z.number().int().min(0).max(100).default(0),
        'modules-left': zod_1.z.array(zod_1.z.string()).default(['niri/workspaces']),
        'modules-center': zod_1.z.array(zod_1.z.string()).default(['clock']),
        'modules-right': zod_1.z.array(zod_1.z.string()).default(['pulseaudio', 'network', 'battery', 'tray']),
        'startup-command': zod_1.z.string().optional(),
        'reload-style-on-change': zod_1.z.boolean().default(false),
        'fixed-center': zod_1.z.boolean().default(true),
        'passthrough': zod_1.z.boolean().default(false),
        'ipc': zod_1.z.boolean().default(true),
        'include': zod_1.z.array(zod_1.z.string()).default([]),
        modules: zod_1.z.record(WaybarModuleSchema).default({}),
        'bar-id': zod_1.z.string().optional(),
        'output': zod_1.z.array(zod_1.z.string()).optional(),
        'exclusive': zod_1.z.boolean().default(true),
        'gtk-layer-shell': zod_1.z.boolean().default(true),
    }),
});
// wofi configuration schema
exports.WofiConfigSchema = BaseConfigSchema.extend({
    service: zod_1.z.literal('wofi'),
    settings: zod_1.z.object({
        mode: zod_1.z.enum(['drun', 'run', 'dmenu', 'combi']).default('drun'),
        term: zod_1.z.string().default('ghostty'),
        exec: zod_1.z.string().optional(),
        'exec-search': zod_1.z.string().optional(),
        prompt: zod_1.z.string().default('Apps'),
        filter: zod_1.z.boolean().default(true),
        'allow-images': zod_1.z.boolean().default(true),
        'allow-markup': zod_1.z.boolean().default(true),
        insensitive: zod_1.z.boolean().default(true),
        'parse-search': zod_1.z.boolean().default(true),
        'hide-scroll': zod_1.z.boolean().default(false),
        'normal-window': zod_1.z.boolean().default(false),
        monitor: zod_1.z.number().int().min(0).default(0),
        layers: zod_1.z.enum(['top', 'bottom', 'background', 'overlay']).default('top'),
        'x-offset': zod_1.z.number().int().default(0),
        'y-offset': zod_1.z.number().int().default(0),
        width: zod_1.z.union([zod_1.z.number().int().positive(), zod_1.z.string()]).default('50%'),
        height: zod_1.z.union([zod_1.z.number().int().positive(), zod_1.z.string()]).default('40%'),
        location: zod_1.z.enum(['top-left', 'top-center', 'top-right', 'center-left', 'center', 'center-right', 'bottom-left', 'bottom-center', 'bottom-right']).default('center'),
        orientation: zod_1.z.enum(['horizontal', 'vertical']).default('vertical'),
        halign: zod_1.z.enum(['left', 'center', 'right']).default('fill'),
        valign: zod_1.z.enum(['top', 'center', 'bottom']).default('fill'),
        line_wrap: zod_1.z.enum(['off', 'word', 'char', 'word_char']).default('off'),
        dynamic_lines: zod_1.z.boolean().default(false),
        num_lines: zod_1.z.number().int().min(1).max(100).default(10),
        columns: zod_1.z.number().int().min(1).max(10).default(1),
        'term-size': zod_1.z.number().int().min(1).max(100).default(10),
        'display-columns': zod_1.z.number().int().min(1).max(10).default(1),
        'display-row': zod_1.z.number().int().min(1).max(100).default(1),
        'sort-order': zod_1.z.enum(['default', 'alphabetical']).default('default'),
        'gtk-dark': zod_1.z.boolean().default(true),
        color: zod_1.z.object({
            background: zod_1.z.string().default('#282828ff'),
            foreground: zod_1.z.string().default('#ebdbb2ff'),
            border: zod_1.z.string().default('#458588ff'),
            selected: zod_1.z.string().default('#458588ff'),
            'selected-foreground': zod_1.z.string().default('#282828ff'),
            window: zod_1.z.string().default('#458588ff'),
            separator: zod_1.z.string().default('#665c54ff'),
        }).default({}),
        'color-window': zod_1.z.string().default('#458588ff'),
        'color-border': zod_1.z.string().default('#458588ff'),
        'color-separator': zod_1.z.string().default('#665c54ff'),
        'color-row-bg': zod_1.z.string().optional(),
        'color-row-fg': zod_1.z.string().optional(),
        'color-row-bg-alt': zod_1.z.string().optional(),
        'color-row-fg-alt': zod_1.z.string().optional(),
        'color-row-bg-selected': zod_1.z.string().optional(),
        'color-row-fg-selected': zod_1.z.string().optional(),
        'color-row-bg-active': zod_1.z.string().optional(),
        'color-row-fg-active': zod_1.z.string().optional(),
        'key-expand': zod_1.z.enum(['Tab', 'ISO_Left_Tab', 'Down', 'Control-bracketleft', 'grave']).default('Tab'),
        'key-nav-up': zod_1.z.enum(['Up', 'Control-p', 'Shift-Tab', 'ISO_Left_Tab']).default('Up'),
        'key-nav-down': zod_1.z.enum(['Down', 'Control-n', 'Tab']).default('Down'),
        'key-nav-left': zod_1.z.enum(['Left', 'Control-b']).default('Left'),
        'key-nav-right': zod_1.z.enum(['Right', 'Control-f']).default('Right'),
        'key-submit': zod_1.z.enum(['Return', 'KP_Enter', 'Control-m', 'Control-j']).default('Return'),
        'key-exit': zod_1.z.enum(['Escape', 'Control-g', 'Control-c']).default('Escape'),
        'key-delete': zod_1.z.enum(['BackSpace', 'Delete', 'Control-h']).default('BackSpace'),
        'key-delete-word': zod_1.z.enum(['Control-BackSpace', 'Control-w']).default('Control-BackSpace'),
        'key-delete-line': zod_1.z.enum(['Control-u']).default('Control-u'),
        'key-pgup': zod_1.z.enum(['Page_Up', 'KP_Page_Up', 'Control-v']).default('Page_Up'),
        'key-pgdn': zod_1.z.enum(['Page_Down', 'KP_Page_Down', 'Control-y']).default('Page_Down'),
        'key-home': zod_1.z.enum(['Home', 'KP_Home', 'Control-a']).default('Home'),
        'key-end': zod_1.z.enum(['End', 'KP_End', 'Control-e']).default('End'),
        'key-row-first': zod_1.z.enum(['Home', 'KP_Home', 'Control-a']).default('Home'),
        'key-row-last': zod_1.z.enum(['End', 'KP_End', 'Control-e']).default('End'),
        'key-row-up': zod_1.z.enum(['Up', 'Control-p', 'Shift-Tab', 'ISO_Left_Tab']).default('Up'),
        'key-row-down': zod_1.z.enum(['Down', 'Control-n', 'Tab']).default('Down'),
        'key-page-first': zod_1.z.enum(['Home', 'KP_Home', 'Control-a']).default('Home'),
        'key-page-last': zod_1.z.enum(['End', 'KP_End', 'Control-e']).default('End'),
        'key-page-up': zod_1.z.enum(['Page_Up', 'KP_Page_Up', 'Control-v']).default('Page_Up'),
        'key-page-down': zod_1.z.enum(['Page_Down', 'KP_Page_Down', 'Control-y']).default('Page_Down'),
        'search-field': zod_1.z.boolean().default(true),
        'password-field': zod_1.z.boolean().default(false),
        lines: zod_1.z.number().int().min(1).max(100).default(10),
        columns: zod_1.z.number().int().min(1).max(10).default(1),
        halign: zod_1.z.enum(['left', 'center', 'right', 'fill']).default('fill'),
        valign: zod_1.z.enum(['top', 'center', 'bottom', 'fill']).default('fill'),
        'halign-label': zod_1.z.enum(['left', 'center', 'right', 'fill']).default('left'),
        'valign-label': zod_1.z.enum(['top', 'center', 'bottom', 'fill']).default('center'),
        'halign-content': zod_1.z.enum(['left', 'center', 'right', 'fill']).default('left'),
        'valign-content': zod_1.z.enum(['top', 'center', 'bottom', 'fill']).default('center'),
        'drun-display-generic': zod_1.z.boolean().default(true),
        'drun-display-actions': zod_1.z.boolean().default(false),
        'drun-display-no-generic': zod_1.z.boolean().default(false),
        'drun-username': zod_1.z.string().optional(),
        'drun-desktop': zod_1.z.array(zod_1.z.string()).default([]),
        'run-exec': zod_1.z.string().optional(),
        'run-exec-search': zod_1.z.string().optional(),
        'run-list-command': zod_1.z.string().optional(),
        'run-file-exec': zod_1.z.string().optional(),
        'run-match': zod_1.z.enum(['exact', 'fuzzy', 'regex']).default('fuzzy'),
        'run-actions': zod_1.z.boolean().default(true),
        'dmenu-print-index': zod_1.z.boolean().default(false),
        'dmenu-allow-markup': zod_1.z.boolean().default(false),
        'dmenu-allow-images': zod_1.z.boolean().default(false),
        'combi-hide-mode': zod_1.z.boolean().default(false),
        'cache-file': zod_1.z.string().optional(),
        'config-file': zod_1.z.string().optional(),
        style: zod_1.z.string().optional(),
        'css-file': zod_1.z.string().optional(),
        'widget-list': zod_1.z.string().optional(),
        'log-file': zod_1.z.string().optional(),
        'log-level': zod_1.z.enum(['ERROR', 'WARNING', 'INFO', 'DEBUG']).default('INFO'),
        'show-all': zod_1.z.boolean().default(false),
        'single-pass': zod_1.z.boolean().default(false),
        'exec-args': zod_1.z.array(zod_1.z.string()).default([]),
        defer: zod_1.z.boolean().default(false),
        'wait-for': zod_1.z.string().optional(),
        'pre-display-cmd': zod_1.z.string().optional(),
        'post-display-cmd': zod_1.z.string().optional(),
        'pre-select-cmd': zod_1.z.string().optional(),
        'post-select-cmd': zod_1.z.string().optional(),
    }),
});
// Ghostty configuration schema
exports.GhosttyConfigSchema = BaseConfigSchema.extend({
    service: zod_1.z.literal('ghostty'),
    settings: zod_1.z.object({
        // Terminal behavior
        shell: zod_1.z.object({
            program: zod_1.z.string().default('bash'),
            args: zod_1.z.array(zod_1.z.string()).default([]),
        }).default({}),
        // Appearance
        font: zod_1.z.object({
            family: zod_1.z.string().default('Fira Code Nerd Font'),
            size: zod_1.z.number().positive().default(12.0),
            weight: zod_1.z.enum(['thin', 'extra-light', 'light', 'semi-light', 'regular', 'medium', 'semi-bold', 'bold', 'extra-bold', 'black']).default('regular'),
            stretch: zod_1.z.enum(['ultra-condensed', 'extra-condensed', 'condensed', 'semi-condensed', 'normal', 'semi-expanded', 'expanded', 'extra-expanded', 'ultra-expanded']).default('normal'),
            style: zod_1.z.enum(['normal', 'italic', 'oblique']).default('normal'),
        }).default({}),
        // Colors
        theme: zod_1.z.string().default('auto'),
        background: zod_1.z.string().default('#24273a'),
        foreground: zod_1.z.string().default('#cad3f5'),
        cursor: zod_1.z.object({
            color: zod_1.z.string().default('#f4dbd2'),
            style: zod_1.z.enum(['block', 'beam', 'underline']).default('block'),
            blink: zod_1.z.boolean().default(false),
        }).default({}),
        // Window behavior
        window: zod_1.z.object({
            width: zod_1.z.number().int().min(400).max(4000).default(800),
            height: zod_1.z.number().int().min(300).max(3000).default(600),
            'padding-x': zod_1.z.number().int().min(0).max(100).default(8),
            'padding-y': zod_1.z.number().int().min(0).max(100).default(8),
            'margin-x': zod_1.z.number().int().min(0).max(100).default(0),
            'margin-y': zod_1.z.number().int().min(0).max(100).default(0),
            opacity: zod_1.z.number().min(0.1).max(1.0).default(1.0),
            blur: zod_1.z.boolean().default(false),
            decorations: zod_1.z.boolean().default(true),
            resizable: zod_1.z.boolean().default(true),
        }).default({}),
        // Performance and rendering
        render: zod_1.z.object({
            backend: zod_1.z.enum(['auto', 'gl', 'vulkan', 'software']).default('auto'),
            fps: zod_1.z.number().int().min(30).max(240).default(60),
            vsync: zod_1.z.boolean().default(true),
            'gpu-acceleration': zod_1.z.boolean().default(true),
            'font-hinting': zod_1.z.enum(['none', 'slight', 'medium', 'full']).default('slight'),
            antialiasing: zod_1.z.boolean().default(true),
        }).default({}),
        // Key bindings
        keybind: zod_1.z.array(zod_1.z.object({
            key: zod_1.z.string(),
            action: zod_1.z.enum(['spawn', 'copy', 'paste', 'scroll-to-top', 'scroll-to-bottom', 'page-up', 'page-down', 'increase-font-size', 'decrease-font-size', 'reset-font-size', 'toggle-fullscreen', 'toggle-transparency', 'quit']),
            command: zod_1.z.string().optional(),
            mods: zod_1.z.array(zod_1.z.enum(['ctrl', 'alt', 'shift', 'super', 'hyper', 'meta'])).default([]),
        })).default([
            { key: 'c', action: 'copy', mods: ['ctrl', 'shift'] },
            { key: 'v', action: 'paste', mods: ['ctrl', 'shift'] },
            { key: 'plus', action: 'increase-font-size', mods: ['ctrl'] },
            { key: 'minus', action: 'decrease-font-size', mods: ['ctrl'] },
            { key: '0', action: 'reset-font-size', mods: ['ctrl'] },
            { key: 'f11', action: 'toggle-fullscreen' },
        ]),
        // Shell integration
        'shell-integration': zod_1.z.object({
            detect: zod_1.z.boolean().default(true),
            program: zod_1.z.string().optional(),
            cwd: zod_1.z.string().optional(),
        }).default({}),
        // Mouse behavior
        mouse: zod_1.z.object({
            'hide-while-typing': zod_1.z.boolean().default(true),
            'alternate-scroll-mode': zod_1.z.boolean().default(true),
            'url-detection': zod_1.z.boolean().default(true),
            'double-click-speed': zod_1.z.number().int().min(100).max(2000).default(500),
        }).default({}),
        // Bell/notifications
        bell: zod_1.z.object({
            sound: zod_1.z.boolean().default(false),
            visual: zod_1.z.boolean().default(true),
            command: zod_1.z.string().optional(),
        }).default({}),
        // Clipboard
        clipboard: zod_1.z.object({
            read: zod_1.z.boolean().default(true),
            write: zod_1.z.boolean().default(true),
            primary: zod_1.z.boolean().default(false),
            'max-size': zod_1.z.number().int().min(1024).max(10485760).default(1048576),
        }).default({}),
        // Advanced options
        advanced: zod_1.z.object({
            'buffer-size': zod_1.z.number().int().min(1000).max(100000).default(10000),
            'scrollback-size': zod_1.z.number().int().min(100).max(100000).default(10000),
            'tab-width': zod_1.z.number().int().min(1).max(20).default(8),
            'unicode-version': zod_1.z.enum(['9', '10', '11', '12', '13', '14', '15']).default('15'),
            'working-directory': zod_1.z.string().default('home'),
            'confirm-close-sudo': zod_1.z.boolean().default(true),
        }).default({}),
    }),
});
// Desktop environment configuration schema
exports.DesktopEnvironmentConfigSchema = zod_1.z.object({
    version: zod_1.z.string().default('1.0.0'),
    components: zod_1.z.object({
        niri: exports.NiriConfigSchema.optional(),
        waybar: exports.WaybarConfigSchema.optional(),
        wofi: exports.WofiConfigSchema.optional(),
        ghostty: exports.GhosttyConfigSchema.optional(),
    }),
    global: zod_1.z.object({
        'log-level': zod_1.z.enum(['error', 'warn', 'info', 'debug']).default('info'),
        'auto-start': zod_1.z.boolean().default(true),
        'config-validation': zod_1.z.boolean().default(true),
        'hardware-detection': zod_1.z.boolean().default(true),
        theme: zod_1.z.object({
            name: zod_1.z.string().default('voidance'),
            variant: zod_1.z.enum(['dark', 'light']).default('dark'),
            'accent-color': zod_1.z.string().default('#458588'),
        }).default({}),
    }),
});
// Validation functions
const validateNiriConfig = (config) => {
    return exports.NiriConfigSchema.safeParse(config);
};
exports.validateNiriConfig = validateNiriConfig;
const validateWaybarConfig = (config) => {
    return exports.WaybarConfigSchema.safeParse(config);
};
exports.validateWaybarConfig = validateWaybarConfig;
const validateWofiConfig = (config) => {
    return exports.WofiConfigSchema.safeParse(config);
};
exports.validateWofiConfig = validateWofiConfig;
const validateGhosttyConfig = (config) => {
    return exports.GhosttyConfigSchema.safeParse(config);
};
exports.validateGhosttyConfig = validateGhosttyConfig;
const validateDesktopEnvironmentConfig = (config) => {
    return exports.DesktopEnvironmentConfigSchema.safeParse(config);
};
exports.validateDesktopEnvironmentConfig = validateDesktopEnvironmentConfig;
// Default configurations
exports.defaultNiriConfig = {
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
exports.defaultWaybarConfig = {
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
exports.defaultWofiConfig = {
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
exports.defaultGhosttyConfig = {
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
exports.defaultDesktopEnvironmentConfig = {
    version: '1.0.0',
    components: {
        niri: exports.defaultNiriConfig,
        waybar: exports.defaultWaybarConfig,
        wofi: exports.defaultWofiConfig,
        ghostty: exports.defaultGhosttyConfig,
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

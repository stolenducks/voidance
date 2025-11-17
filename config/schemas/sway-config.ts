// Zod schema for Sway configuration validation
// Educational: Each schema includes detailed validation rules

import { z } from 'zod';

// =============================================================================
// BASIC CONFIGURATION SCHEMAS
// =============================================================================

// Modifier key schema
export const ModifierKeySchema = z.enum(['Mod1', 'Mod4'], {
    description: 'Modifier key: Mod1 (Alt) or Mod4 (Super/Windows)'
});

// Font configuration schema
export const FontConfigSchema = z.object({
    family: z.string().min(1, 'Font family is required'),
    size: z.number().min(6, 'Font size must be at least 6').max(72, 'Font size must not exceed 72'),
    weight: z.enum(['normal', 'bold']).optional(),
    style: z.enum(['normal', 'italic', 'oblique']).optional()
}, {
    description: 'Font configuration for Sway'
});

// Color schema (hex color codes)
export const ColorSchema = z.string().regex(/^#[0-9a-fA-F]{6}$/, {
    message: 'Color must be a valid hex color code (e.g., #88c0d0)'
});

// =============================================================================
// OUTPUT CONFIGURATION SCHEMAS
// =============================================================================

// Resolution schema
export const ResolutionSchema = z.object({
    width: z.number().min(640, 'Width must be at least 640'),
    height: z.number().min(480, 'Height must be at least 480'),
    refresh: z.number().min(30, 'Refresh rate must be at least 30Hz').optional()
}, {
    description: 'Display resolution configuration'
});

// Position schema
export const PositionSchema = z.object({
    x: z.number().min(0, 'X position must be non-negative'),
    y: z.number().min(0, 'Y position must be non-negative')
}, {
    description: 'Display position configuration'
});

// Output configuration schema
export const OutputConfigSchema = z.object({
    name: z.string().optional(),
    resolution: ResolutionSchema.optional(),
    position: PositionSchema.optional(),
    scale: z.number().min(0.5, 'Scale must be at least 0.5').max(4, 'Scale must not exceed 4').optional(),
    transform: z.enum(['normal', '90', '180', '270', 'flipped', 'flipped-90', 'flipped-180', 'flipped-270']).optional(),
    background: z.string().optional(),
    mode: z.string().optional(),
    adaptive_sync: z.boolean().optional(),
    max_render_time: z.number().min(0, 'Max render time must be non-negative').optional()
}, {
    description: 'Output configuration for displays'
});

// =============================================================================
// INPUT CONFIGURATION SCHEMAS
// =============================================================================

// Keyboard layout schema
export const KeyboardLayoutSchema = z.object({
    layout: z.string().default('us'),
    variant: z.string().default(''),
    options: z.string().default(''),
    repeat_delay: z.number().min(100, 'Repeat delay must be at least 100ms').max(2000, 'Repeat delay must not exceed 2000ms').optional(),
    repeat_rate: z.number().min(2, 'Repeat rate must be at least 2').max(100, 'Repeat rate must not exceed 100').optional()
}, {
    description: 'Keyboard input configuration'
});

// Touchpad configuration schema
export const TouchpadConfigSchema = z.object({
    tap: z.boolean().optional(),
    natural_scroll: z.boolean().optional(),
    dwt: z.boolean().optional(),
    drag: z.boolean().optional(),
    drag_lock: z.boolean().optional(),
    middle_emulation: z.boolean().optional(),
    scroll_method: z.enum(['none', 'two_finger', 'edge', 'on_button_down']).optional(),
    accel_profile: z.enum(['none', 'flat', 'adaptive']).optional(),
    pointer_accel: z.number().min(-1, 'Pointer acceleration must be at least -1').max(1, 'Pointer acceleration must not exceed 1').optional()
}, {
    description: 'Touchpad input configuration'
});

// Input device configuration schema
export const InputConfigSchema = z.object({
    identifier: z.string().optional(),
    type: z.enum(['keyboard', 'pointer', 'touchpad', 'touch', 'tablet_tool', 'tablet_pad', 'switch']).optional(),
    keyboard: KeyboardLayoutSchema.optional(),
    touchpad: TouchpadConfigSchema.optional(),
    accel_profile: z.enum(['none', 'flat', 'adaptive']).optional(),
    pointer_accel: z.number().min(-1, 'Pointer acceleration must be at least -1').max(1, 'Pointer acceleration must not exceed 1').optional(),
    scroll_factor: z.number().min(0.1, 'Scroll factor must be at least 0.1').max(10, 'Scroll factor must not exceed 10').optional(),
    map_to_output: z.string().optional(),
    map_to_region: z.string().optional()
}, {
    description: 'Input device configuration'
});

// =============================================================================
// WINDOW AND WORKSPACE SCHEMAS
// =============================================================================

// Window border schema
export const WindowBorderSchema = z.enum(['none', 'normal', 'pixel'], {
    description: 'Window border style'
});

// Client state schema
export const ClientStateSchema = z.object({
    border: ColorSchema,
    background: ColorSchema,
    text: ColorSchema,
    indicator: ColorSchema,
    child_border: ColorSchema
}, {
    description: 'Window client state colors'
});

// Workspace configuration schema
export const WorkspaceConfigSchema = z.object({
    number: z.number().min(1, 'Workspace number must be at least 1').max(10, 'Workspace number must not exceed 10'),
    name: z.string().min(1, 'Workspace name is required'),
    output: z.string().optional()
}, {
    description: 'Workspace configuration'
});

// Window rule schema
export const WindowRuleSchema = z.object({
    criteria: z.record(z.string(), z.union([z.string(), z.number(), z.boolean()])),
    commands: z.array(z.string()).min(1, 'At least one command is required')
}, {
    description: 'Window rule configuration'
});

// =============================================================================
// KEYBINDING SCHEMAS
// =============================================================================

// Keybinding schema
export const KeybindingSchema = z.object({
    modifiers: z.array(z.enum(['Mod1', 'Mod4', 'Shift', 'Control'])).min(1, 'At least one modifier is required'),
    key: z.string().min(1, 'Key is required'),
    command: z.string().min(1, 'Command is required'),
    release: z.boolean().optional(),
    whole_window: z.boolean().optional(),
    border: z.boolean().optional(),
    exclude_titlebar: z.boolean().optional(),
    locked: z.boolean().optional(),
    to_focus: z.boolean().optional(),
    group: z.array(z.string()).optional()
}, {
    description: 'Keybinding configuration'
});

// =============================================================================
// BAR CONFIGURATION SCHEMAS
// =============================================================================

// Bar position schema
export const BarPositionSchema = z.enum(['top', 'bottom'], {
    description: 'Bar position'
});

// Bar status command schema
export const BarStatusCommandSchema = z.object({
    command: z.string().min(1, 'Command is required'),
    name: z.string().optional(),
    interval: z.number().min(1, 'Interval must be at least 1').optional()
}, {
    description: 'Bar status command configuration'
});

// Bar workspace button schema
export const BarWorkspaceButtonSchema = z.object({
    workspace: z.number().min(1, 'Workspace number must be at least 1'),
    name: z.string().optional(),
    urgent: z.boolean().optional(),
    focused: z.boolean().optional(),
    visible: z.boolean().optional()
}, {
    description: 'Bar workspace button configuration'
});

// Bar configuration schema
export const BarConfigSchema = z.object({
    id: z.string().min(1, 'Bar ID is required'),
    position: BarPositionSchema.default('top'),
    output: z.union([z.string(), z.array(z.string())]).optional(),
    status_command: z.string().optional(),
    font: z.string().optional(),
    height: z.number().min(10, 'Height must be at least 10').max(100, 'Height must not exceed 100').optional(),
    workspace_buttons: z.boolean().default(true),
    binding_mode_indicator: z.boolean().default(true),
    verbose: z.boolean().optional(),
    pango_markup: z.boolean().optional(),
    colors: z.object({
        background: ColorSchema.optional(),
        statusline: ColorSchema.optional(),
        separator: ColorSchema.optional(),
        focused_workspace: ClientStateSchema.optional(),
        active_workspace: ClientStateSchema.optional(),
        inactive_workspace: ClientStateSchema.optional(),
        urgent_workspace: ClientStateSchema.optional(),
        binding_mode: ClientStateSchema.optional()
    }).optional(),
    tray_output: z.union([z.string(), z.array(z.string())]).optional()
}, {
    description: 'Bar configuration'
});

// =============================================================================
// MAIN SWAY CONFIGURATION SCHEMA
// =============================================================================

// Sway configuration schema
export const SwayConfigSchema = z.object({
    // Basic settings
    modifier: ModifierKeySchema.default('Mod4'),
    terminal: z.string().min(1, 'Terminal command is required'),
    menu: z.string().min(1, 'Menu command is required'),
    
    // Appearance
    font: FontConfigSchema.optional(),
    default_border: WindowBorderSchema.default('pixel'),
    default_floating_border: WindowBorderSchema.default('normal'),
    hide_edge_borders: z.enum(['none', 'vertical', 'horizontal', 'both', 'smart']).default('smart'),
    border_pixel_size: z.number().min(0, 'Border size must be non-negative').max(20, 'Border size must not exceed 20').optional(),
    
    // Colors
    colors: z.object({
        focused: ClientStateSchema,
        focused_inactive: ClientStateSchema,
        unfocused: ClientStateSchema,
        urgent: ClientStateSchema,
        placeholder: ClientStateSchema
    }).optional(),
    
    // Outputs
    outputs: z.array(OutputConfigSchema).optional(),
    
    // Inputs
    inputs: z.array(InputConfigSchema).optional(),
    
    // Workspaces
    workspaces: z.array(WorkspaceConfigSchema).optional(),
    
    // Window rules
    window_rules: z.array(WindowRuleSchema).optional(),
    
    // Keybindings
    keybindings: z.array(KeybindingSchema).optional(),
    
    // Bars
    bars: z.array(BarConfigSchema).optional(),
    
    // Autostart
    exec: z.array(z.string()).optional(),
    exec_always: z.array(z.string()).optional(),
    
    // Include files
    include: z.array(z.string()).optional(),
    
    // Miscellaneous
    gaps: z.object({
        inner: z.number().min(0, 'Inner gap must be non-negative').max(100, 'Inner gap must not exceed 100').optional(),
        outer: z.number().min(0, 'Outer gap must be non-negative').max(100, 'Outer gap must not exceed 100').optional(),
        horizontal: z.number().min(0, 'Horizontal gap must be non-negative').max(100, 'Horizontal gap must not exceed 100').optional(),
        vertical: z.number().min(0, 'Vertical gap must be non-negative').max(100, 'Vertical gap must not exceed 100').optional()
    }).optional(),
    
    smart_gaps: z.boolean().optional(),
    smart_borders: z.enum(['no_gaps', 'inverse_outer', 'on']).optional(),
    
    focus_follows_mouse: z.boolean().optional(),
    mouse_warping: z.boolean().optional(),
    focus_wrapping: z.enum(['yes', 'no', 'force']).optional(),
    
    floating_minimum_size: z.tuple([z.number(), z.number()]).optional(),
    floating_maximum_size: z.tuple([z.number(), z.number()]).optional(),
    
    title_align: z.enum(['left', 'center', 'right']).optional(),
    titlebar_border_thickness: z.number().min(0, 'Border thickness must be non-negative').max(10, 'Border thickness must not exceed 10').optional(),
    titlebar_padding: z.number().min(0, 'Padding must be non-negative').max(20, 'Padding must not exceed 20').optional()
}, {
    description: 'Complete Sway configuration'
});

// =============================================================================
// VALIDATION FUNCTIONS
// =============================================================================

// Validate Sway configuration
export function validateSwayConfig(config: unknown): z.infer<typeof SwayConfigSchema> {
    return SwayConfigSchema.parse(config);
}

// Validate Sway configuration with detailed error reporting
export function validateSwayConfigDetailed(config: unknown): {
    success: boolean;
    data?: z.infer<typeof SwayConfigSchema>;
    errors?: z.ZodIssue[];
} {
    const result = SwayConfigSchema.safeParse(config);
    
    if (result.success) {
        return {
            success: true,
            data: result.data
        };
    } else {
        return {
            success: false,
            errors: result.error.issues
        };
    }
}

// =============================================================================
// EDUCATIONAL NOTES
// =============================================================================

/*
This Zod schema provides comprehensive validation for Sway configuration:

Educational Features:
- Each schema includes detailed descriptions
- Validation rules explain constraints
- Type safety ensures configuration consistency
- Error messages guide users to fix issues

Learning Tips:
- Use validateSwayConfig() for basic validation
- Use validateSwayConfigDetailed() for detailed error reporting
- Schema structure mirrors Sway configuration format
- Validation rules prevent common configuration errors

Customization:
- Extend schemas for additional validation rules
- Add custom validation functions for complex checks
- Modify constraints to match your requirements
- Use schema inheritance for related configurations

Integration:
- Use with TypeScript for type safety
- Integrate with configuration editors
- Validate user input in real-time
- Generate configuration forms from schemas
*/
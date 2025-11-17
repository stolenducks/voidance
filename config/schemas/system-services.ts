// Zod schemas for Voidance Linux system services configuration
// Provides type-safe configuration validation

import { z } from 'zod';

// Base configuration schema
const BaseConfigSchema = z.object({
  version: z.string().default('1.0.0'),
  enabled: z.boolean().default(true),
  debug: z.boolean().default(false),
});

// Session management configuration
export const SessionConfigSchema = BaseConfigSchema.extend({
  service: z.literal('elogind'),
  settings: z.object({
    handle_lid_switch: z.enum(['suspend', 'hibernate', 'ignore', 'poweroff']).default('suspend'),
    handle_lid_switch_docked: z.enum(['suspend', 'hibernate', 'ignore', 'poweroff']).default('ignore'),
    handle_power_key: z.enum(['poweroff', 'reboot', 'ignore', 'suspend', 'hibernate']).default('poweroff'),
    handle_suspend_key: z.enum(['suspend', 'hibernate', 'ignore']).default('suspend'),
    handle_hibernate_key: z.enum(['hibernate', 'ignore']).default('hibernate'),
    kill_user_processes: z.boolean().default(false),
    kill_exclude_users: z.array(z.string()).default(['root']),
    idle_action: z.enum(['ignore', 'suspend', 'hibernate', 'poweroff']).default('ignore'),
    idle_action_sec: z.number().int().min(0).default(0),
  }),
});

// Display manager configuration
export const DisplayConfigSchema = BaseConfigSchema.extend({
  service: z.literal('sddm'),
  settings: z.object({
    theme: z.string().default('breeze'),
    wayland_first: z.boolean().default(true),
    autologin: z.object({
      enabled: z.boolean().default(false),
      user: z.string().optional(),
      session: z.string().optional(),
    }),
    display: z.object({
      minimum_vt: z.number().int().min(1).max(12).default(7),
      server_command: z.string().optional(),
      server_args: z.string().optional(),
      xserver_command: z.string().default('X'),
      xserver_args: z.string().default('-nolisten tcp'),
    }),
    users: z.object({
      maximum_uid: z.number().int().min(1000).default(60000),
      minimum_uid: z.number().int().min(0).default(1000),
      hide_users: z.array(z.string()).default([]),
      hide_shells: z.array(z.string()).default([]),
    }),
  }),
});

// Network manager configuration
export const NetworkConfigSchema = BaseConfigSchema.extend({
  service: z.literal('NetworkManager'),
  settings: z.object({
    dhcp: z.enum(['internal', 'dhclient']).default('internal'),
    plugins: z.array(z.string()).default(['keyfile']),
    wifi: z.object({
      scan_rand_mac_address: z.boolean().default(true),
      powersave: z.number().int().min(0).max(3).default(3),
    }),
    ethernet: z.object({
      auto_negotiate: z.boolean().default(true),
    }),
    connectivity: z.object({
      enabled: z.boolean().default(true),
      uri: z.string().default('http://check.ipv6.microsoft.com/'),
      interval: z.number().int().min(60).default(300),
    }),
    ipv6: z.object({
      ip6_privacy: z.enum(['disabled', 'prefer-public-addr', 'prefer-temp-addr', 'prefer-public-addr-6rd', 'prefer-temp-addr-6rd']).default('prefer-public-addr'),
    }),
  }),
});

// Audio services configuration
export const AudioConfigSchema = BaseConfigSchema.extend({
  service: z.literal('pipewire'),
  settings: z.object({
    default_clock_rate: z.number().int().min(8000).max(384000).default(48000),
    default_clock_quantum: z.number().int().min(32).max(8192).default(1024),
    allowed_rates: z.array(z.number().int()).default([44100, 48000, 88200, 96000, 176400, 192000]),
    mem_allow_mlock: z.boolean().default(true),
    log_level: z.enum(['0', '1', '2', '3', '4']).default('2'),
    rtkit: z.object({
      enabled: z.boolean().default(true),
      nice_level: z.number().int().min(-20).max(19).default(-11),
      rt_prio: z.number().int().min(1).max(99).default(88),
      rt_time_soft: z.number().int().min(-1).default(200000),
      rt_time_hard: z.number().int().min(-1).default(200000),
    }),
    pulse: z.object({
      server_address: z.array(z.string()).default(['unix:native']),
      min_req: z.string().default('256/48000'),
      default_req: z.string().default('960/48000'),
      max_req: z.string().default('1920/48000'),
      min_quantum: z.string().default('256/48000'),
      default_quantum: z.string().default('960/48000'),
      max_quantum: z.string().default('1920/48000'),
    }),
  }),
});

// Idle management configuration
export const IdleConfigSchema = BaseConfigSchema.extend({
  service: z.literal('swayidle'),
  settings: z.object({
    timeouts: z.object({
      idle: z.number().int().min(60).default(300),        // 5 minutes
      lock: z.number().int().min(60).default(600),        // 10 minutes
      suspend: z.number().int().min(300).default(1800),    // 30 minutes
    }),
    lock: z.object({
      enabled: z.boolean().default(true),
      command: z.string().default('swaylock -f -c 000000'),
      before_sleep: z.boolean().default(true),
    }),
    screen_off: z.object({
      enabled: z.boolean().default(true),
      command: z.string().default('swaymsg "output * power off"'),
    }),
    suspend: z.object({
      enabled: z.boolean().default(true),
      command: z.string().default('systemctl suspend'),
      resume_command: z.string().default('swaymsg "output * power on"'),
    }),
    notifications: z.object({
      enabled: z.boolean().default(true),
      before_lock: z.number().int().min(10).default(30),
      message: z.string().default('Screen will lock in 30 seconds'),
      icon: z.string().default('dialog-information'),
    }),
    battery: z.object({
      enabled: z.boolean().default(true),
      timeouts: z.object({
        idle: z.number().int().min(60).default(180),      // 3 minutes
        lock: z.number().int().min(60).default(300),      // 5 minutes
        suspend: z.number().int().min(300).default(900),   // 15 minutes
      }),
    }),
  }),
});

// Swaylock configuration
export const SwaylockConfigSchema = BaseConfigSchema.extend({
  service: z.literal('swaylock'),
  settings: z.object({
    colors: z.object({
      background: z.string().default('000000ff'),
      bs_color: z.string().default('000000ff'),
      inside_color: z.string().default('00000088'),
      ring_color: z.string().default('458588ff'),
      line_color: z.string().default('458588ff'),
      text_color: z.string().default('ebdbb2ff'),
      text_clear_color: z.string().default('ebdbb2ff'),
      text_caps_lock_color: z.string().default('fabd2fff'),
      text_ver_color: z.string().default('8ec07cff'),
      text_wrong_color: z.string().default('fb4934ff'),
      inside_clear_color: z.string().default('00000000'),
      inside_ver_color: z.string().default('45858888'),
      inside_wrong_color: z.string().default('cc241d88'),
      ring_clear_color: z.string().default('8ec07cff'),
      ring_ver_color: z.string().default('8ec07cff'),
      ring_wrong_color: z.string().default('fb4934ff'),
    }),
    indicator: z.object({
      enabled: z.boolean().default(true),
      radius: z.number().int().min(50).max(200).default(100),
      thickness: z.number().int().min(10).max(50).default(20),
    }),
    effects: z.object({
      screenshots: z.boolean().default(true),
      blur: z.string().default('7x5'),
      vignette: z.string().default('0.5:0.5'),
      fade_in: z.number().min(0).max(5).default(0.2),
    }),
    clock: z.object({
      enabled: z.boolean().default(true),
      time_str: z.string().default('%H:%M:%S'),
      date_str: z.string().default('%Y-%m-%d'),
    }),
    font: z.string().default('monospace'),
    key_handling: z.object({
      ignore_empty_password: z.boolean().default(true),
      show_keyboard_layout: z.boolean().default(true),
      show_failed_attempts: z.boolean().default(true),
    }),
  }),
});

// System services configuration schema
export const SystemServicesConfigSchema = z.object({
  version: z.string().default('1.0.0'),
  services: z.object({
    session: SessionConfigSchema.optional(),
    display: DisplayConfigSchema.optional(),
    network: NetworkConfigSchema.optional(),
    audio: AudioConfigSchema.optional(),
    idle: IdleConfigSchema.optional(),
    swaylock: SwaylockConfigSchema.optional(),
  }),
  global: z.object({
    log_level: z.enum(['error', 'warn', 'info', 'debug']).default('info'),
    service_timeout: z.number().int().min(5).max(300).default(30),
    auto_start: z.boolean().default(true),
    dependency_check: z.boolean().default(true),
  }),
});

// Type exports
export type SessionConfig = z.infer<typeof SessionConfigSchema>;
export type DisplayConfig = z.infer<typeof DisplayConfigSchema>;
export type NetworkConfig = z.infer<typeof NetworkConfigSchema>;
export type AudioConfig = z.infer<typeof AudioConfigSchema>;
export type IdleConfig = z.infer<typeof IdleConfigSchema>;
export type SwaylockConfig = z.infer<typeof SwaylockConfigSchema>;
export type SystemServicesConfig = z.infer<typeof SystemServicesConfigSchema>;

// Validation functions
export const validateSessionConfig = (config: unknown) => {
  return SessionConfigSchema.safeParse(config);
};

export const validateDisplayConfig = (config: unknown) => {
  return DisplayConfigSchema.safeParse(config);
};

export const validateNetworkConfig = (config: unknown) => {
  return NetworkConfigSchema.safeParse(config);
};

export const validateAudioConfig = (config: unknown) => {
  return AudioConfigSchema.safeParse(config);
};

export const validateIdleConfig = (config: unknown) => {
  return IdleConfigSchema.safeParse(config);
};

export const validateSwaylockConfig = (config: unknown) => {
  return SwaylockConfigSchema.safeParse(config);
};

export const validateSystemServicesConfig = (config: unknown) => {
  return SystemServicesConfigSchema.safeParse(config);
};

// Default configurations
export const defaultSessionConfig: SessionConfig = {
  version: '1.0.0',
  enabled: true,
  debug: false,
  service: 'elogind',
  settings: {
    handle_lid_switch: 'suspend',
    handle_lid_switch_docked: 'ignore',
    handle_power_key: 'poweroff',
    handle_suspend_key: 'suspend',
    handle_hibernate_key: 'hibernate',
    kill_user_processes: false,
    kill_exclude_users: ['root'],
    idle_action: 'ignore',
    idle_action_sec: 0,
  },
};

export const defaultDisplayConfig: DisplayConfig = {
  version: '1.0.0',
  enabled: true,
  debug: false,
  service: 'sddm',
  settings: {
    theme: 'breeze',
    wayland_first: true,
    autologin: {
      enabled: false,
    },
    display: {
      minimum_vt: 7,
      server_command: undefined,
      server_args: undefined,
      xserver_command: 'X',
      xserver_args: '-nolisten tcp',
    },
    users: {
      maximum_uid: 60000,
      minimum_uid: 1000,
      hide_users: [],
      hide_shells: [],
    },
  },
};

export const defaultNetworkConfig: NetworkConfig = {
  version: '1.0.0',
  enabled: true,
  debug: false,
  service: 'NetworkManager',
  settings: {
    dhcp: 'internal',
    plugins: ['keyfile'],
    wifi: {
      scan_rand_mac_address: true,
      powersave: 3,
    },
    ethernet: {
      auto_negotiate: true,
    },
    connectivity: {
      enabled: true,
      uri: 'http://check.ipv6.microsoft.com/',
      interval: 300,
    },
    ipv6: {
      ip6_privacy: 'prefer-public-addr',
    },
  },
};

export const defaultAudioConfig: AudioConfig = {
  version: '1.0.0',
  enabled: true,
  debug: false,
  service: 'pipewire',
  settings: {
    default_clock_rate: 48000,
    default_clock_quantum: 1024,
    allowed_rates: [44100, 48000, 88200, 96000, 176400, 192000],
    mem_allow_mlock: true,
    log_level: '2',
    rtkit: {
      enabled: true,
      nice_level: -11,
      rt_prio: 88,
      rt_time_soft: 200000,
      rt_time_hard: 200000,
    },
    pulse: {
      server_address: ['unix:native'],
      min_req: '256/48000',
      default_req: '960/48000',
      max_req: '1920/48000',
      min_quantum: '256/48000',
      default_quantum: '960/48000',
      max_quantum: '1920/48000',
    },
  },
};

export const defaultIdleConfig: IdleConfig = {
  version: '1.0.0',
  enabled: true,
  debug: false,
  service: 'swayidle',
  settings: {
    timeouts: {
      idle: 300,
      lock: 600,
      suspend: 1800,
    },
    lock: {
      enabled: true,
      command: 'swaylock -f -c 000000',
      before_sleep: true,
    },
    screen_off: {
      enabled: true,
      command: 'swaymsg "output * power off"',
    },
    suspend: {
      enabled: true,
      command: 'systemctl suspend',
      resume_command: 'swaymsg "output * power on"',
    },
    notifications: {
      enabled: true,
      before_lock: 30,
      message: 'Screen will lock in 30 seconds',
      icon: 'dialog-information',
    },
    battery: {
      enabled: true,
      timeouts: {
        idle: 180,
        lock: 300,
        suspend: 900,
      },
    },
  },
};

export const defaultSwaylockConfig: SwaylockConfig = {
  version: '1.0.0',
  enabled: true,
  debug: false,
  service: 'swaylock',
  settings: {
    colors: {
      background: '000000ff',
      bs_color: '000000ff',
      inside_color: '00000088',
      ring_color: '458588ff',
      line_color: '458588ff',
      text_color: 'ebdbb2ff',
      text_clear_color: 'ebdbb2ff',
      text_caps_lock_color: 'fabd2fff',
      text_ver_color: '8ec07cff',
      text_wrong_color: 'fb4934ff',
      inside_clear_color: '00000000',
      inside_ver_color: '45858888',
      inside_wrong_color: 'cc241d88',
      ring_clear_color: '8ec07cff',
      ring_ver_color: '8ec07cff',
      ring_wrong_color: 'fb4934ff',
    },
    indicator: {
      enabled: true,
      radius: 100,
      thickness: 20,
    },
    effects: {
      screenshots: true,
      blur: '7x5',
      vignette: '0.5:0.5',
      fade_in: 0.2,
    },
    clock: {
      enabled: true,
      time_str: '%H:%M:%S',
      date_str: '%Y-%m-%d',
    },
    font: 'monospace',
    key_handling: {
      ignore_empty_password: true,
      show_keyboard_layout: true,
      show_failed_attempts: true,
    },
  },
};

export const defaultSystemServicesConfig: SystemServicesConfig = {
  version: '1.0.0',
  services: {
    session: defaultSessionConfig,
    display: defaultDisplayConfig,
    network: defaultNetworkConfig,
    audio: defaultAudioConfig,
    idle: defaultIdleConfig,
    swaylock: defaultSwaylockConfig,
  },
  global: {
    log_level: 'info',
    service_timeout: 30,
    auto_start: true,
    dependency_check: true,
  },
};
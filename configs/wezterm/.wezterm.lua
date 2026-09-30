local wezterm = require 'wezterm'
local act = wezterm.action

local config = wezterm.config_builder()

config.font = wezterm.font_with_fallback {
  'JetBrains Mono',
  'Menlo',
}
config.font_size = 14
config.line_height = 1.08

config.colors = {
  foreground = '#dce7f7',
  background = '#07111f',
  cursor_bg = '#8bdcff',
  cursor_fg = '#07111f',
  selection_bg = '#24466f',
  selection_fg = '#ffffff',
}

config.window_decorations = 'RESIZE'
config.window_background_opacity = 0.94
config.macos_window_background_blur = 24
config.window_padding = {
  left = 14,
  right = 14,
  top = 12,
  bottom = 12,
}

config.use_fancy_tab_bar = false
config.hide_tab_bar_if_only_one_tab = true
config.tab_bar_at_bottom = true
config.scrollback_lines = 10000
config.audible_bell = 'Disabled'

-- The window is frameless (window_decorations = 'RESIZE'), so there is no title
-- bar to grab. These make a modifier + left-drag move the window from anywhere
-- in it. Both are provided because the Windows key is occasionally swallowed by
-- the OS; CTRL|SHIFT always reaches the app.
-- ALT is deliberately avoided: it is WezTerm's default rectangular-select drag.
config.mouse_bindings = {
  {
    event = { Drag = { streak = 1, button = 'Left' } },
    mods = 'SUPER',
    action = act.StartWindowDrag,
  },
  {
    event = { Drag = { streak = 1, button = 'Left' } },
    mods = 'CTRL|SHIFT',
    action = act.StartWindowDrag,
  },
  -- Suppress the text-selection that would otherwise begin on mouse-down,
  -- before the drag above is recognised.
  {
    event = { Down = { streak = 1, button = 'Left' } },
    mods = 'SUPER',
    action = act.Nop,
  },
  {
    event = { Down = { streak = 1, button = 'Left' } },
    mods = 'CTRL|SHIFT',
    action = act.Nop,
  },
}

config.leader = { key = 'a', mods = 'CTRL', timeout_milliseconds = 1000 }
config.keys = {
  {
    key = '|',
    mods = 'LEADER|SHIFT',
    action = act.SplitHorizontal { domain = 'CurrentPaneDomain' },
  },
  {
    key = '-',
    mods = 'LEADER',
    action = act.SplitVertical { domain = 'CurrentPaneDomain' },
  },
  { key = 'h', mods = 'LEADER', action = act.ActivatePaneDirection 'Left' },
  { key = 'j', mods = 'LEADER', action = act.ActivatePaneDirection 'Down' },
  { key = 'k', mods = 'LEADER', action = act.ActivatePaneDirection 'Up' },
  { key = 'l', mods = 'LEADER', action = act.ActivatePaneDirection 'Right' },
  { key = 'z', mods = 'LEADER', action = act.TogglePaneZoomState },
  { key = 'c', mods = 'LEADER', action = act.SpawnTab 'CurrentPaneDomain' },
  {
    key = 'a',
    mods = 'LEADER|CTRL',
    action = act.SendKey { key = 'a', mods = 'CTRL' },
  },
}

return config
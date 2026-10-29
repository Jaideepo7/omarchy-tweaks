-- Keep only your personal input overrides here. Uncommented settings below
-- replace Omarchy's defaults.

-- Keyboard layout and options.
-- See https://wiki.hypr.land/Configuring/Basics/Variables/#input
-- hl.config({
--   input = {
--     -- Use multiple keyboard layouts and switch between them with Left Alt + Right Alt.
--     kb_layout = "us,dk,eu",
--     kb_options = "compose:caps,shift:both_capslock_cancel,grp:alts_toggle",
--
--     -- Use a specific keyboard variant if needed (e.g. intl for international keyboards).
--     kb_variant = "intl",
--
--     -- Change speed of keyboard repeat.
--     repeat_rate = 40,
--     repeat_delay = 250,
--
--     -- Start with numlock on by default.
--     numlock_by_default = true,
--
--     -- Increase sensitivity for mouse/trackpad (default: 0).
--     sensitivity = 0,
--
--     -- Turn off mouse acceleration (default: adaptive).
--     accel_profile = "adaptive",
--
--     touchpad = {
--       -- Use natural (inverse) scrolling.
--       natural_scroll = true,
--
--       -- Use two-finger clicks for right-click instead of lower-right corner.
--       clickfinger_behavior = true,
--
--       -- Control the speed of your scrolling.
--       scroll_factor = 0.2,
--
--       -- Enable the touchpad while typing.
--       disable_while_typing = false,
--
--       -- Left-click-and-drag with three fingers.
--       drag_3fg = 1,
--     },
--   },
-- })

-- App-specific touchpad scroll speeds.
-- o.window("(Alacritty|kitty|foot)", { scroll_touchpad = 1.5 })
-- o.window("com.mitchellh.ghostty", { scroll_touchpad = 0.2 })

-- Enable touchpad gestures for changing workspaces.
-- See https://wiki.hypr.land/Configuring/Advanced-and-Cool/Gestures/
hl.gesture({ fingers = 3, direction = "horizontal", action = "workspace" })

-- 4-finger pinch out to toggle fullscreen on the focused window.
hl.gesture({ fingers = 4, direction = "pinchout", action = function() hl.dispatch(hl.dsp.window.fullscreen({ mode = "fullscreen" })) end })

-- Enable touchpad gestures for moving focus (helpful on scrolling layout).
-- hl.gesture({ fingers = 3, direction = "left", action = function() hl.dispatch(hl.dsp.focus({ direction = "l" })) end })
-- hl.gesture({ fingers = 3, direction = "right", action = function() hl.dispatch(hl.dsp.focus({ direction = "r" })) end })

-- Normal Caps Lock (Omarchy default makes it a Compose key)
hl.config({
  input = {
    kb_options = "",

    -- Faster pointer speed (-1.0 to 1.0, default 0).
    sensitivity = 0.15,

    -- Mouse wheel scroll speed (default 1.0).
    scroll_factor = 2.0,

    -- Natural scrolling on the touchpad (content follows your fingers).
    touchpad = {
      natural_scroll = true,

      -- Touchpad scroll speed (Omarchy default: 0.4).
      scroll_factor = 0.3,

      -- Palm rejection while typing.
      disable_while_typing = true,

      -- Tap to click, tap and drag, two-finger tap = right click (lrm).
      tap_to_click = true,
      tap_and_drag = true,
      tap_button_map = "lrm",

      -- Two-finger click = right click, three-finger = middle.
      clickfinger_behavior = true,
    },
  },
})

-- Spotifast scrolls 1.1x faster than the global touchpad scroll factor.
o.window("spotifast", { scroll_touchpad = 1.1 })

-- Strata scrolls at the global touchpad scroll factor.
o.window("io.github.lgse.Strata", { scroll_touchpad = 1.0 })

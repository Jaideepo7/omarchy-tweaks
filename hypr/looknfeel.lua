-- Change the default Omarchy look'n'feel.

-- https://wiki.hypr.land/Configuring/Basics/Variables/#general
-- hl.config({
--   general = {
--     -- No gaps between windows or borders.
--     gaps_in = 0,
--     gaps_out = 0,
--     border_size = 0,
--
--     -- Change to niri-like side-scrolling layout.
--     layout = "scrolling",
--   },
-- })

-- https://wiki.hypr.land/Configuring/Basics/Variables/#decoration
-- hl.config({
--   decoration = {
--     -- Use round window corners.
--     rounding = 8,
--
--     -- Dim unfocused windows (0.0 = no dim, 1.0 = fully dimmed).
--     dim_inactive = true,
--     dim_strength = 0.15,
--   },
-- })

-- https://wiki.hypr.land/Configuring/Basics/Variables/#animations
-- hl.config({
--   animations = {
--     -- Disable all animations.
--     enabled = false,
--   },
-- })

-- https://wiki.hypr.land/Configuring/Basics/Variables/#layout
-- hl.config({
--   layout = {
--     -- Avoid overly wide single-window layouts on wide screens.
--     single_window_aspect_ratio = { 1, 1 },
--   },
-- })

-- https://wiki.hypr.land/Configuring/Layouts/Scrolling-Layout/
-- hl.config({
--   scrolling = {
--     -- See only one column per screen instead of two.
--     column_width = 0.97,
--   },
-- })

-- >>> omaland managed block >>>
-- Written by Omaland. Safe to hand-edit: Omaland re-reads this block
-- every time it opens, and only ever rewrites what's between the fences.
hl.config({
  decoration = {
    rounding = 4,
  },

  general = {
    gaps_in = 0,
    gaps_out = 0,
    gaps_workspaces = 0,
  },
})
-- <<< omaland managed block <<<

-- Keep the screen awake while watching media.
-- Dedicated video players: inhibit idle whenever focused.
o.window("^(mpv|vlc|imv|org.jellyfin.*|io.github.celluloid_player.Celluloid|org.kde.haruna|smplayer)$", { idle_inhibit = "focus" })
-- Anything (browsers, etc.) going fullscreen also inhibits idle.
o.window(".*", { idle_inhibit = "fullscreen" })

-- Opt another application in to Omarchy's standard transparency.
-- Find its class with: hyprctl clients
-- o.transparent_window("my-app")
-- o.transparent_window("my-app", "0.9 0.85") -- Custom active/inactive opacity.

-- Screensaver: fully opaque. Overrides the terminal transparency rule, and
-- `opaque` ignores kitty's own translucent background (theme background_opacity).
o.window("org.omarchy.screensaver", { opacity = "1.0 override 1.0 override", opaque = true, no_blur = true })

-- >>> omarchy-tweaks glass >>>
-- Blur behind the shell's frosted glass cards (glass/apply.sh). ignore_alpha
-- 0.3 keeps fully see-through pixels sharp; the cards stay above it.
hl.layer_rule({
  match = { namespace = "^(omarchy-notifications|omarchy-keyboard-panel|omarchy-menu|omarchy-dock-apps|omarchy-clipboard|omarchy-emojis|omarchy-reminders|omarchy-polkit|omarchy-osd)$" },
  blur = true,
  ignore_alpha = 0.3,
})
-- <<< omarchy-tweaks glass <<<

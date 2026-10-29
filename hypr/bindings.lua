-- Keep only your personal keybinding overrides here. Add new bindings or
-- unbind defaults before replacing them.

-- See current bindings and descriptions:
--   omarchy menu keybindings --print

-- To disable every Omarchy default binding, set this in
-- ~/.config/hypr/hyprland.lua before require("default.hypr.omarchy"), then add
-- only the bindings you want below:
--   omarchy_default_bindings = false

-- To disable all preinstalled app/webapp bindings, set:
--   omarchy_preinstalled_bindings = false

-- Add a new binding.
-- o.bind("SUPER + SHIFT + R", "SSH", "alacritty -e ssh your-server")

-- Change an existing binding by unbinding it first, then binding the key again.
-- This example changes SUPER+SPACE from the launcher to the Omarchy root menu.
-- hl.unbind("SUPER + SPACE")
-- o.bind("SUPER + SPACE", "Omarchy menu", "omarchy-menu toggle root")

-- Disable a default binding without replacing it.
-- hl.unbind("SUPER + SHIFT + B")

-- Logitech MX Keys examples:
-- o.bind("SUPER + SHIFT + S", nil, "omarchy-capture-screenshot")
-- o.bind("SUPER + H", nil, "voxtype record toggle")
-- o.bind("SUPER + PERIOD", nil, "omarchy-shell shell toggle omarchy.emojis")

-- Proportional floating-window resize; unshifted Omarchy bindings stay default.
hl.unbind("SUPER + SHIFT + code:21")
o.bind("SUPER + SHIFT + code:21", "Grow floating window proportionally", "/home/jaideep/.local/bin/omarchy-proportional-grow")
hl.unbind("SUPER + SHIFT + code:20")
o.bind("SUPER + SHIFT + code:20", "Shrink floating window proportionally", "/home/jaideep/.local/bin/omarchy-proportional-grow --shrink")

-- Screenshot shortcut (overrides Google Maps).
hl.unbind("SUPER + SHIFT + S")
o.bind("SUPER + SHIFT + S", "Screenshot", "omarchy-capture-screenshot")

-- App launchers (overrides Omawrite on W and ChatGPT on A).
hl.unbind("SUPER + SHIFT + W")
o.bind("SUPER + SHIFT + W", "WhatsApp", { launch = "/home/jaideep/Apps/pake/whatsapp-binary", focus = "^whatsapp-binary$" })  -- Pake app; web version: { webapp = "https://web.whatsapp.com/", focus = true }
o.bind("SUPER + H", "Hermes", "uwsm-app -- hermes-desktop")
hl.unbind("SUPER + SHIFT + A")
o.bind("SUPER + SHIFT + A", "Claude", { webapp = "https://claude.ai", focus = true })
o.bind("SUPER + SHIFT + Q", "Spotifast", "uwsm-app -- spotifast")
o.bind("SUPER + SHIFT + Z", "Discord", { launch = "/home/jaideep/Apps/pake/discord-binary", focus = "^discord-binary$" })  -- Pake app; web version: { webapp = "https://discord.com/channels/@me", focus = true }

-- File manager: Strata instead of Nautilus.
hl.unbind("SUPER + SHIFT + F")
o.bind("SUPER + SHIFT + F", "File manager", "uwsm-app -- /home/jaideep/.local/bin/strata")
hl.unbind("SUPER + ALT + SHIFT + F")
o.bind("SUPER + ALT + SHIFT + F", "File manager (cwd)", [[bash -c 'uwsm-app -- /home/jaideep/.local/bin/strata "$(omarchy-cmd-terminal-cwd)"']])

-- Extra autostart processes.
-- o.launch_on_start("my-service")

-- Patched kinetic (inertial) touchpad scrolling plugin.
-- Loaded via hyprctl shortly after startup (and again after config reloads)
-- only if it isn't already loaded; hl.plugin.load at hyprland.start didn't stick.
local kinetic_so = os.getenv("HOME") .. "/hypr-kinetic-scroll-patched/hypr-kinetic-scroll.so"
local function ensure_kinetic()
  hl.exec_cmd("sh -c 'sleep 2; hyprctl plugin list | grep -q hypr-kinetic-scroll || hyprctl plugin load " .. kinetic_so .. "'")
end

hl.on("hyprland.start", ensure_kinetic)
hl.on("config.reloaded", ensure_kinetic)

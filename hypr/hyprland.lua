-- Learn how to configure Hyprland: https://wiki.hypr.land/Configuring/Start/

-- Omarchy's bootstrap keeps path setup out of this user config.
dofile((os.getenv("OMARCHY_PATH") or "/usr/share/omarchy") .. "/default/hypr/bootstrap.lua")

-- Disable all Omarchy default bindings. Add your own in hypr/bindings.lua.
-- omarchy_default_bindings = false
--
-- Or disable only bindings for Omarchy's preinstalled apps/web apps while
-- keeping core window-manager bindings:
-- omarchy_preinstalled_bindings = false

-- Load Omarchy defaults.
require("default.hypr.omarchy")

-- Put your personal overrides in these files. They're loaded after Omarchy's
-- defaults so package updates can improve the defaults without rewriting your
-- ~/.config/hypr files.
require("hypr.monitors")
require("hypr.input")
require("hypr.bindings")
require("hypr.looknfeel")
require("hypr.autostart")

-- Toggle config flags dynamically.
require("default.hypr.toggles")

-- Add any other personal Hyprland configuration below.
-- o.window("qemu", { workspace = "5" })

-- Battery fix: Omarchy's omarchy-hw-nvidia-display misdetects this laptop as
-- NVIDIA-driven (the AMD 890M is PCI class 0x0380 with no boot_vga file), so it
-- forced GLX + VA-API onto the RTX 4060 for every app, keeping the dGPU awake.
-- The panel is on the AMD iGPU; route GL/video decode there. Use
-- `nvidia-gate run <app>` to opt a specific app into the NVIDIA GPU.
hl.env("__GLX_VENDOR_LIBRARY_NAME", "mesa")
hl.env("LIBVA_DRIVER_NAME", "radeonsi")
-- EGL and Vulkan still enumerate every vendor driver, so apps like Zen's media
-- decoder (EGL) and strata (Vulkan) loaded the NVIDIA driver and pinned the
-- dGPU awake. Point both at gated driver dirs: the nvidia-gate user service
-- (dotfiles/bin/nvidia-gate) adds the NVIDIA manifests there only on the barrel
-- charger or USB-C >= 65 W. To force the dGPU on battery: nvidia-gate run <app>
local nvidia_gate = os.getenv("HOME") .. "/.local/state/nvidia-gate"
local gate_ok = io.open(nvidia_gate .. "/egl/50_mesa.json", "r")
if gate_ok then
  gate_ok:close()
  hl.env("__EGL_VENDOR_LIBRARY_DIRS", nvidia_gate .. "/egl")
  hl.env("VK_DRIVER_FILES", nvidia_gate .. "/vulkan")
else -- gate never ran: plain AMD-only block
  hl.env("__EGL_VENDOR_LIBRARY_FILENAMES", "/usr/share/glvnd/egl_vendor.d/50_mesa.json")
  hl.env("VK_DRIVER_FILES", "/usr/share/vulkan/icd.d/radeon_icd.json")
end

-- Added by hyprmoncfg: its generated monitor rules load last, so nothing before this can override the applied layout.
do local path = (os.getenv("XDG_CONFIG_HOME") or os.getenv("HOME") .. "/.config") .. "/hypr/hyprmoncfg-monitors.lua"; local file = io.open(path, "r"); if file then file:close(); dofile(path) end end

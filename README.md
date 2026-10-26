# Omarchy Tweaks

My personal customizations for [Omarchy](https://omarchy.org): keybindings, bar plugins,
fixes to third-party plugins and a patched kinetic-scroll plugin for Hyprland.

> **After any Omarchy update or plugin resync, run:**
> ```bash
> ~/dotfiles/install.sh
> ```
> It is safe to run as often as you like. Anything already in place is skipped.

---

## Contents

- [Quick start](#quick-start)
- [Installing individual pieces](#installing-individual-pieces)
- [Keybindings](#keybindings)
- [Bar plugins](#bar-plugins)
  - [Media controls on the waveform](#media-controls-on-the-waveform-jaideepvisualizer)
  - [Album art: jump to the player](#album-art-jump-to-the-player-jaideepalbumart)
- [Patches to existing plugins](#patches-to-existing-plugins)
  - [Hover to open bar panels](#hover-to-open-bar-panels-bar-hover-openpatch)
  - [Calendar time column fix](#calendar-time-column-fix-calendar-timedrowpatch)
- [Kinetic touchpad scrolling](#kinetic-touchpad-scrolling)
- [Hyprland config](#hyprland-config)
- [What install.sh does](#what-installsh-does)
- [Repo layout](#repo-layout)

---

## Quick start

**On a fresh machine:**

```bash
git clone https://github.com/Jaideepo7/omarchy-tweaks ~/dotfiles
~/dotfiles/install.sh
```

**After an update:** just run `~/dotfiles/install.sh` again.

---

## Installing individual pieces

You don't need to use `install.sh`. Each piece can be installed on its own. All the steps
below start by cloning the repo:

```bash
git clone https://github.com/Jaideepo7/omarchy-tweaks ~/omarchy-tweaks
cd ~/omarchy-tweaks
```

### Media controls on the waveform (`jaideep.visualizer`)

**Needs:** `cava` (`sudo pacman -S cava`)

```bash
cp -r plugins/jaideep.visualizer ~/.config/omarchy/plugins/
omarchy plugin enable jaideep.visualizer --section center
omarchy restart shell
```

- **Placement:** use `--section left|center|right`, or `--before <id>` / `--after <id>`
  to place it next to another widget, for example `--after jaideep.albumart`.
- **Hover to open** needs the [hover patch](#hover-to-open-bar-panels). Without it,
  clicking the waveform still opens the card.

### Album art: jump to the player (`jaideep.albumart`)

**Needs:** `jq` (installed by default on Omarchy)

```bash
cp -r plugins/jaideep.albumart ~/.config/omarchy/plugins/
chmod +x ~/.config/omarchy/plugins/jaideep.albumart/focus-player.sh
omarchy plugin enable jaideep.albumart --section center
omarchy restart shell
```

### Hover to open bar panels

**Needs:** your own copy of the bar. The patch can't change the built-in bar in
`/usr/share`, because system updates overwrite it.

1. **Make your own copy of the bar** if you don't already have one. This creates
   `~/.config/omarchy/plugins/<your-username>.bar` and switches to it:
   ```bash
   omarchy plugin clone omarchy.bar
   ```
2. **Apply the patch** to that copy:
   ```bash
   patch -p1 -d ~/.config/omarchy/plugins/$USER.bar < patches/bar-hover-open.patch
   omarchy restart shell
   ```

> If the patch reports failed hunks, your Omarchy version's `Bar.qml` differs from the one
> this patch was made against. The change only touches the `ModuleSlot` component, right
> after `HoverHandler { id: moduleHover }`, so it can be copied in by hand from the patch file.

**To undo it:** run `patch -R -p1 -d ~/.config/omarchy/plugins/$USER.bar < patches/bar-hover-open.patch`

### Calendar time column fix

**Needs:** the [`tmn73.calendar`](https://github.com/tmn73/omarchy-calendar) plugin installed:

```bash
omarchy plugin add https://github.com/tmn73/omarchy-calendar.git --enable
```

Then apply the fix:

```bash
patch -p1 -d ~/.config/omarchy/plugins/tmn73.calendar < patches/calendar-timedrow.patch
omarchy restart shell
```

### Keybindings only

Copy the lines you want from **`hypr/bindings.lua`** into your own
`~/.config/hypr/bindings.lua`. Hyprland reloads its config automatically when the file is
saved.

- **Overriding a default:** keep the `hl.unbind(...)` line that comes before the binding.
  Otherwise the default and your binding will both fire.
- **Grow / shrink keys:** these also need the script:
  ```bash
  install -Dm755 bin/omarchy-proportional-grow ~/.local/bin/omarchy-proportional-grow
  ```

### Kinetic touchpad scrolling

**Needs:** Hyprland development headers and a C++ compiler (`sudo pacman -S base-devel`).

```bash
./kinetic-scroll/build.sh
cat kinetic-scroll/autostart-snippet.lua >> ~/.config/hypr/autostart.lua
```

Log out and back in, or load it immediately with:

```bash
hyprctl plugin load ~/hypr-kinetic-scroll-patched/hypr-kinetic-scroll.so
```

### Removing a plugin

```bash
omarchy plugin disable jaideep.visualizer   # hide it from the bar
omarchy plugin remove jaideep.visualizer    # delete it entirely
```

---

## Keybindings

Defined in **`hypr/bindings.lua`**.

| Shortcut | Action | Notes |
|---|---|---|
| **Super + Shift + W** | WhatsApp | Web app. Focuses it if already open. *Replaces Omawrite.* |
| **Super + H** | Hermes | Launches `hermes-desktop`. |
| **Super + Shift + A** | Claude | `claude.ai` web app. Focuses if open. *Replaces ChatGPT.* |
| **Super + Shift + Q** | Spotifast | Native Spotify client. |
| **Super + Shift + Z** | Discord | Web app. Focuses if open. |
| **Super + Shift + S** | Screenshot | *Replaces Google Maps.* |
| **Super + Shift + =** | Grow floating window | Keeps its aspect ratio. Tiled windows are left alone. |
| **Super + Shift + -** | Shrink floating window | Same, in reverse. |

The grow and shrink keys run **`bin/omarchy-proportional-grow`**. It resizes the focused
floating window by 10% per press, capped at the screen size and at a minimum of 160×90.

---

## Bar plugins

![Album art and waveform in the bar](docs/bar-media.png)

*From the left: album art, the waveform, then the clock.*

Both plugins are written from scratch and live in **`plugins/`**. `install.sh` copies them
into `~/.config/omarchy/plugins/`.

### Media controls on the waveform (`jaideep.visualizer`)

A live audio spectrum in the bar, driven by **cava**, that doubles as a media remote.

- **Waveform:** 10 bars that move with whatever is playing.
- **Click it**, or **hover it for 0.5 s**, to open a small card with three controls:
  - **⏮ Previous**
  - **⏯ Play / Pause**, whose icon follows the player's state
  - **⏭ Next**
- **Works with any player** that uses MPRIS: Spotifast, browsers, mpv and so on. It controls
  the player that is currently playing, or the first player if none is.
- **Minimal look:** equal-size icons with no button borders, and only a soft highlight on hover.
  Unavailable controls are dimmed.
- **Auto-close:** a card opened by hover closes when the pointer leaves, unless you clicked
  inside it. See [Hover to open bar panels](#hover-to-open-bar-panels-bar-hover-openpatch).
- **Resize it** by changing `popupScale` in `Visualizer.qml`. It is currently **1.35**.

### Album art: jump to the player (`jaideep.albumart`)

A small cover thumbnail of the current track.

- **Shows the cover art** of the track that is playing, or of the first player that has art.
  It hides itself when nothing has art.
- **Click the cover** to go straight to the player:
  1. **Finds the player's window.** It looks up the process behind the player and the
     Hyprland window that process owns.
  2. **Switches to its workspace** and focuses that window.
  3. **Brings the playing tab to the front** in Chromium-based browsers. If several browser
     windows are open, it picks the one titled after the track.
- **Fallback:** if a player can't switch tabs (Firefox, for example), it still focuses the
  right window.
- The logic lives in **`focus-player.sh`**. Run it with `DRY_RUN=1` to print the window it
  would pick without switching to it.

---

## Patches to existing plugins

These change plugins that a resync can overwrite. They are stored as **patches**, not
copies, so they still apply if the plugin itself gets updated.

### Hover to open bar panels (`bar-hover-open.patch`)

Applies to **`jaideep.bar`**, the bar itself, so it covers **every bar icon that has a panel**:
calendar, audio, network, Bluetooth, power, monitor, media and so on.

- **Hover an icon for 0.5 s** and its panel opens, just as if you had clicked it.
- **Auto-close:** a panel opened this way closes **about 0.4 s after the pointer leaves both
  the icon and the panel**. The short delay lets you cross the gap between them.
- **Click inside to keep it:** pressing anything in the panel, such as a button, a day or a
  text field, keeps it open. It then closes the normal way, with a click outside.
- **Panels opened by click or keyboard shortcut are not affected.**
- **Ignored while dragging:** dragging an icon to reorder the bar won't open its panel.
- **How it works:** an open panel covers the bar with an invisible full-screen layer, so the
  icon can't detect the pointer. While a hover-opened panel is open, the bar asks Hyprland
  for the cursor position (`hyprctl cursorpos`) about 8 times a second to know whether you
  are still on the icon.

> **Limitation:** while one panel is open, hovering a *different* icon won't switch panels.
> Clicking it still does.

### Calendar time column fix (`calendar-timedrow.patch`)

Applies to **`tmn73.calendar`**, the Google Calendar plugin.

- **The problem:** in the agenda list, 12-hour times like "10:00 AM" were wider than the time
  column, so they ran into the coloured calendar dot.
- **The fix:** the column now sizes itself to the widest time the current format can produce.
  Times never overlap the dot, and all the dots stay lined up.

---

## Kinetic touchpad scrolling

My patch to **[savonovv/hypr-kinetic-scroll](https://github.com/savonovv/hypr-kinetic-scroll)**,
a Hyprland plugin that adds momentum to touchpad scrolling. Files are in **`kinetic-scroll/`**.

**What the patch changes:**

- **Feels like Firefox / Zen:** the defaults follow Firefox's touchpad fling physics
  (`decel = 0.967`, `min_velocity = 0.17`, `delta_multiplier = 1.0`).
- **Better start of the glide:** momentum starts when your fingers lift, using your finger
  speed over the last 40 ms.
- **Same feel on every monitor:** the decay is based on time, not frames, so it behaves the
  same at any refresh rate.
- **Clean stop:** apps are told properly when the momentum ends.
- **Keys stop it:** a new `stop_on_motion_key` option stops the glide on arrows, Page Up/Down,
  Home, End and Space.
- **Hotplug and resume:** touchpads are found on demand, so plugging one in or waking from
  sleep keeps working.
- **Safety limits:** glides are capped at 6 s, and an invalid `decel` falls back to the default.
- **Smaller details:** window classes in `disabled_classes` are matched case-insensitively,
  and the log moved to `$XDG_RUNTIME_DIR`.

**Files:**

| File | Purpose |
|---|---|
| `hypr-kinetic-scroll.patch` | My changes to the upstream source (commit `657a8a7`) |
| `build.sh` | Downloads the upstream plugin, applies the patch and builds `hypr-kinetic-scroll.so` |
| `autostart-snippet.lua` | Loads the plugin at login and after config reloads |

**To use it:**

1. Build: `~/dotfiles/kinetic-scroll/build.sh`
2. Paste `autostart-snippet.lua` into `~/.config/hypr/autostart.lua`.

> **⚠️ Rebuild after every Hyprland update.** The `.so` only works with the Hyprland
> version it was built against, which is why only the source patch is stored here.
> `install.sh` does **not** enable this plugin.

---

## Hyprland config

`install.sh` **symlinks** these files into `~/.config/hypr/`, so editing them there edits
this repo.

- **`bindings.lua`:** the [keybindings](#keybindings) above.
- **`input.lua`:**
  - **Gestures:** swipe 3 fingers sideways to switch workspace, and pinch out with 4 fingers
    for fullscreen.
  - **Mouse:** sensitivity `0.15`, scroll speed `2.0`.
  - **Touchpad:** natural scrolling, scroll speed `0.3`, tap to click, tap and drag,
    multi-finger clicks, and the touchpad is off while typing.
  - **Spotifast** gets its own touchpad scroll speed of `1.1`.
- **`looknfeel.lua`:** corner rounding `4`, and gaps of `2` inside and out.
- **`monitors.lua`:** laptop screen (`eDP-1`) at 2x scale.
- **`hyprland.lua`:** the stock entry point that loads all of the above.
- **`autostart.lua`:** extra programs to start at login. Currently empty.

---

## What install.sh does

1. **Symlinks** `hypr/*.lua` into `~/.config/hypr/`.
2. **Symlinks** `bin/omarchy-proportional-grow` into `~/.local/bin/`.
3. **Copies** `plugins/*` into `~/.config/omarchy/plugins/`. They have to be real folders,
   because the shell ignores symlinked plugins.
4. **Applies** each patch in `patches/`. Patches that are already applied are skipped.
5. **Restarts** the Omarchy shell and **reloads** Hyprland.

---

## Repo layout

```
.
├── install.sh                  # re-apply everything
├── bin/
│   └── omarchy-proportional-grow
├── hypr/                       # Hyprland Lua config (symlinked)
├── plugins/
│   ├── jaideep.visualizer/     # waveform + media controls card
│   └── jaideep.albumart/       # cover art + jump-to-player
├── patches/
│   ├── bar-hover-open.patch    # hover to open / auto-close panels
│   └── calendar-timedrow.patch # calendar time/dot overlap fix
└── kinetic-scroll/             # patched hypr-kinetic-scroll plugin
```

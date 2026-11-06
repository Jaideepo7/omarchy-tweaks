# Omarchy Tweaks

Small additions and fixes for [Omarchy](https://omarchy.org) on Hyprland: two media widgets for
the bar, bar panels that open on hover, a bar that hides in fullscreen and comes back when you
reach for it, smoother touchpad scrolling, and a few keybindings.

![Album art and waveform in the bar](docs/bar-media.png)

*Album art, the waveform media control, then the clock.*

Each piece works **on its own**, so take only the parts you want.

---

## Contents

- [What's here](#whats-here)
- [Requirements](#requirements)
- [Installing](#installing)
- [Bar widgets](#bar-widgets)
- [Bar patches](#bar-patches)
- [Calendar fix](#calendar-fix)
- [Kinetic touchpad scrolling](#kinetic-touchpad-scrolling)
- [Proportional window resize](#proportional-window-resize)
- [My Hyprland config](#my-hyprland-config)
- [Repo layout](#repo-layout)
- [Credits](#credits)
- [License](#license)

---

## What's here

| Piece | What it does | Type |
|---|---|---|
| [`jaideep.visualizer`](#waveform-media-controls-jaideepvisualizer) | Live audio waveform in the bar. Hover or click it for previous / play-pause / next | New bar widget |
| [`jaideep.albumart`](#album-art-jaideepalbumart) | Cover art of the current track. Click it to jump to the player's window and tab | New bar widget |
| [`bar-hover-open.patch`](#hover-to-open-panels) | Every bar panel opens on hover and closes when you move away | Patch to your bar |
| [`bar-fullscreen-peek.patch`](#fullscreen-peek) | The bar hides in fullscreen and slides back in when the pointer reaches the top edge | Patch to your bar |
| [`calendar-timedrow.patch`](#calendar-fix) | Stops 12-hour times from overlapping the event dot in the calendar | Patch to `tmn73.calendar` |
| [`kinetic-scroll/`](#kinetic-touchpad-scrolling) | Momentum touchpad scrolling that feels like Firefox | Patched Hyprland plugin |
| [`omarchy-proportional-grow`](#proportional-window-resize) | Grows or shrinks a floating window while keeping its aspect ratio | Script + keybinding |
| [`hypr/`](#my-hyprland-config) | My personal Hyprland config, for reference | Config |

---

## Requirements

- **Omarchy** with the Quickshell-based `omarchy-shell` bar and the Lua Hyprland config.
- **`cava`** for the waveform: `sudo pacman -S cava`
- **`jq`** for the album-art click (installed with Omarchy).
- **`base-devel`** and Hyprland headers, only if you build the kinetic-scroll plugin.

---

## Installing

Clone the repo anywhere:

```bash
git clone https://github.com/Jaideepo7/omarchy-tweaks
cd omarchy-tweaks
```

Then follow the section for each piece you want.

> **About `install.sh`:** this is the script I use to put **my own** setup back after updates. It
> **replaces** `~/.config/hypr/{autostart,bindings,hyprland,input,looknfeel,monitors}.lua`
> with symlinks to this repo, and it patches a bar named `jaideep.bar`. Don't run it unless you
> want my entire config. [What it does](#what-installsh-does) is listed further down.

After changing anything in the bar, restart the shell:

```bash
omarchy restart shell
```

Hot reload sometimes keeps the old QML running, so restart the shell even if the log says
"reloading".

---

## Bar widgets

Both widgets are copied into `~/.config/omarchy/plugins/`. Copy the folders themselves: the
shell ignores plugins that are symlinks.

### Waveform media controls (`jaideep.visualizer`)

```bash
cp -r plugins/jaideep.visualizer ~/.config/omarchy/plugins/
omarchy plugin enable jaideep.visualizer --section center
omarchy restart shell
```

- **Waveform:** 10 bars, driven by `cava`, that move with whatever is playing.
- **Media card:** click the waveform, or hover it for 0.5 s, to get **⏮ / ⏯ / ⏭**. The
  play/pause icon follows the player's state, and controls the player doesn't support are
  dimmed.
- **Any player that uses MPRIS** works, including Spotify clients, browsers and mpv. The card
  controls whatever is playing, or the first player if nothing is.
- **Hover to open** needs the [hover patch](#hover-to-open-panels). Without it, clicking still
  works.
- **Size:** change `popupScale` in `Visualizer.qml` (the default is `1.35`).

### Album art (`jaideep.albumart`)

```bash
cp -r plugins/jaideep.albumart ~/.config/omarchy/plugins/
chmod +x ~/.config/omarchy/plugins/jaideep.albumart/focus-player.sh
omarchy plugin enable jaideep.albumart --section center
omarchy restart shell
```

- **Shows the cover** of the playing track, and hides itself when no player has artwork.
- **Click the cover to jump to the player.** `focus-player.sh` follows the player's MPRIS D-Bus
  name to its process and then to the Hyprland window that process owns. It switches to that
  workspace and focuses the window.
- **Browsers:** in Chromium-based browsers it also brings the playing tab to the front. With
  several browser windows open, it picks the one titled after the track. Firefox can't switch
  tabs this way, so it only gets the right window focused.
- **Debugging:** `DRY_RUN=1 focus-player.sh <bus> <desktop-entry> <title>` prints the window
  it would pick instead of switching to it.

**Placement:** for either widget, use `--section left|center|right`, or `--before <id>` /
`--after <id>`, to choose where it sits.

**Removing:** `omarchy plugin disable <id>` hides a widget, and `omarchy plugin remove <id>`
deletes it.

---

## Bar patches

These patch the bar's `Bar.qml`. Omarchy's built-in bar lives in `/usr/share`, where system
updates overwrite it, so you need **your own copy of the bar** first:

```bash
omarchy plugin clone omarchy.bar   # creates ~/.config/omarchy/plugins/$USER.bar and switches to it
```

The patches are stored as patches instead of whole files so that they keep applying when the
bar changes upstream. If a hunk fails, your `Bar.qml` has drifted from the version the patch was
made against. Each patch is self-contained and commented, so it can be copied in by hand.

### Hover to open panels

```bash
patch -p1 -d ~/.config/omarchy/plugins/$USER.bar < patches/bar-hover-open.patch
omarchy restart shell
```

This works for every bar icon that has a panel: calendar, audio, network, Bluetooth, power,
media and so on.

- **Hover for 0.5 s** and the panel opens as if you had clicked the icon.
- **It closes by itself** about 0.4 s after the pointer leaves both the icon and the panel. The
  delay lets you cross the gap between them.
- **Click inside to keep it open.** Once you press anything in the panel, it stays open until
  you click outside, as usual.
- **Panels opened by a click or a keyboard shortcut behave as before.** So does dragging an
  icon to reorder the bar.
- **Limitation:** while one panel is open, hovering a different icon doesn't switch panels.
  Clicking it still does.

<details>
<summary>How it works</summary>

An open panel covers the screen with an invisible layer that catches outside clicks, so the
bar icon stops receiving hover events. While a hover-opened panel is open, the bar reads the
pointer position from `hyprctl cursorpos` about 8 times a second to tell whether you're still
on the icon or the card.

</details>

**Undo:** `patch -R -p1 -d ~/.config/omarchy/plugins/$USER.bar < patches/bar-hover-open.patch`

### Fullscreen peek

Apply this **after** the hover patch:

```bash
patch -p1 -d ~/.config/omarchy/plugins/$USER.bar < patches/bar-fullscreen-peek.patch
omarchy restart shell
```

- **In fullscreen, the bar hides** just off the top of the screen.
- **Push the pointer to the top edge** and it slides in over the fullscreen window.
- **Move away** and it hides again about 0.35 s later.
- **It animates** (about 180 ms in, 120 ms out) and follows `omarchy toggle animations`.

<details>
<summary>How it works</summary>

A 2 px invisible strip on the Overlay layer watches the screen edge. Fullscreen state comes
from `hyprctl -j activeworkspace`. It is checked on Hyprland events and again every 1.5 s,
because Quickshell's `hasFullscreen` flag can fall out of sync. While the bar is showing, it
checks `hyprctl cursorpos` every 0.4 s and hides the bar if the pointer is clearly elsewhere,
in case a leave event was missed.

</details>

---

## Calendar fix

This is for the [`tmn73.calendar`](https://github.com/tmn73/omarchy-calendar) Google Calendar
plugin. In its agenda list, 12-hour times such as "10:00 AM" were wider than the time column
and ran into the coloured calendar dot. With the patch, the column sizes itself to the widest
time the current format can produce, so the dots line up and nothing overlaps.

```bash
omarchy plugin add https://github.com/tmn73/omarchy-calendar.git --enable   # if you don't have it
patch -p1 -d ~/.config/omarchy/plugins/tmn73.calendar < patches/calendar-timedrow.patch
omarchy restart shell
```

---

## Kinetic touchpad scrolling

This is a patch to [savonovv/hypr-kinetic-scroll](https://github.com/savonovv/hypr-kinetic-scroll),
a Hyprland plugin that adds momentum to touchpad scrolling.

```bash
./kinetic-scroll/build.sh                                        # clones upstream at 657a8a7, patches, builds
cat kinetic-scroll/autostart-snippet.lua >> ~/.config/hypr/autostart.lua
hyprctl plugin load ~/hypr-kinetic-scroll-patched/hypr-kinetic-scroll.so   # or log out and back in
```

> **⚠️ Rebuild after every Hyprland update.** The plugin only loads into the exact Hyprland
> version it was built against, which is why only the source patch is in this repo.

**What the patch changes:**

- **Firefox-style fling:** the defaults follow Firefox's touchpad physics (`decel = 0.967`,
  `min_velocity = 0.17`, `delta_multiplier = 1.0`).
- **Better launch:** momentum starts when your fingers lift, based on their speed over the last
  40 ms.
- **The same on every monitor:** the slowdown is based on time rather than frames, so it feels
  the same at any refresh rate.
- **Clean stop:** apps are told properly when the glide ends.
- **`stop_on_motion_key`:** a new option that stops the glide when you press an arrow key,
  Page Up/Down, Home, End or Space.
- **Hotplug and resume:** touchpads are looked up on demand, so plugging one in or waking from
  sleep keeps working.
- **Safety limits:** a glide lasts at most 6 s, and an invalid `decel` value falls back to the
  default.
- **Smaller fixes:** `disabled_classes` ignores case, and the log moved to `$XDG_RUNTIME_DIR`.

---

## Proportional window resize

`bin/omarchy-proportional-grow` grows the focused **floating** window by 10% and keeps its
aspect ratio. It stops at the edge of the screen and keeps the window on screen. With
`--shrink`, it shrinks the window by 10%, down to a minimum of 160×90. Tiled and fullscreen
windows are left alone.

```bash
install -Dm755 bin/omarchy-proportional-grow ~/.local/bin/omarchy-proportional-grow
```

Then bind it in `~/.config/hypr/bindings.lua`. `code:21` is the `=` key and `code:20` is `-`:

```lua
hl.unbind("SUPER + SHIFT + code:21")
o.bind("SUPER + SHIFT + code:21", "Grow floating window", os.getenv("HOME") .. "/.local/bin/omarchy-proportional-grow")
hl.unbind("SUPER + SHIFT + code:20")
o.bind("SUPER + SHIFT + code:20", "Shrink floating window", os.getenv("HOME") .. "/.local/bin/omarchy-proportional-grow --shrink")
```

Keep the `hl.unbind` line before each binding you change, or Omarchy's default action and your
own will both run.

---

## My Hyprland config

`hypr/` is my own config, kept here for reference. Copy any lines you like into your own files
in `~/.config/hypr/`. Hyprland reloads when you save.

**Keybindings** (`bindings.lua`):

| Shortcut | Action |
|---|---|
| Super + Shift + W | WhatsApp web app (replaces Omawrite) |
| Super + Shift + A | Claude web app (replaces ChatGPT) |
| Super + Shift + Z | Discord web app |
| Super + M | Google Messages web app |
| Super + Shift + Q | Spotifast |
| Super + H | Hermes |
| Super + N | Omawrite |
| Super + Shift + S | Screenshot (replaces Google Maps) |
| Super + Shift + F | [Strata](https://github.com/lgse/strata) file manager (replaces Nautilus) |
| Super + Alt + Shift + F | Strata, opened in the terminal's current folder |
| Super + Shift + = / - | [Grow / shrink a floating window](#proportional-window-resize) |

**Other settings:**

- **`input.lua`:** normal Caps Lock instead of Compose. Swipe 3 fingers sideways to switch
  workspace, and pinch out with 4 fingers for fullscreen. Mouse sensitivity is `0.15` with
  scroll speed `2.0`. On the touchpad: natural scrolling at speed `0.3`, tap to click, tap and
  drag, and the touchpad is off while typing. Some apps get their own scroll speed.
- **`looknfeel.lua`:** corner rounding `4` and gaps of `0` inside, `2` outside. Video players
  keep the screen awake while focused, and any app does while fullscreen.
- **`monitors.lua`:** the laptop screen (`eDP-1`) at 2x scale.
- **`autostart.lua`:** loads the kinetic-scroll plugin at login and after config reloads.

### What `install.sh` does

1. **Symlinks** `hypr/*.lua` into `~/.config/hypr/`, **replacing** whatever is there.
2. **Symlinks** `bin/omarchy-proportional-grow` into `~/.local/bin/`.
3. **Copies** `plugins/*` into `~/.config/omarchy/plugins/`.
4. **Applies** the patches to `tmn73.calendar` and `jaideep.bar`. A patch that is already
   applied, or doesn't fit, is skipped.
5. **Restarts** the shell and **reloads** Hyprland.

Running it again is safe. It doesn't build kinetic-scroll; run `kinetic-scroll/build.sh` for
that.

---

## Repo layout

```
.
├── install.sh                     # re-applies my full setup (see warning above)
├── bin/
│   └── omarchy-proportional-grow  # proportional floating-window resize
├── plugins/
│   ├── jaideep.visualizer/        # waveform + media controls
│   └── jaideep.albumart/          # cover art + jump to player
├── patches/
│   ├── bar-hover-open.patch       # hover to open / auto-close bar panels
│   ├── bar-fullscreen-peek.patch  # hide bar in fullscreen, reveal at top edge
│   └── calendar-timedrow.patch    # tmn73.calendar time/dot overlap fix
├── kinetic-scroll/                # patch + build script for hypr-kinetic-scroll
├── hypr/                          # my Hyprland Lua config
└── docs/                          # README images
```

---

## Credits

- [Omarchy](https://omarchy.org) by DHH and contributors
- [hypr-kinetic-scroll](https://github.com/savonovv/hypr-kinetic-scroll) by savonovv
- [omarchy-calendar](https://github.com/tmn73/omarchy-calendar) by tmn73
- [cava](https://github.com/karlstav/cava) for the audio spectrum

---

## License

[MIT](LICENSE)

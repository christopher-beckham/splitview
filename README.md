# splitview

A hotkey that switches macOS's native full-screen **Split View** between preset proportions (for example 80:20 and 60:40), instantly, without dragging the divider.

It works by calling the private SkyLight (window server) functions that the Dock itself uses to move the Split View divider. It needs no SIP changes, no code injection into the Dock and no `sudo`.

Tested on macOS 14.1 Sonoma (Apple Silicon).

## Install

Requires [Hammerspoon](https://www.hammerspoon.org) and the Xcode command-line tools (`clang`).

```sh
make install
```

This:
- builds `svctl` and copies it to `~/.hammerspoon/bin/svctl`
- symlinks `hammerspoon/splitview.lua` into `~/.hammerspoon/`
- creates `~/.config/splitview/ratios.txt` with the defaults, unless it already exists

Then add this line to `~/.hammerspoon/init.lua` and reload Hammerspoon:

```lua
require("splitview")
```

## Use

1. Put two apps in full-screen Split View.
2. Press **⌘⇧,** (Cmd+Shift+comma). The divider moves to the next ratio, and a popup shows the ratio, the two apps and the focused window.

Ratios are listed in `~/.config/splitview/ratios.txt`, one `left:right` per line:

```
# comments start with #
80:20
60:40
```

The file is re-read on every press, so edits take effect without reloading. Each press finds the listed ratio closest to the current layout and moves to the next one, wrapping around. That means it copes with a divider you've dragged by hand, and with three or more ratios.

## Limits

- **An app's minimum window width always wins.** The window server won't shrink a tile below the minimum its app allows, and nothing short of modifying the app gets around that. For example, Edge stops at 541 px and iTerm2 at 73 px. A ratio that would go below an app's minimum stops there.
- **Moving the divider has an extra floor of about 94 px** on the narrow side, so `100:0` doesn't quite reach the app's minimum.
- **Only two-tile Split Views are supported.**
- **These are private APIs.** A macOS update can break them without warning.

## svctl

`svctl` can also be run on its own. `<wid>` is a window ID (Hammerspoon's `hs.window:id()`). If that window isn't in a Split View, the one on the active Space is used.

| Command | What it does |
|---|---|
| `svctl info <wid>` | Prints `dividerX layoutWidth spacing`, then the left and right app names |
| `svctl divider <wid> <x>` | Moves the divider's left edge to x |
| `svctl collapse-other <wid>` | Shrinks the other tile to its app's minimum width and prints the previous divider x |

## How it works

The private functions, with signatures worked out from disassembly:

```c
// list displays/Spaces; a Split View Space has a "TileLayoutManager" dict
// holding each tile's rect, size constraints, app and window ID
CFArrayRef SLSCopyManagedDisplaySpaces(int cid);

// locate the divider ("spacer") at a point
void SLSSpaceGetSpacersAtPoint(int cid, uint64_t space, CGPoint p,
                               long *vIndex, long *hIndex, CGRect *rect);

// move the divider; the point sets the divider's left edge
int SLSSpaceMoveSpacersToPoint(int cid, uint64_t space, long vIndex,
                               long hIndex, CGPoint p, int options);

// size a tile directly; reaches the app's own minimum width
int SLSTileSpaceMoveSpacersForSize(uint64_t tileSpace, CGSize size);
```

Hammerspoon can't resize full-screen windows through its usual APIs, which is why this goes through the window server instead.

`research/` holds the probes used to work this out: read-only space and tile dumps, the divider move tests, and a dead end on reading other apps' window constraints.

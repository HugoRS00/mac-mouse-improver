# Mac Mouse Improver

A tiny, beautiful macOS menu-bar app that gives your cursor a clean,
bold black-with-white-outline look — with a subtle scale animation on click.

One click in the menu bar to toggle it on or off. That's the whole app.

```
   ╱
  ╱
 ╱
╱_╱
 ╱_╱
```

## Features

- Clean black cursor with crisp white outline and a soft drop shadow
- Subtle press/release scale animation on every click
- Enable / disable from the menu bar with one click
- Launch at login (opt-in)
- Multi-monitor and Spaces aware
- Menu-bar-only — no dock icon, no window clutter
- No tracking, no analytics, no network. Pure local app
- 100% open source under the MIT license

## Install

### Option 1 — One-line install (recommended)

Open Terminal and paste:

```bash
git clone https://github.com/HugoRS00/mac-mouse-improver.git \
    && cd mac-mouse-improver \
    && ./install.sh
```

That clones the repo, builds the app, installs it to `/Applications`, and
launches it. Look for the cursor icon in your menu bar.

> Requires the Xcode Command Line Tools. If you don't have them, macOS will
> prompt you to install them automatically the first time the script runs
> (or you can run `xcode-select --install` yourself).

### Option 2 — Build by hand

```bash
git clone https://github.com/HugoRS00/mac-mouse-improver.git
cd mac-mouse-improver
./build.sh
open "build/Mac Mouse Improver.app"
```

To install permanently:

```bash
cp -R "build/Mac Mouse Improver.app" /Applications/
```

### Option 3 — Download a release

If a pre-built release is available, grab the latest `.app.zip` from
[Releases](https://github.com/HugoRS00/mac-mouse-improver/releases),
unzip it, and drag `Mac Mouse Improver.app` to `/Applications`.

Because the app isn't notarized, you'll need to **right-click → Open**
the first time. After that it just runs.

## Usage

1. Open the app. A cursor icon appears in your menu bar.
2. Click it to open the menu.
3. Use the **Enabled** item to toggle the custom cursor on or off.
4. Optionally turn on **Launch at Login**.

That's it.

## Uninstall

```bash
rm -rf "/Applications/Mac Mouse Improver.app"
defaults delete dev.macmouseimprover.app 2>/dev/null || true
```

## How it works

The app paints a custom cursor inside a transparent, click-through overlay
window that floats above every space and follows the real mouse position
via `NSEvent` global monitors. The system cursor underneath is mostly hidden
behind the new artwork. Nothing system-wide is patched and no kernel or
private APIs are used.

See [`Sources/`](Sources/) — it's only a few hundred lines of Swift.

## Requirements

- macOS 12 (Monterey) or newer
- Xcode Command Line Tools (only to build from source)

## Contributing

Pull requests welcome. Things on the wishlist:

- Configurable cursor colors and sizes
- Custom cursor for `IBeam`, `crosshair`, `link`, etc.
- A real app icon
- Notarized release builds

## License

MIT — see [LICENSE](LICENSE).

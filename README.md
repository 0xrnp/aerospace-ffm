# aerospace-ffm

Focus follows mouse for [AeroSpace](https://github.com/nikitabobko/AeroSpace). Rest the mouse on a window and it gets focus.

AeroSpace has no focus-follows-mouse setting. This is a small helper that adds it. It needs no macOS permissions and uses no private APIs.

## How it works

1. Every 20ms it reads the cursor position.
2. When the cursor has rested for a moment (60ms by default), it asks the macOS window server which window a click at that point would reach.
3. If that is a different window from the last rest, and AeroSpace manages it on a visible workspace, it runs `aerospace focus --window-id <id>`.

AeroSpace's window IDs are the same numbers macOS uses, so there is no translation step. AeroSpace does the focusing; this tool never touches windows itself.

Asking "where would a click land" rather than "what is drawn here" matters. Invisible click-through windows, such as [JankyBorders](https://github.com/FelixKratz/JankyBorders) borders or overlays the screenshot tool sometimes leaves behind, are looked through. Anything that takes the mouse, such as a menu, the menu bar, the Dock, or a launcher like Spotlight, stops it.

It leaves focus alone when:

- the cursor is over a menu, the menu bar, the Dock, a launcher, or the desktop
- a mouse button is held (dragging, selecting text)
- the cursor rests again over the window it rested on last time, so focus you change with the keyboard sticks until the mouse moves to another window
- the window is on a hidden workspace (AeroSpace parks those in a screen corner, and focusing one would switch workspaces)
- it has just started: the first rest only records the window under the cursor

## Requirements

- macOS 13 or later
- AeroSpace, running, with the `aerospace` CLI installed
- Xcode or the Command Line Tools, to build

Without AeroSpace the tool does nothing: it exits with a message if it can't find the CLI, and logs an error on each window change if AeroSpace isn't running. If you don't use AeroSpace, try [AutoRaise](https://github.com/sbmpost/AutoRaise), which handles regular macOS windows.

## Install

```sh
git clone https://github.com/0xrnp/aerospace-ffm
cd aerospace-ffm
make install
```

This puts the binary in `~/.local/bin`. Use `make install PREFIX=/usr/local` to install somewhere else.

## Run it

Try it in a terminal first:

```sh
aerospace-ffm --verbose
```

Move the mouse between windows and rest it for a moment. Each decision is logged. Stop it with Ctrl-C.

To start it with AeroSpace, add it to `after-startup-command` in `~/.config/aerospace/aerospace.toml`. Use the full path, because AeroSpace may not have your shell's `PATH`:

```toml
after-startup-command = [
  'exec-and-forget /Users/<you>/.local/bin/aerospace-ffm',
]
```

If you already have entries in that list, add this one to it. `after-startup-command` runs when AeroSpace starts, not when the config reloads, so restart AeroSpace or log in again.

Only one copy runs at a time; a second one exits with `another aerospace-ffm is already running`. That also means a copy started by AeroSpace keeps running across AeroSpace restarts. To stop it, for example before testing in a terminal or after installing a new version:

```sh
pkill -x aerospace-ffm
```

## Options

| Option | Default | Meaning |
|---|---|---|
| `--delay <ms>` | 60 | How long the mouse must rest before focus changes (0 to 5000, checked every 20ms) |
| `--aerospace <path>` | search `PATH`, then Homebrew locations | Path to the `aerospace` CLI |
| `--verbose` | off | Log every focus decision to stderr |
| `--version` | | Print the version |

A higher delay helps if focus changes while you are only passing over windows, for example on the way to the menu bar.

## Known limits

- AeroSpace's default config has `on-focused-monitor-changed = ['move-mouse monitor-lazy-center']`. When you switch monitors from the keyboard, the cursor jumps to the monitor's center, which can be over a different window than the one AeroSpace just focused, and this tool then focuses that window. Replace it with `on-focus-changed = ['move-mouse window-lazy-center']`, which moves the cursor onto the window AeroSpace actually focused, or remove the line.
- The macOS menu bar belongs to the focused app. If you rest the mouse on a window on your way to the menu bar, the menus switch to that app. A longer `--delay` reduces this.
- Windows that AeroSpace doesn't manage never get focus from this tool.
- If an `aerospace` call takes longer than 2 seconds, it is cancelled and logged, and the tool carries on.
- It only talks to AeroSpace. yabai and other window managers are not supported.

## Development

```sh
make test
```

The decisions (when the mouse has rested, when focus should move) live in `Sources/FFMCore` and are unit tested. The polling loop and the calls to macOS and AeroSpace are in `Sources/aerospace-ffm/main.swift`.

## License

MIT

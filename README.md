# claude-notch-notify

**Get a visible alert on your MacBook when Claude Code finishes a reply: your keyboard flashes
and a little pop-up grows out of the notch.**

Stop staring at the terminal while Claude works. Go do something else, and your Mac will let you
know when it's done (or when it needs your approval).

- ⌨️ **`kbflash`** flashes the **keyboard backlight** and the **green caps lock LED** together
- 🟠 **`notchpop`** grows a black pop-up out of the **notch** with a pulsing orange spark and a message
- 🔁 Restores your original brightness, auto-brightness and caps lock light afterwards
- 🔒 Caps lock light blinks **without** turning caps lock on
- 🙈 The pop-up never steals focus, ignores clicks, and has no Dock icon
- ⚡ Tiny native binaries, no dependencies, ~3 seconds per alert
- 🪝 Plugs straight into [Claude Code hooks](https://docs.claude.com/en/docs/claude-code/hooks)

## Requirements

- A MacBook with a backlit keyboard (tested on an M5 MacBook Pro, macOS 26)
- A notch for the full pop-up effect (without one it shows as a small tab at the top of the screen)
- Xcode Command Line Tools (`xcode-select --install`) for `clang` and `swiftc`
- [Claude Code](https://claude.com/claude-code) (terminal, VS Code extension, or the desktop app's Code tab)

## Install

```bash
git clone https://github.com/elliotwhittard/claude-notch-notify.git
cd claude-notch-notify
./install.sh
```

This compiles both tools into `~/.claude/bin/` and runs a test alert.

## Hook it into Claude Code

Add this to `~/.claude/settings.json` (create the file if it doesn't exist; merge it in if it does):

```json
{
  "hooks": {
    "Stop": [
      { "hooks": [{ "type": "command", "command": "~/.claude/bin/notchpop 'Claude is done' 3 >/dev/null 2>&1 & ~/.claude/bin/kbflash 2 5" }] }
    ],
    "Notification": [
      { "hooks": [{ "type": "command", "command": "~/.claude/bin/notchpop 'Needs you' 3 >/dev/null 2>&1 & ~/.claude/bin/kbflash 2 2 400 200" }] }
    ]
  }
}
```

| Hook | When it fires | Alert |
| --- | --- | --- |
| `Stop` | Claude finished responding | "Claude is done" pop-up + 2 backlight flashes + 5 caps lock flashes |
| `Notification` | Claude is waiting on you (e.g. a permission prompt) | "Needs you" pop-up + 2 flashes of both lights |

The `&` runs the pop-up and the keyboard flash at the same time. Want only one of them? Keep just that
half of the command.

Start a new Claude Code session afterwards so it picks up the settings.

## Usage

### kbflash

```bash
kbflash [backlight_flashes] [caps_flashes] [on_ms] [off_ms]
```

| Argument | Default | Meaning |
| --- | --- | --- |
| `backlight_flashes` | `2` | Blinks of the keyboard backlight |
| `caps_flashes` | `5` | Blinks of the green caps lock light |
| `on_ms` | `400` | Milliseconds lit |
| `off_ms` | `250` | Milliseconds dark |

```bash
kbflash                   # backlight x2, caps lock x5, 400 ms on, 250 ms off
kbflash 5 5               # both lights 5 times
kbflash 0 5               # caps lock light only
kbflash 3 3 150 150       # 3 fast blinks of both
kbflash 8 8 600 400       # slow and obvious
KBFLASH_DEBUG=1 kbflash   # print what it's doing
```

### notchpop

```bash
notchpop [message] [seconds]
```

| Argument | Default | Meaning |
| --- | --- | --- |
| `message` | `Done` | Text shown to the right of the notch |
| `seconds` | `3` | How long it stays open |

```bash
notchpop                        # "Done" for 3 seconds
notchpop "Tests passed" 5       # any message you like
```

### Add a sound

```json
{ "type": "command", "command": "~/.claude/bin/notchpop 'Claude is done' 3 >/dev/null 2>&1 & ~/.claude/bin/kbflash 2 5; afplay /System/Library/Sounds/Glass.aiff" }
```

## How it works

- **Backlight:** Apple's private `CoreBrightness` framework (`KeyboardBrightnessClient`), the same
  API Control Centre uses. Brightness changes are applied instantly and aren't saved as your preference.
  Auto-brightness is paused during the flash so it doesn't fight back.
- **Caps lock LED:** IOKit HID. The program writes the keyboard's LED output element directly, which
  lights the LED without changing the actual caps lock state.
- **Notch pop-up:** a borderless AppKit panel at screen-saver level, so it sits above the menu bar.
  It reads the notch's exact size from `NSScreen` (`safeAreaInsets` and the auxiliary top areas), starts
  as a black shape covering the notch, springs outwards into "ears" on each side, then shrinks back and exits.

## Caveats

- `CoreBrightness` is a private framework. It works on current macOS, but Apple could change it.
- The keyboard flash is hard to see in a bright room.
- The MacBook backlight is one zone, so per-key effects (ripples, single rows) aren't possible.
- The orange spark is an original drawing, not an official Anthropic logo.

## Uninstall

```bash
rm ~/.claude/bin/kbflash ~/.claude/bin/notchpop
```

Then remove the `hooks` entries from `~/.claude/settings.json`.

## License

[MIT](LICENSE)

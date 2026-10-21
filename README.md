# claude-glow

`kbflash` — **flash your MacBook's keyboard backlight and caps lock light when Claude Code finishes a reply.**

Stop staring at the terminal while Claude works. Go do something else, and your keyboard
will blink at you when it's done (or when it needs your approval).

- ⌨️ Flashes the **keyboard backlight** and the **green caps lock LED** together
- 🔁 Restores your original brightness, auto-brightness and caps lock light afterwards
- 🔒 Caps lock light blinks **without** turning caps lock on
- ⚡ Tiny native binary, no dependencies, ~3 seconds per alert
- 🪝 Plugs straight into [Claude Code hooks](https://docs.claude.com/en/docs/claude-code/hooks)

## Requirements

- A MacBook with a backlit keyboard (tested on an M5 MacBook, macOS 26)
- Xcode Command Line Tools (`xcode-select --install`) for `clang`
- [Claude Code](https://claude.com/claude-code) (terminal, VS Code extension, or the desktop app's Code tab)

## Install

```bash
git clone https://github.com/elliotwhittard/claude-glow.git
cd claude-glow
./install.sh
```

This compiles `kbflash.m` into `~/.claude/bin/kbflash` and runs a test flash.

## Hook it into Claude Code

Add this to `~/.claude/settings.json` (create the file if it doesn't exist; merge it in if it does):

```json
{
  "hooks": {
    "Stop": [
      { "hooks": [{ "type": "command", "command": "~/.claude/bin/kbflash 5" }] }
    ],
    "Notification": [
      { "hooks": [{ "type": "command", "command": "~/.claude/bin/kbflash 2 400 200" }] }
    ]
  }
}
```

| Hook | When it fires | Flash |
| --- | --- | --- |
| `Stop` | Claude finished responding | 5 flashes |
| `Notification` | Claude is waiting on you (e.g. a permission prompt) | 2 slow flashes |

Start a new Claude Code session afterwards so it picks up the settings.

## Usage

```bash
kbflash [flashes] [on_ms] [off_ms]
```

| Argument | Default | Meaning |
| --- | --- | --- |
| `flashes` | `5` | Number of blinks |
| `on_ms` | `400` | Milliseconds lit |
| `off_ms` | `250` | Milliseconds dark |

```bash
kbflash                   # 5 flashes, 400 ms on, 250 ms off
kbflash 3 150 150         # 3 fast blinks
kbflash 8 600 400         # slow and obvious
KBFLASH_DEBUG=1 kbflash   # print what it's doing
```

Want a sound as well?

```json
{ "type": "command", "command": "~/.claude/bin/kbflash 5; afplay /System/Library/Sounds/Glass.aiff" }
```

## How it works

- **Backlight:** Apple's private `CoreBrightness` framework (`KeyboardBrightnessClient`), the same
  API Control Centre uses. Brightness changes are applied instantly and aren't saved as your preference.
  Auto-brightness is paused during the flash so it doesn't fight back.
- **Caps lock LED:** IOKit HID. The program writes the keyboard's LED output element directly, which
  lights the LED without changing the actual caps lock state.

## Caveats

- `CoreBrightness` is a private framework. It works on current macOS, but Apple could change it.
- The flash is hard to see in a bright room.
- Only the built-in keyboard backlight is used. External keyboards still get the caps lock flash if
  they expose a caps lock LED.

## Uninstall

```bash
rm ~/.claude/bin/kbflash
```

Then remove the `hooks` entries from `~/.claude/settings.json`.

## License

[MIT](LICENSE)

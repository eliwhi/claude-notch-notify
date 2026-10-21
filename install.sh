#!/bin/bash
# Installs kbflash, notchpop and notch-alert to ~/.claude/bin and adds the Claude Code hooks.
#
# One-liner:
#   curl -fsSL https://raw.githubusercontent.com/eliwhi/claude-notch-notify/main/install.sh | bash
#
# Options:
#   --no-hooks   install the programs only, don't touch ~/.claude/settings.json
set -euo pipefail

REPO="eliwhi/claude-notch-notify"
BIN_DIR="$HOME/.claude/bin"
SETTINGS="$HOME/.claude/settings.json"
ADD_HOOKS=1
[[ "${1:-}" == "--no-hooks" ]] && ADD_HOOKS=0

if [[ "$(uname)" != "Darwin" ]]; then
  echo "notch-notify only works on macOS." >&2
  exit 1
fi

# Use the prebuilt programs next to this script when run from a clone,
# otherwise download them from the latest GitHub release.
SCRIPT_DIR=""
if [[ -n "${BASH_SOURCE[0]:-}" && -f "${BASH_SOURCE[0]}" ]]; then
  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
fi
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

if [[ -n "$SCRIPT_DIR" && -x "$SCRIPT_DIR/dist/kbflash" && -x "$SCRIPT_DIR/dist/notchpop" && -x "$SCRIPT_DIR/dist/notch-alert" ]]; then
  SRC="$SCRIPT_DIR/dist"
else
  echo "Downloading the latest release..."
  curl -fsSL "https://github.com/$REPO/releases/latest/download/notch-notify-macos.zip" -o "$TMP/release.zip"
  unzip -q "$TMP/release.zip" -d "$TMP"
  SRC="$TMP"
fi

mkdir -p "$BIN_DIR"
install -m 755 "$SRC/kbflash" "$SRC/notchpop" "$SRC/notch-alert" "$BIN_DIR/"
xattr -d com.apple.quarantine "$BIN_DIR/kbflash" "$BIN_DIR/notchpop" "$BIN_DIR/notch-alert" 2>/dev/null || true
echo "Installed kbflash, notchpop and notch-alert to $BIN_DIR"

if [[ $ADD_HOOKS == 1 ]]; then
  mkdir -p "$(dirname "$SETTINGS")"
  [[ -f "$SETTINGS" ]] && cp "$SETTINGS" "$SETTINGS.bak" && echo "Backed up settings to $SETTINGS.bak"

  # Merge the hooks into settings.json with macOS's built-in JavaScript, keeping everything
  # else in the file. Any older notch-notify hooks are replaced rather than duplicated.
  osascript -l JavaScript - "$SETTINGS" <<'JS'
function run(argv) {
  const path = argv[0];
  const fm = $.NSFileManager.defaultManager;
  let settings = {};
  if (fm.fileExistsAtPath(path)) {
    const text = $.NSString.stringWithContentsOfFileEncodingError(path, $.NSUTF8StringEncoding, null).js;
    if (text.trim()) settings = JSON.parse(text);
  }
  const ours = {
    Stop: "~/.claude/bin/notch-alert done",
    Notification: "~/.claude/bin/notch-alert needs-you",
  };
  const isOurs = (h) => /kbflash|notchpop|notch-alert/.test(h.command || "");
  settings.hooks = settings.hooks || {};
  for (const event of Object.keys(ours)) {
    const groups = (settings.hooks[event] || [])
      .map((g) => Object.assign({}, g, { hooks: (g.hooks || []).filter((h) => !isOurs(h)) }))
      .filter((g) => g.hooks.length > 0);
    groups.push({ hooks: [{ type: "command", command: ours[event] }] });
    settings.hooks[event] = groups;
  }
  $(JSON.stringify(settings, null, 2) + "\n").writeToFileAtomicallyEncodingError(path, true, $.NSUTF8StringEncoding, null);
}
JS
  echo "Added Stop and Notification hooks to $SETTINGS"
fi

echo "Testing..."
NOTCH_DONE_MESSAGE="notch-notify installed" "$BIN_DIR/notch-alert" done
wait
echo "Done! Start a new Claude Code session to pick up the hooks."

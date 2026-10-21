#!/bin/bash
# Removes kbflash, notchpop and notch-alert from ~/.claude/bin and their hooks from ~/.claude/settings.json.
#
#   curl -fsSL https://raw.githubusercontent.com/eliwhi/claude-notch-notify/main/uninstall.sh | bash
set -euo pipefail

SETTINGS="$HOME/.claude/settings.json"
rm -f "$HOME/.claude/bin/kbflash" "$HOME/.claude/bin/notchpop" "$HOME/.claude/bin/notch-alert"
echo "Removed kbflash, notchpop and notch-alert from ~/.claude/bin"

if [[ -f "$SETTINGS" ]]; then
  cp "$SETTINGS" "$SETTINGS.bak"
  osascript -l JavaScript - "$SETTINGS" <<'JS'
function run(argv) {
  const path = argv[0];
  const text = $.NSString.stringWithContentsOfFileEncodingError(path, $.NSUTF8StringEncoding, null).js;
  const settings = text.trim() ? JSON.parse(text) : {};
  const isOurs = (h) => /kbflash|notchpop|notch-alert/.test(h.command || "");
  for (const event of Object.keys(settings.hooks || {})) {
    settings.hooks[event] = settings.hooks[event]
      .map((g) => Object.assign({}, g, { hooks: (g.hooks || []).filter((h) => !isOurs(h)) }))
      .filter((g) => g.hooks.length > 0);
    if (settings.hooks[event].length === 0) delete settings.hooks[event];
  }
  if (settings.hooks && Object.keys(settings.hooks).length === 0) delete settings.hooks;
  $(JSON.stringify(settings, null, 2) + "\n").writeToFileAtomicallyEncodingError(path, true, $.NSUTF8StringEncoding, null);
}
JS
  echo "Removed notch-notify hooks from $SETTINGS (backup at $SETTINGS.bak)"
fi

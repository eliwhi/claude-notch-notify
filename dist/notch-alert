#!/bin/bash
# notch-alert: the one command the Claude Code hooks run. Shows the notch pop-up, flashes the
# keyboard and optionally plays a sound, all at once.
#
# Usage:
#   notch-alert done        # Claude finished a reply
#   notch-alert needs-you   # Claude is waiting for you
#
# Settings come from the plugin's options (CLAUDE_PLUGIN_OPTION_*), then from NOTCH_* environment
# variables (set them under "env" in ~/.claude/settings.json), then from the defaults below.

event="${1:-done}"
dir="$(cd "$(dirname "$0")" && pwd)"

# setting NAME DEFAULT: plugin option, then NOTCH_ env var, then default.
setting() {
  local plugin_var="CLAUDE_PLUGIN_OPTION_$1" env_var="NOTCH_$1"
  local value="${!plugin_var:-${!env_var:-}}"
  echo "${value:-$2}"
}
# Plugin number options can arrive as "2.0"; keep the whole number.
whole() { local n="${1%%.*}"; [[ "$n" =~ ^[0-9]+$ ]] && echo "$n" || echo "$2"; }

seconds="$(setting POPUP_SECONDS 3)"
sound="$(setting SOUND none)"
if [[ "$event" == "needs-you" ]]; then
  message="$(setting NEEDS_YOU_MESSAGE "Needs you")"
  backlight=2; caps=2; on_ms=400; off_ms=200
else
  message="$(setting DONE_MESSAGE "Claude is done")"
  backlight="$(whole "$(setting BACKLIGHT_FLASHES 2)" 2)"
  caps="$(whole "$(setting CAPS_FLASHES 5)" 5)"
  on_ms=400; off_ms=250
fi

if [[ "$(setting SHOW_POPUP true)" != "false" ]]; then
  "$dir/notchpop" "$message" "$seconds" >/dev/null 2>&1 &
fi
if [[ -n "$sound" && "$sound" != "none" && -f "/System/Library/Sounds/$sound.aiff" ]]; then
  afplay "/System/Library/Sounds/$sound.aiff" >/dev/null 2>&1 &
fi
"$dir/kbflash" "$backlight" "$caps" "$on_ms" "$off_ms"

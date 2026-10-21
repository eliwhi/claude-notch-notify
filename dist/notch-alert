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

# Each setting: plugin option, then NOTCH_ env var, then default. Every variable is named
# explicitly so it's clear exactly what the script reads.
# Plugin number options can arrive as "2.0"; keep the whole number.
whole() { local n="${1%%.*}"; [[ "$n" =~ ^[0-9]+$ ]] && echo "$n" || echo "$2"; }

seconds="${CLAUDE_PLUGIN_OPTION_POPUP_SECONDS:-${NOTCH_POPUP_SECONDS:-3}}"
sound="${CLAUDE_PLUGIN_OPTION_SOUND:-${NOTCH_SOUND:-none}}"
show_popup="${CLAUDE_PLUGIN_OPTION_SHOW_POPUP:-${NOTCH_SHOW_POPUP:-true}}"
if [[ "$event" == "needs-you" ]]; then
  message="${CLAUDE_PLUGIN_OPTION_NEEDS_YOU_MESSAGE:-${NOTCH_NEEDS_YOU_MESSAGE:-Needs you}}"
  backlight=2; caps=2; on_ms=400; off_ms=200
else
  message="${CLAUDE_PLUGIN_OPTION_DONE_MESSAGE:-${NOTCH_DONE_MESSAGE:-Claude is done}}"
  backlight="$(whole "${CLAUDE_PLUGIN_OPTION_BACKLIGHT_FLASHES:-${NOTCH_BACKLIGHT_FLASHES:-2}}" 2)"
  caps="$(whole "${CLAUDE_PLUGIN_OPTION_CAPS_FLASHES:-${NOTCH_CAPS_FLASHES:-5}}" 5)"
  on_ms=400; off_ms=250
fi

if [[ "$show_popup" != "false" ]]; then
  "$dir/notchpop" "$message" "$seconds" >/dev/null 2>&1 &
fi
if [[ -n "$sound" && "$sound" != "none" && -f "/System/Library/Sounds/$sound.aiff" ]]; then
  afplay "/System/Library/Sounds/$sound.aiff" >/dev/null 2>&1 &
fi
"$dir/kbflash" "$backlight" "$caps" "$on_ms" "$off_ms"

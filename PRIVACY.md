# Privacy policy

_Last updated: 21 October 2026_

notch-notify (the "Notch Notify" Claude Code plugin, and the `kbflash`, `notchpop` and `notch-alert`
programs in this repository) runs entirely on your Mac.

## What it collects

Nothing. notch-notify does not collect, store or share any personal data, usage data or analytics.

## What it accesses on your Mac

Only what it needs to show an alert, and only while the alert is running (about 3 seconds):

- **The keyboard backlight and caps lock light:** it reads their current state, flashes them, then puts
  them back as they were.
- **The screen's notch size:** so the pop-up lines up with the notch.
- **The list of parent processes:** so clicking the pop-up can reopen the app that launched Claude Code.
- **Its own settings:** the plugin options you choose, or `NOTCH_*` environment variables.

It does not read your conversations, files, code, or anything from your Claude Code sessions.

## Network

notch-notify makes no network requests and sends no data anywhere.

The optional one-line installer (`install.sh`) downloads the programs from this repository's GitHub
releases. That download is subject to [GitHub's privacy statement](https://docs.github.com/site-policy/privacy-policies/github-general-privacy-statement).
The plugin itself downloads nothing.

## Contact

Questions or concerns: [open an issue](https://github.com/eliwhi/claude-notch-notify/issues).

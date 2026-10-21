#!/bin/zsh
# Builds kbflash and installs it to ~/.claude/bin/kbflash.
set -e
cd "$(dirname "$0")"
mkdir -p ~/.claude/bin
clang -fobjc-arc -framework Foundation -framework IOKit \
  -F /System/Library/PrivateFrameworks -framework CoreBrightness \
  kbflash.m -o ~/.claude/bin/kbflash
echo "Installed ~/.claude/bin/kbflash — testing now..."
~/.claude/bin/kbflash 5

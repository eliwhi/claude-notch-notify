#!/bin/zsh
# Builds kbflash and notchpop and installs them to ~/.claude/bin.
set -e
cd "$(dirname "$0")"
mkdir -p ~/.claude/bin
clang -fobjc-arc -framework Foundation -framework IOKit \
  -F /System/Library/PrivateFrameworks -framework CoreBrightness \
  kbflash.m -o ~/.claude/bin/kbflash
swiftc -O notchpop.swift -o ~/.claude/bin/notchpop
echo "Installed ~/.claude/bin/kbflash and ~/.claude/bin/notchpop — testing now..."
~/.claude/bin/notchpop "Installed" 3 &
~/.claude/bin/kbflash
wait

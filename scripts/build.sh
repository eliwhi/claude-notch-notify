#!/bin/zsh
# Builds universal (Apple Silicon + Intel) kbflash and notchpop into dist/, plus the notch-alert script.
set -e
cd "$(dirname "$0")/.."
mkdir -p dist
TMP=$(mktemp -d)
MIN=13.0

clang -fobjc-arc -O2 -arch arm64 -arch x86_64 -mmacosx-version-min=$MIN \
  -framework Foundation -framework IOKit \
  -F /System/Library/PrivateFrameworks -framework CoreBrightness \
  src/kbflash.m -o dist/kbflash

for arch in arm64 x86_64; do
  swiftc -O -target $arch-apple-macos$MIN src/notchpop.swift -o "$TMP/notchpop-$arch"
done
lipo -create "$TMP/notchpop-arm64" "$TMP/notchpop-x86_64" -output dist/notchpop

codesign --force --sign - dist/kbflash dist/notchpop
install -m 755 src/notch-alert.sh dist/notch-alert
rm -rf "$TMP"
echo "Built dist/kbflash, dist/notchpop and dist/notch-alert:"
lipo -info dist/kbflash dist/notchpop

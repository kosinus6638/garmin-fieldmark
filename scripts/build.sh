#!/usr/bin/env bash
# Builds the .prg file for the specified device target.
# Run inside the dev container, or on host if SDK is in PATH.
#
# Usage:
#   bash scripts/build.sh              # builds for fr255music (default)
#   bash scripts/build.sh fr255music   # explicit device target
#
# To sideload the built .prg to your watch:
#   1. Connect watch via USB
#   2. Mount via MTP (file manager or: gio mount)
#   3. Copy bin/fr255music.prg to GARMIN/Apps/ on the watch
#   4. Eject and disconnect — app appears immediately

set -euo pipefail

DEVICE="${1:-fr255m}"
KEY="keys/developer_key.der"
OUT="bin/${DEVICE}.prg"

if [ ! -f "$KEY" ]; then
    echo "Error: Developer key not found at $KEY"
    echo "Run: bash scripts/gen-key.sh"
    exit 1
fi

mkdir -p bin

monkeyc \
    -f monkey.jungle \
    -o "$OUT" \
    -d "$DEVICE" \
    -y "$KEY" \
    -w

echo "==> Built: $OUT"
echo "    Copy to GARMIN/Apps/ on the watch to sideload."

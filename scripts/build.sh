#!/bin/sh
set -eu
ROOT="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
OUT="$ROOT/build"
mkdir -p "$OUT"
xcrun -sdk macosx metal -c "$ROOT/kernel/m3b2_reference.metal" -o "$OUT/m3b2.air"
xcrun -sdk macosx metallib "$OUT/m3b2.air" -o "$OUT/m3b2.metallib"
echo "Built: $OUT/m3b2.metallib"

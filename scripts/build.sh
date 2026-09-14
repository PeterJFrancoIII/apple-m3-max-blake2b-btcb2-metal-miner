#!/bin/sh
set -eu
ROOT="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
OUT="$ROOT/build"
mkdir -p "$OUT"

xcrun -sdk macosx metal -c "$ROOT/kernel/m3b2_reference.metal" -o "$OUT/m3b2.air"
xcrun -sdk macosx metallib "$OUT/m3b2.air" -o "$OUT/m3b2.metallib"

clang++ -std=c++17 -fobjc-arc -framework Foundation -framework Metal \
  "$ROOT/src/m3b2_bench.mm" -o "$OUT/m3b2-bench"

echo "Built: $OUT/m3b2.metallib"
echo "Built: $OUT/m3b2-bench"
echo "Run:   $OUT/m3b2-bench $OUT/m3b2.metallib"

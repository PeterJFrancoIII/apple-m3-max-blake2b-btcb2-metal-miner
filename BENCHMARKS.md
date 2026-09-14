# M3 Max BTCB2 / BLAKE2b Benchmarks

Hardware: Apple M3 Max, 30-core GPU, 36 GB unified memory. Primary metric: **incremental whole-package J/GH**.

| Kernel | MH/s | GPU W | Incremental package J/GH | Result |
|---|---:|---:|---:|---|
| A — universal specialized | ~1,110 | ~41–46 | ~40.8–43.5 | baseline |
| B — job-specialized | ~1,113–1,128 | ~40–45 | ~40.2 | accepted improvement |
| D1 — split lifetime | ~1,105 | ~41 | ~38.7 | statistical parity / non-win |
| D2 — 2-way ARX | ~1,082 | ~45.2 | **47.8** | rejected |
| C — 4-way ARX | ~1,109 | ~45.0 | **42.3** | rejected |
| **D3 — straight-line generated** | **~1,129** | **~39.8** | **~36.9** | **current champion** |
| D4 — extra constant folding | ~1,111 | ~40.8 | ~39.6 median | statistical parity; no promotion |

## Repeatedly best launch geometry

- threadgroup size: **64**
- steps/thread: **128**
- pipeline depth: **1**
- GPU-only hashing
- CPU reserved for network/job coordination
- job-specialized Metal pipeline

## D3 controlled comparison

Representative randomized thermal-steady-state D3 result:

- median hashrate: **1,128.90 MH/s**
- median GPU core power: **39.77 W**
- median GPU energy: **35.24 J/GH**
- median incremental package power: **41.63 W**
- median incremental package energy: **36.90 J/GH**
- dynamic compile latency: **~0.23 ms** in the benchmarked generated form

D3's improvement over the preceding B kernel was small relative to run-to-run variance, so it is the current champion, not proof that optimization is saturated.

## Rejected scheduling experiments

**2-way and 4-way ARX interleaving both worsened package J/GH.** Increasing simultaneously live 64-bit state did not pay off on the tested M3 Max. This is empirical evidence against those specific schedules, not proof that every alternate schedule is inferior.

## Low-duty telemetry warning

Two nominal 30% duty measurements materially disagree:

- earlier calibrated run: **305.1 MH/s, 5.1 W incremental package, 16.83 J/GH**
- later D3 sweep: **311 MH/s, 13.1 W incremental package, 42.03 J/GH**

Because hashrate was similar but incremental package power differed by ~2.6×, the low-duty telemetry methodology must be reconciled before any low-duty number is treated as the global efficiency optimum.

## Still open

1. Fixed-duty D3 stock vs command-buffer/encoder-coalesced host runtime A/B.
2. Compiler/AIR-guided low-live-range D3 schedule search.
3. Eliminate any remaining runtime invariants, avoidable loads/moves, or branches.
4. Re-run final power/duty sweep only after kernel/runtime efficiency plateaus.

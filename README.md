# Apple M3 Max BLAKE2b BTCB2 Metal Miner

**M3B2 Metal** is an Apple-Silicon Metal kernel package for **BTCB2 / Bitcoin BLAKE2b** mining on the **Apple M3 Max**. Goal: minimize **joules per valid BLAKE2b hash**.

## Best validated M3 Max settings

- GPU: Apple M3 Max 30-core
- Kernel family: job-specialized, straight-line BLAKE2b-256
- Threadgroup: **64**
- Steps/thread: **128**
- Pipeline depth: **1**
- CPU: network/job coordination only
- Primary metric: incremental whole-package **J/GH**

The internally benchmarked **D3** kernel is the current champion at about **1.13 GH/s** and **~36.9 J/GH incremental package energy** in its best controlled full-duty comparison. Full history: [`BENCHMARKS.md`](BENCHMARKS.md).

> Low-duty telemetry remains unresolved: nominal 30% duty measured **16.83 J/GH** in one calibrated session and **42.03 J/GH** later. Neither is presented here as a settled global optimum.

## Build + run

Requires macOS + Xcode command-line tools.

```bash
git clone https://github.com/PeterJFrancoIII/apple-m3-max-blake2b-btcb2-metal-miner.git
cd apple-m3-max-blake2b-btcb2-metal-miner
sh scripts/build.sh && ./build/m3b2-bench ./build/m3b2.metallib
```

The public package contains:

- `kernel/m3b2_reference.metal` — portable BLAKE2b-256 80-byte mining kernel
- `src/m3b2_bench.mm` — minimal Metal host/benchmark runner
- `scripts/build.sh` — one-command build
- `BENCHMARKS.md` — findings, settings, wins and rejected variants

BTCB2/Sia-style work layout: **m0..m3 = prevhash, m4 = nonce, m5 = ntime, m6..m9 = work root, m10..m15 = zero**.

The benchmarked internal D3 artifact adds aggressive job specialization and straight-line constant folding. This repo deliberately does **not** label the portable reference kernel as the exact private D3 benchmark artifact.

## Compatibility

| Network / algorithm | Status |
|---|---|
| **BTCB2 / Bitcoin BLAKE2b** | **Direct target** |
| **BLAKE2b-256 + Sia-style 80-byte PoW headers** | Direct kernel family |
| **Siacoin (SC)** | Strong adaptation target; job/pool plumbing differs |
| **Handshake (HNS)** | Not drop-in: BLAKE2b + SHA3, different header |
| BLAKE3 / BLAKE-256 / SHA256d | Not compatible |

Sources: [Bitcoin BLAKE2b mining](https://bitcoin-blake2b.org/miners), [Bitcoin BLAKE2b developer notes](https://bitcoin-blake2b.org/developers), [Sia core](https://github.com/SiaFoundation/core), [Sia v2 mining compatibility](https://github.com/SiaFoundation/docs/blob/main/v2/README.md), [Handshake protocol summary](https://github.com/handshake-org/handshake-org.github.io/blob/master/src/protocol/summary.md).

## Findings

- GPU-only beats CPU+GPU efficiency on M3 Max.
- Job specialization beat the universal kernel.
- 2-way and 4-way ARX interleaving regressed J/GH.
- `tg=64`, `steps=128`, `depth=1` repeatedly won for this kernel family.
- **D3 straight-line specialization** remains the benchmark champion; D4 was statistical parity.

## Status

Optimization is still active. Next target: fixed-duty command-buffer/encoder coalescing around D3, then compiler-guided lower-live-range scheduling.

MIT licensed. Use at your own risk.
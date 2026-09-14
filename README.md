# Apple M3 Max BLAKE2b BTCB2 Metal Miner

**M3B2 Metal** is an Apple-Silicon Metal kernel package for **BTCB2 / Bitcoin BLAKE2b** mining on the **Apple M3 Max**. The project goal is simple: minimize **joules per valid BLAKE2b hash**.

## Best validated M3 Max settings

- GPU: Apple M3 Max 30-core
- Kernel family: job-specialized, straight-line BLAKE2b-256
- Threadgroup: **64 threads**
- Steps/thread: **128**
- Pipeline depth: **1**
- CPU: protocol/network only; no CPU mining
- Primary metric: incremental whole-package **J/GH**

The internally benchmarked **D3** kernel is the current champion at about **1.13 GH/s** and **~36.9 J/GH incremental package energy** in its best controlled full-duty comparison. See [`BENCHMARKS.md`](BENCHMARKS.md).

> Important: older and newer 30% duty telemetry disagreed sharply (**16.83 vs 42.03 J/GH**). That low-duty result is therefore **not** presented as a settled production claim.

## Quick start

```bash
xcrun -sdk macosx metal -c kernel/m3b2_reference.metal -o m3b2.air
xcrun -sdk macosx metallib m3b2.air -o m3b2.metallib
```

`kernel/m3b2_reference.metal` is a compact public BLAKE2b-256/Sia-style 80-byte work-header kernel intended for integration into a Metal mining host. It follows the verified BTCB2 work layout: **m0..m3 = prevhash, m4 = 64-bit nonce, m5 = ntime, m6..m9 = work root, m10..m15 = zero**.

The benchmarked internal D3 implementation additionally uses aggressive job specialization and straight-line constant folding. This repository does **not** mislabel the public reference kernel as the exact private benchmark artifact.

## Compatibility

| Network / algorithm | Status |
|---|---|
| **BTCB2 / Bitcoin BLAKE2b** | **Direct target; validated architecture** |
| **BLAKE2b-256, Sia-style 80-byte PoW headers** | Direct kernel family |
| **Siacoin (SC)** | Strong adaptation target; Sia uses BLAKE2b and preserves mining header compatibility across v2, but pool/job plumbing must be adapted |
| **Handshake (HNS)** | **Not drop-in**; Handshake PoW is BLAKE2b + SHA3 over a different header |
| BLAKE3, BLAKE-256, SHA256d | **Not compatible** |

Sources: [Bitcoin BLAKE2b mining](https://bitcoin-blake2b.org/miners), [Bitcoin BLAKE2b developer notes](https://bitcoin-blake2b.org/developers), [Sia core](https://github.com/SiaFoundation/core), [Sia v2 mining compatibility](https://github.com/SiaFoundation/docs/blob/main/v2/README.md), [Handshake protocol summary](https://github.com/handshake-org/handshake-org.github.io/blob/master/src/protocol/summary.md).

## Key findings

- GPU-only mining is substantially more efficient than CPU+GPU on M3 Max.
- Job specialization beat the universal kernel.
- 2-way and 4-way ARX interleaving **reduced** efficiency; lower-live-range serial scheduling won.
- `tg=64`, `steps=128`, `depth=1` was the best repeatedly observed launch geometry for this kernel family.
- D3 straight-line specialization is the current benchmark champion; D4 was statistical parity.

## Status

Kernel efficiency work remains active. The next high-value experiment is fixed-duty command-buffer / encoder coalescing around D3, followed by compiler-guided low-live-range schedule variants.

MIT licensed. Use at your own risk.
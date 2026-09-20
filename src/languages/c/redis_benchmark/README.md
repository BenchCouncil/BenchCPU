# Redis Benchmark

This workload builds and runs Redis locally as a CPU-oriented database benchmark.

## Source

The setup script downloads Redis 8.2.2 from the official Redis repository and builds it under this workload directory.

Relevant reference:

- Redis source repository: https://github.com/redis/redis
- Redis 8.2.2 source archive: https://github.com/redis/redis/archive/refs/tags/8.2.2.tar.gz

The local setup script builds Redis from source and installs these binaries into `bin/redis_install`:

- `redis-server`
- `redis-cli`
- `redis-benchmark`

The benchmark runner starts multiple local Redis server instances and drives them with `redis-benchmark` over Redis' RESP protocol on TCP loopback ports.

## License Notice

This workload currently uses Redis 8.2.2. Redis 8.2.2 is not licensed under the older BSD-3-Clause license used by Redis 7.2 and earlier.

The Redis 8.2.2 `LICENSE.txt` file states that Redis is available under a choice of:

- Redis Source Available License v2 (RSALv2)
- Server Side Public License v1 (SSPLv1)
- GNU Affero General Public License v3 (AGPLv3)

The same license file states that Redis Open Source 7.2 and prior releases remain subject to the BSDv3 clause license.

BenchCPU does not modify Redis source code in this workload. The BenchCPU setup and runner scripts download, build, launch, benchmark, and stop unmodified Redis binaries as an external benchmark dependency.

BenchCPU framework code for this workload may be licensed separately, such as under MIT. If a BenchCPU release redistributes Redis source code, build artifacts, or binaries, those Redis files remain under Redis' own license terms and should be listed separately in release metadata or third-party notices.

If a release needs to avoid Redis' newer source-available or copyleft-style license terms in redistributed artifacts, consider excluding Redis source and binaries from the release package, switching the workload to Valkey, or pinning it to Redis 7.2.x after validating benchmark compatibility.

## What the workload does

The benchmark launches multiple independent Redis server instances, then runs `redis-benchmark` clients against them with configurable request count, client count, data size, pipeline depth, and total logical thread budget. It is intended to stress Redis request processing and CPU throughput on a single machine.

## Execution

Build Redis locally from this directory:

```bash
./setup.sh --compiler gcc --opt -O2
```

Run the benchmark:

```bash
python3 run_benchmark.py --threads 8 --requests 3600000
```

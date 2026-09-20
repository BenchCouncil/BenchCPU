# CockroachDB KV Benchmark

This workload measures CockroachDB key-value transaction performance using its built-in `workload kv` command.

## Software Source and Version

The setup script downloads the official CockroachDB binary distribution:

- Upstream project: https://github.com/cockroachdb/cockroach
- Version: `v23.1.30`
- Binary archive for x86_64: https://binaries.cockroachdb.com/cockroach-v23.1.30.linux-amd64.tgz
- Binary archive for ARM64: https://binaries.cockroachdb.com/cockroach-v23.1.30.linux-arm64.tgz

The binary is installed as `bin/cockroach`. A user-provided executable can also be selected with the `COCKROACH_BIN` environment variable.

## Invocation

The local Go driver is [src/kv.go](src/kv.go). It invokes the unmodified CockroachDB executable with `exec.Command`.

The KV benchmark sequence is equivalent to:

```bash
./bin/cockroach start-single-node \
  --insecure \
  --listen-addr localhost:26257 \
  --http-addr localhost:8080 \
  --cache <cache-size> \
  --store <temporary-store> \
  --log-dir <temporary-log-dir>

./bin/cockroach node status \
  --insecure \
  --host=localhost \
  --port=26257

./bin/cockroach workload init kv \
  "postgres://root@localhost:26257?sslmode=disable"

./bin/cockroach workload run kv \
  --read-percent=50 \
  --min-block-bytes=128 \
  --max-block-bytes=128 \
  --concurrency=2000 \
  --ramp=10s \
  --scatter \
  --splits=5 \
  --seed=42 \
  --max-ops=<actual-max-ops> \
  "postgres://root@localhost:26257?sslmode=disable"
```

The read percentage can be `0`, `50`, or `95`. The driver sets `GOMAXPROCS` for the CockroachDB process and shuts down the process after the run.

## License Notice

BenchCPU does not modify CockroachDB source code. The setup script downloads and runs the official CockroachDB `v23.1.30` binary, while the local Go driver only manages the server process and invokes the built-in KV workload.

The downloaded binary package includes:

- `LICENSE` - CockroachDB Software License
- `THIRD-PARTY-NOTICES.txt` - notices for bundled third-party components

If a release does not include `bin/cockroach` or the downloaded CockroachDB package, the BenchCPU driver can be distributed under the BenchCPU project license, such as MIT, while CockroachDB remains an external runtime dependency. If the binary is redistributed, retain its `LICENSE` and `THIRD-PARTY-NOTICES.txt` files and comply with the CockroachDB Software License.

This workload should not be described as MIT-licensed CockroachDB code. The BenchCPU driver and CockroachDB binary are separate works with separate license terms.

## What the workload does

The benchmark starts a local single-node CockroachDB cluster, initializes the built-in KV dataset, and runs concurrent read/write transactions against the SQL endpoint. It is intended to stress transaction processing and CPU throughput on one machine.

## Execution

Install the CockroachDB binary:

```bash
./setup.sh
```

Run the KV workload:

```bash
go run ./src/kv.go --cockroachdb-bin ./bin/cockroach --kv 50 --threads 1 --max-ops 1000000
```

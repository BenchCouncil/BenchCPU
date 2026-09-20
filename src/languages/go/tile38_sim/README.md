# Tile38-Style KD-Tree Benchmark

This workload is a local spatial-query benchmark that simulates a Tile38-style point lookup scenario using a KD-tree. It is not a copy of the Tile38 server implementation.

## Source

The local benchmark harness is `src/main.go`. It generates a configurable set of points, builds a KD-tree, and performs nearest-neighbor and range-search queries.

The third-party KD-tree implementation is:

- Repository: https://github.com/kyroy/kdtree
- Pinned source revision: https://github.com/kyroy/kdtree/tree/70830f883f1d
- Go module: `github.com/kyroy/kdtree`
- Version: `v0.0.0-20200419114247-70830f883f1d`

The local `go.mod` and `vendor/modules.txt` pin this version. No Tile38 upstream source is used by the benchmark.

## License Notice

The vendored `github.com/kyroy/kdtree` library is distributed under the Apache License 2.0. Its license file is included at `vendor/github.com/kyroy/kdtree/LICENSE`.

If the vendored library or compiled artifacts containing it are redistributed, retain the Apache-2.0 license, copyright notices, and required notices. The local benchmark harness and its generated test data may be covered by the BenchCPU project license.

This benchmark uses the upstream KD-tree library through its public Go API and does not modify the upstream `kyroy/kdtree` implementation.

## What the workload does

The benchmark creates point data, builds a KD-tree, and executes KNN and range-search queries. It is intended to exercise spatial indexing, distance calculations, sorting, and concurrent Go query execution on a single machine.

## Execution

Run from this directory:

```bash
go run ./src/main.go --points 100000 --threads 1
```

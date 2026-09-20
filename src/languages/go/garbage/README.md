# gc_garbage Benchmark

This workload stresses the Go garbage collector by repeatedly parsing Go source files and discarding the resulting syntax trees.

## Source

The benchmark is adapted from the Go benchmarks repository's `garbage` benchmark:

- Direct source directory: https://github.com/golang/benchmarks/tree/master/garbage
- Original benchmark file: https://github.com/golang/benchmarks/blob/master/garbage/garbage.go
- Repository license: https://github.com/golang/benchmarks/blob/master/LICENSE

The upstream benchmark parses bundled `net/http` source code. The BenchCPU version keeps the same core idea but adds a generated-input workflow and configurable execution parameters:

- `generate_data.py` generates `data/input.go`.
- `garbage.go` accepts `--input`, `--iterations`, and `--threads`.
- `--threads` controls `GOMAXPROCS` for the benchmark process.

## License Notice

The upstream source header states:

```go
// Copyright 2014 The Go Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.
```

The Go benchmarks repository uses a BSD-style license, equivalent in its conditions to a BSD-3-Clause license. Retain the Go Authors copyright notice, license terms, and disclaimer when distributing code derived from this benchmark.

The BenchCPU-specific runner changes and generated input are separate local additions and may be covered by the BenchCPU project license. This workload does not modify the Go compiler or Go runtime source code; it uses the standard library `go/parser` package at runtime.

## What the workload does

The benchmark reads a large Go source file, repeatedly parses it with `go/parser.ParseFile`, retains a bounded set of parsed package pointers, and overwrites entries while concurrent goroutines create short-lived parse trees. This generates allocation and garbage-collection pressure.

## Execution

Generate input data:

```bash
python3 generate_data.py --size 100000 --output ./data/input.go
```

Run the benchmark:

```bash
go run garbage.go --input ./data/input.go --iterations 600 --threads 1
```

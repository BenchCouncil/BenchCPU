# biogo-igor Benchmark

This directory contains a benchmark that takes pairwise alignment data as produced by PALS or krishna, and reports repeat feature family groupings in JSON format. It is powered by the biogo bioinformatics library.

## Source

The benchmark is adapted from the `third_party/biogo-examples` copy in the Go benchmarks repository. That Go benchmarks copy contains modified examples from the original biogo examples repository.

Relevant sources:

- Direct source: https://github.com/golang/benchmarks/tree/master/third_party/biogo-examples
- Original example source: https://github.com/biogo/examples
- Local adapted example code: `biogo-examples/igor/igor`
- biogo library dependency: https://github.com/biogo/biogo

The local runner imports the adapted Igor example package and biogo library APIs:

```go
"biogo/biogo-examples/igor/igor"
"github.com/biogo/biogo/align/pals"
"github.com/biogo/biogo/io/featio/gff"
```

The local `go.mod` currently depends on:

```text
github.com/biogo/biogo v1.0.4
```

## License Notice

The adapted Igor example code retains the BSD-3-Clause license from the Go benchmarks `third_party/biogo-examples` copy and the original biogo examples project. The local license file is included at `biogo-examples/LICENSE`.

The license file states:

```text
Copyright (c) 2012 The biogo Authors. All rights reserved.
```

Redistribution of source or binary forms should retain the copyright notice, license conditions, and disclaimer from that license file.

BenchCPU may use a separate project-level license for its own framework code, such as MIT, while the adapted biogo example code and biogo library dependency remain under their own upstream license terms.

## What the workload does

The workload generates in-memory GFF-style pairwise alignment records, parses them through biogo's GFF reader, builds PALS piles, clusters repeat hits, groups repeat families, and serializes the result to JSON. The benchmark can run multiple replicas to exercise CPU-heavy bioinformatics clustering logic.

# biogo-krishna Benchmark

This directory also contains a benchmark which runs a Go implementation of PALS, powered by the biogo bioinformatics library.

# GopherLua KNucleotide Benchmark

This workload runs a Lua implementation of the KNucleotide benchmark inside the GopherLua virtual machine from Go.

## Source

The workload has two distinct upstream sources:

- Lua runtime and VM: https://github.com/yuin/gopher-lua
- KNucleotide benchmark algorithm: The Computer Language Benchmarks Game, https://benchmarksgame-team.pages.debian.net/benchmarksgame/

The Go wrapper imports GopherLua as:

```go
lua "github.com/yuin/gopher-lua"
```

The local `go.mod` pins:

```text
github.com/yuin/gopher-lua v1.1.1
```

The Lua script [src/knucleotide.lua](src/knucleotide.lua) identifies its algorithm as adapted from The Computer Language Benchmarks Game. Its original historical URL was `http://benchmarksgame.alioth.debian.org/`, which is no longer the current project URL.

This workload is not sourced from `golang/benchmarks`. The Go benchmark code and the integration wrapper are local BenchCPU code.

## License Notice

GopherLua is distributed under the MIT License. The vendored GopherLua license is included at `vendor/github.com/yuin/gopher-lua/LICENSE`.

The KNucleotide Lua script should retain the original attribution and license terms from The Computer Language Benchmarks Game source. The upstream terms for that script should be verified before redistributing it as a standalone work.

BenchCPU-specific Go integration, input generation, and execution changes may be covered by the BenchCPU project license. This workload uses GopherLua as an external/library dependency and does not modify the GopherLua implementation.

## What the workload does

The Go wrapper reads a DNA input file, creates one GopherLua state per worker, loads `knucleotide.lua`, and calls `run_knucleotide(seq)` repeatedly. The Lua code calculates k-mer frequencies and counts selected DNA fragments. Multiple Go goroutines can run independent Lua states concurrently.

## Execution

Build and run from this directory:

```bash
go build -o gopher_lua ./src
./gopher_lua --lua ./src/knucleotide.lua --data ./data/dna_input.fasta --threads 1 --iters 80
```

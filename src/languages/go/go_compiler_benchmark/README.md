# Go Compiler Benchmark

This workload measures Go compilation performance by generating synthetic Go packages and building them with the external Go toolchain.

## Source

The benchmark scripts and generated input sources are local BenchCPU code. `generate_data.py` creates Go packages, structs, functions, arithmetic expressions, `main.go`, and `go.mod` for each benchmark run. The generated sources are not copied from a third-party Go project or a specific upstream benchmark.

The compiler invoked by the benchmark is the system Go toolchain:

- Go project: https://github.com/golang/go
- Go documentation and download site: https://go.dev/
- Verified environment version: Go 1.24.5 on linux/amd64

## Compiler Invocation

The runner invokes the Go command through `subprocess.run` with a command equivalent to:

```bash
go build -a -o /dev/null ./...
```

The command builds all generated packages, discards the output binary, and measures the elapsed build time. Multiple independent build processes may run concurrently according to the benchmark's thread setting.

## License Notice

BenchCPU only invokes the external Go toolchain. It does not modify, patch, rebuild, or redistribute the Go compiler or Go runtime source code.

The local benchmark scripts and synthetic generated sources may be distributed under the BenchCPU project license, such as MIT. The Go toolchain remains an external dependency under its own license. `go.dev` is listed as the official Go project website; the Go source repository is `https://github.com/golang/go`.

## What the workload does

The data-generation step creates many Go packages and source files with structs, functions, and complex expressions. The runner repeatedly compiles all generated packages with `go build -a`, optionally using several parallel build processes, and measures total compilation time.

## Execution

Generate synthetic Go source:

```bash
python3 generate_data.py --out ./data/generated --pkgs 100 --files 5 --structs 8 --funcs 40 --complex 200
```

Run the compiler benchmark:

```bash
python3 run_benchmark.py --src ./data/generated --threads 1 --iters 1
```

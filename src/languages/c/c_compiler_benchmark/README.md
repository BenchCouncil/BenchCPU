# C Compiler Benchmark

This workload measures C compiler throughput by compiling generated C source files with GCC or Clang.

## Source

The benchmark itself is BenchCPU framework code. It generates synthetic C source files and invokes an external compiler executable to compile and link them.

Relevant local files:

- `generate_data.py` generates the input C source files under `data/src`.
- `run_benchmark.py` collects `.c` files from the source directory and compiles them with GCC or Clang.
- `metadata.yaml` defines the `gcc_compile` and `clang_compile` workloads.

## Compiler Invocation

For GCC, the runner selects the system `gcc` executable:

```python
compiler_bin = "/usr/bin/clang-14" if args.compiler == "clang" else "gcc"
```

It then runs a command equivalent to:

```bash
gcc -O3 -pthread ./data/src/*.c -o /tmp/tmpxxxx.out -lm
```

The actual command is built as a Python argument list rather than through shell wildcard expansion:

```python
cmd = [compiler_bin, f"-{args.opt}", "-pthread"] + src_files + ["-o", bin_file, "-lm"]
subprocess.run(cmd, check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
```

The `--compiler clang` path uses `/usr/bin/clang-14` in the same way.

## License Notice

This workload does not modify GCC or Clang source code. It does not download, build, patch, or redistribute GCC or Clang. It only invokes compiler executables that are already available in the runtime environment.

BenchCPU's benchmark scripts and generated synthetic input sources may be licensed under the BenchCPU project license, such as MIT. GCC and Clang remain external tools under their own licenses and should be documented as runtime/build dependencies, not as source code embedded in this workload.

If a release package ever includes compiler binaries or compiler source code, those files must be listed separately and distributed under their own license terms.

## What the workload does

The data generation step creates many synthetic C files containing computationally intensive functions. The benchmark runner repeatedly compiles all generated sources into temporary output binaries, optionally in multiple parallel threads, and measures total elapsed compilation time.

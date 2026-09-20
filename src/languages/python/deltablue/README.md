# DeltaBlue Benchmark

This workload is a Python implementation of the DeltaBlue incremental constraint solver benchmark.

## Source

The benchmark source file states that this implementation was directly ported from V8's historical JavaScript DeltaBlue benchmark, which was in turn derived from the Smalltalk implementation by John Maloney and Mario Wolczko.

The same Python benchmark lineage also appears in the Python `pyperformance` benchmark suite, where the DeltaBlue benchmark is described as having been ported for the PyPy project and contributed by Daniel Lindsley.

Relevant references:

- Python benchmark source: https://github.com/python/pyperformance/blob/main/pyperformance/data-files/benchmarks/bm_deltablue/run_benchmark.py
- Historical V8 source referenced by the file header: https://github.com/v8/v8/blob/master/benchmarks/deltablue.js

Note: the V8 `master` link referenced by the source header currently returns 404, so it should be treated as a historical reference. If possible, replace it with a stable archived permalink when preparing a formal release.

## License Notice

The source header states that the original JavaScript implementation was licensed under the GPL. Because this workload is a port of that implementation, this benchmark should be treated conservatively as GPL-derived code.

BenchCPU may use a separate project-level license for its own framework code, such as MIT, but that does not automatically relicense this workload. This DeltaBlue workload should retain its upstream attribution and GPL-derived license notice when distributed.

For release packaging, make sure this workload is listed separately from MIT-licensed project code in the repository README, release notes, or a third-party notices file.

## What the workload does

DeltaBlue exercises an incremental constraint solver. It builds chains and projection constraints, then repeatedly changes variables and executes constraint satisfaction plans. In this repository, the workload runs those solver operations across one or more worker processes for CPU benchmarking.

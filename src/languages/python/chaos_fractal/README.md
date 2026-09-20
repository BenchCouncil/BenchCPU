# Chaos Fractal Benchmark

This workload is a Python implementation of a chaos game style fractal generator using B-splines.

## Source

This workload matches the `bm_chaos` benchmark in the Python `pyperformance` benchmark suite. The local BenchCPU version has been split into separate data generation, core algorithm, and benchmark runner files, and it adds multiprocessing-oriented workload parameters.

Relevant reference:

- Python benchmark source: https://github.com/python/pyperformance/blob/main/pyperformance/data-files/benchmarks/bm_chaos/run_benchmark.py

The upstream `pyperformance` benchmark source is titled "create chaosgame-like fractals" and carries this attribution:

- Copyright (C) 2005 Carl Friedrich Bolz

## License Notice

The `pyperformance` project is distributed under the MIT License. Because this workload appears adapted from `pyperformance`'s `bm_chaos` benchmark, retain the upstream attribution and MIT license notice when distributing this benchmark.

BenchCPU may use a separate project-level license for its own framework code, such as MIT, while this workload should still document its upstream benchmark source and original attribution.

## What the workload does

The benchmark loads or generates spline definitions, initializes a chaos game environment, and repeatedly transforms points through B-spline based geometric operations. It is CPU-bound and exercises floating-point math, random selection, geometric interpolation, and iterative fractal generation.

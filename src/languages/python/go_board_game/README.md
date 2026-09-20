# Go Board Game Benchmark

This workload is a Python Go board game benchmark using random playout and UCT-style move selection logic.

## Source

This workload matches the `bm_go` benchmark in the Python `pyperformance` benchmark suite. The local BenchCPU version makes board size, game count, and worker process count configurable for benchmark runs.

Relevant reference:

- Python benchmark source: https://github.com/python/pyperformance/blob/main/pyperformance/data-files/benchmarks/bm_go/run_benchmark.py

## License Notice

The `pyperformance` project is distributed under the MIT License. Because this workload appears adapted from `pyperformance`'s `bm_go` benchmark, retain the upstream attribution and MIT license notice when distributing this benchmark.

BenchCPU may use a separate project-level license for its own framework code, such as MIT, while this workload should still document its upstream benchmark source.

## What the workload does

The benchmark simulates Go board play, including board state updates, connected-group tracking, captures, scoring, random legal move generation, and UCT-style playout selection. It is CPU-bound and exercises branch-heavy game logic and object-heavy Python execution.

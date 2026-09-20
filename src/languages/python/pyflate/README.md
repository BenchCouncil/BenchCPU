# Pyflate Benchmark

This workload is a pure-Python gzip/bzip2 decompression benchmark.

## Source

This workload matches the `bm_pyflate` benchmark in the Python `pyperformance` benchmark suite. The local BenchCPU version adapts the runner and adds data-generation and multiprocessing-oriented workload parameters.

Relevant reference:

- Python benchmark source: https://github.com/python/pyperformance/blob/main/pyperformance/data-files/benchmarks/bm_pyflate/run_benchmark.py

The upstream `pyperformance` benchmark source carries this attribution:

- Copyright 2006--2007-01-21 Paul Sladen
- Original project reference: http://www.paul.sladen.org/projects/compression/

## License Notice

The upstream source says it may be used and distributed under any DFSG-compatible license, for example BSD or GNU GPLv2. The `pyperformance` project is distributed under the MIT License.

For BenchCPU release metadata, list this workload separately from project framework code and retain the upstream attribution. A conservative release note can describe it as a `pyperformance` `bm_pyflate`-derived workload with the original Paul Sladen attribution and DFSG-compatible licensing notice.

## What the workload does

The benchmark decompresses gzip or bzip2 input using a pure-Python implementation of DEFLATE, Huffman decoding, BWT reversal, and related bitstream processing logic. It is CPU-bound and useful for stressing integer operations, branching, and byte-level decompression code.

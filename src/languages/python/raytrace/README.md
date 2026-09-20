# Raytrace Benchmark

This benchmark is a CPU-focused ray-tracing workload implemented in pure Python. It exercises geometric intersection, lighting, reflection, and recursive scene rendering logic in a synthetic 3D scene.

## Source

This workload matches the Raytrace benchmark in the Python `pyperformance` benchmark suite. The `pyperformance` version preserves the original source notice for the historical LShift toy raytracer.

Relevant references:

- Python benchmark source: https://github.com/python/pyperformance/blob/main/pyperformance/data-files/benchmarks/bm_raytrace/run_benchmark.py
- Original historical source: http://www.lshift.net/blog/2008/10/29/toy-raytracer-in-python

Note: the original LShift URL is no longer active, so it should be treated as a historical reference rather than a currently maintained upstream repository.

## License Notice

The original code is distributed under the MIT License. The local source header and the `pyperformance` source both preserve this MIT notice.

The file header states:

- Copyright Callum and Tony Garnock-Jones, 2008.
- "This file may be freely redistributed under the MIT license."

This benchmark retains the historical MIT attribution and is used here as a CPU workload example.

## What the workload does

- Builds a simple ray-traced scene with spheres and a checkerboard floor
- Casts rays through a virtual camera
- Computes intersections and shading
- Evaluates reflected light and simple Lambert/ambient shading
- Renders a high-resolution image in a CPU-bound loop

This makes it a good synthetic CPU benchmark for evaluating arithmetic throughput, branch-heavy scene traversal, and recursion-heavy render logic.

## Execution

Run the benchmark directly from this directory:

```bash
python3 run_benchmark.py --width 4096 --height 4096 --iters 1 --threads 1
```

You can vary the image size, number of iterations, and worker count to scale the workload.

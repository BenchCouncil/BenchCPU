# Go Markdown Render Benchmark

This workload measures Markdown parsing and HTML rendering performance in Go.

## Source

The benchmark uses the `golang-commonmark/markdown` Go library:

- Direct source repository: https://gitlab.com/golang-commonmark/markdown
- Go package: `gitlab.com/golang-commonmark/markdown`
- Pinned version: `v0.0.0-20211110145824-bf3e522c626a`
- Package documentation: https://pkg.go.dev/gitlab.com/golang-commonmark/markdown

The local benchmark wrapper is [main.go](main.go). It imports the library and configures Markdown options including XHTML output, tables, maximum nesting, typographer processing, and linkification. The local [generate_data.py](generate_data.py) script generates Markdown input files for the benchmark.

This workload is not sourced from `github.com/golang/benchmarks`; the direct dependency is the GitLab `golang-commonmark/markdown` project.

## License Notice

The vendored `golang-commonmark/markdown` package is marked as BSD-2-Clause. Its license file is included at `vendor/gitlab.com/golang-commonmark/markdown/LICENSE`.

If the vendored library or compiled artifacts containing it are redistributed, retain the upstream copyright notice, BSD-2-Clause conditions, and disclaimer. BenchCPU's local benchmark wrapper and generated Markdown input may be covered by the BenchCPU project license.

## What the workload does

The generator creates a collection of Markdown documents. The Go runner loads the documents, creates a Markdown renderer, and repeatedly renders the input to HTML using the configured parser and renderer options. Multiple goroutines may process the same input collection concurrently.

## Execution

Generate Markdown input:

```bash
python3 generate_data.py --size 1000 --output ./data/markdown
```

Build and run the benchmark:

```bash
go build -o markdown-benchmark .
./markdown-benchmark --dir ./data/markdown --threads 1 --iterations 1
```

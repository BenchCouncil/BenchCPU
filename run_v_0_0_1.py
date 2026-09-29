#!/usr/bin/env python3
from __future__ import annotations
import argparse
import subprocess
import sys
from datetime import datetime
from pathlib import Path
import json
import re
import shutil

ROOT = Path(__file__).resolve().parent              
PROJECT_ROOT = ROOT                         
RUN_CPU = PROJECT_ROOT / "scripts" / "run_cpu.py"
LOG_DIR = PROJECT_ROOT / "log"
RES_DIR = PROJECT_ROOT / "res"
SYSTEM_INFO_FILE = RES_DIR / "system_info.json"

LOG_DIR.mkdir(parents=True, exist_ok=True)
RES_DIR.mkdir(parents=True, exist_ok=True)

workloads_sets = {
    "python": [
        "numpy_benchmark.matmul", 
        "numpy_benchmark.svd",
        "numpy_benchmark.fft", 
        "tuf_benchmark.tuf-metadata", 
        "requests_benchmark.requests-json", 
        "raytrace.raytrace",
        "chaos_fractal.chaos-fractal", 
        "deltablue.deltablue",
        "pyflate.pyflate", 
        "go_board_game.go-board-game",
        "resnet50_cpu.resnet50_inference", 
        "resnet50_cpu.resnet50_training",
        "bert_cpu.bert_eval", 
        "transformer_inference.transformer_inference",
        "transformer_train.transformer_train",
    ],
    "c": [
        "redis_benchmark.redis-benchmark", 
        "ffmpeg_benchmark.ffmpeg",
        "openssl_benchmark.openssl", 
        "zstd_benchmark.zstd",
        "c_compiler_benchmark.gcc_compile", 
        "c_compiler_benchmark.clang_compile", 
        "lapack_benchmark.lapack_solve",
        "lapack_benchmark.lapack_eigen", 
        "lapack_benchmark.lapack_svd",
    ],
    "cpp" : [
        "rocksdb_benchmark.rocksdb_cpu", 
        "opencv_benchmark.fft_batch",
        "opencv_benchmark.conv_heavy", 
        "opencv_benchmark.motion_blur",
        "opencv_benchmark.background_sub",
        "opencv_benchmark.mandelbrot",
        "opencv_benchmark.jacobi",
        "opencv_benchmark.canny",
        "opencv_benchmark.optical_flow",
        "opencv_benchmark.color_tracking",
        "opencv_benchmark.feature_match",
    ],
    "go" : [
        "biogo-benchmark.biogo-igor", 
        "bleve_benchmark.bleve-index",
        "cockroachdb_benchmark.kv", 
        "cockroachdb_benchmark.tpcc",
        "esbuild_benchmark.ThreeJS",
        "esbuild_benchmark.RomeTS",
        "gc_garbage.gc_garbage",
        "go_compiler.go_compiler",
        "gopher_lua.gopher_lua",
        "go_json.json",
        "go_markdown.markdown_render",
        "tile38_sim.kdtree",
    ],
    "java": [
        "cassandra_benchmark.cassandra_stress_read",
        "kafka_benchmark.kafka_producer_perf",
        "guava_benchmark.guava_event",
        "guava_benchmark.guava_cache",
        "guava_benchmark.guava_graph",
        "guava_benchmark.guava_bloom",
        "guava_benchmark.guava_immutable",
        "smile_benchmark.smile_kmeans",
    ],
    "basic": [
        "numpy_benchmark.matmul", 
        "numpy_benchmark.svd",
        "numpy_benchmark.fft", 
        "tuf_benchmark.tuf-metadata", 
        "requests_benchmark.requests-json", 
        "raytrace.raytrace",
        "chaos_fractal.chaos-fractal", 
        "deltablue.deltablue",
        "pyflate.pyflate", 
        "go_board_game.go-board-game",
        "resnet50_cpu.resnet50_inference", 
        "resnet50_cpu.resnet50_training",
        "bert_cpu.bert_eval", 
        "transformer_inference.transformer_inference",
        "redis_benchmark.redis-benchmark", 
        "openssl_benchmark.openssl", 
        "zstd_benchmark.zstd",
        "c_compiler_benchmark.gcc_compile", 
        "c_compiler_benchmark.clang_compile", 
        "lapack_benchmark.lapack_solve",
        "lapack_benchmark.lapack_eigen", 
        "lapack_benchmark.lapack_svd",
        "opencv_benchmark.fft_batch",
        "opencv_benchmark.conv_heavy", 
        "opencv_benchmark.motion_blur",
        "opencv_benchmark.background_sub",
        "opencv_benchmark.mandelbrot",
        "opencv_benchmark.jacobi",
        "opencv_benchmark.canny",
        "opencv_benchmark.optical_flow",
        "opencv_benchmark.color_tracking",
        "opencv_benchmark.feature_match",
        "biogo-benchmark.biogo-igor", 
        "bleve_benchmark.bleve-index",
        "cockroachdb_benchmark.kv", 
        "esbuild_benchmark.ThreeJS",
        "esbuild_benchmark.RomeTS",
        "gc_garbage.gc_garbage",
        "go_compiler.go_compiler",
        "gopher_lua.gopher_lua",
        "go_json.json",
        "go_markdown.markdown_render",
        "tile38_sim.kdtree",
        "cassandra_benchmark.cassandra_stress_read",
        "guava_benchmark.guava_event",
        "guava_benchmark.guava_cache",
        "guava_benchmark.guava_graph",
        "guava_benchmark.guava_bloom",
        "guava_benchmark.guava_immutable",
        "smile_benchmark.smile_kmeans",
    ],
    "emerging":[
        "transformer_train.transformer_train",
        "ffmpeg_benchmark.ffmpeg",
        "rocksdb_benchmark.rocksdb_cpu", 
        "cockroachdb_benchmark.tpcc",
        "kafka_benchmark.kafka_producer_perf",
    ],
    "all": [
        "numpy_benchmark.matmul", 
        "numpy_benchmark.svd",
        "numpy_benchmark.fft", 
        "tuf_benchmark.tuf-metadata", 
        "requests_benchmark.requests-json", 
        "raytrace.raytrace",
        "chaos_fractal.chaos-fractal", 
        "deltablue.deltablue",
        "pyflate.pyflate", 
        "go_board_game.go-board-game",
        "resnet50_cpu.resnet50_inference", 
        "resnet50_cpu.resnet50_training",
        "bert_cpu.bert_eval", 
        "transformer_inference.transformer_inference",
        "transformer_train.transformer_train",
        "redis_benchmark.redis-benchmark", 
        "ffmpeg_benchmark.ffmpeg",
        "openssl_benchmark.openssl", 
        "zstd_benchmark.zstd",
        "c_compiler_benchmark.gcc_compile", 
        "c_compiler_benchmark.clang_compile", 
        "lapack_benchmark.lapack_solve",
        "lapack_benchmark.lapack_eigen", 
        "lapack_benchmark.lapack_svd",
        "rocksdb_benchmark.rocksdb_cpu", 
        "opencv_benchmark.fft_batch",
        "opencv_benchmark.conv_heavy", 
        "opencv_benchmark.motion_blur",
        "opencv_benchmark.background_sub",
        "opencv_benchmark.mandelbrot",
        "opencv_benchmark.jacobi",
        "opencv_benchmark.canny",
        "opencv_benchmark.optical_flow",
        "opencv_benchmark.color_tracking",
        "opencv_benchmark.feature_match",
        "biogo-benchmark.biogo-igor", 
        "bleve_benchmark.bleve-index",
        "cockroachdb_benchmark.kv", 
        "cockroachdb_benchmark.tpcc",
        "esbuild_benchmark.ThreeJS",
        "esbuild_benchmark.RomeTS",
        "gc_garbage.gc_garbage",
        "go_compiler.go_compiler",
        "gopher_lua.gopher_lua",
        "go_json.json",
        "go_markdown.markdown_render",
        "tile38_sim.kdtree",
        "cassandra_benchmark.cassandra_stress_read",
        "kafka_benchmark.kafka_producer_perf",
        "guava_benchmark.guava_event",
        "guava_benchmark.guava_cache",
        "guava_benchmark.guava_graph",
        "guava_benchmark.guava_bloom",
        "guava_benchmark.guava_immutable",
        "smile_benchmark.smile_kmeans",
    ]
}

# 2
data_augmentation_params = [
    "numpy_benchmark.matmul.workload.size=4096",
    "numpy_benchmark.svd.workload.size=1126",
    "numpy_benchmark.fft.workload.size=4194304",
    "tuf_benchmark.tuf-metadata.data.size=375809638",
    "requests_benchmark.requests-json.workload.size=170394",
    "raytrace.raytrace.workload.width=2662",
    "raytrace.raytrace.workload.height=2458",
    "chaos_fractal.chaos-fractal.data.width=2253",
    "chaos_fractal.chaos-fractal.data.height=4096",
    "deltablue.deltablue.workload.n=180000",
    "pyflate.pyflate.data.size=5500000",
    "go_board_game.go-board-game.workload.size=190",
    "resnet50_cpu.resnet50_inference.data.batch_size=3",
    "resnet50_cpu.resnet50_training.data.batch_size=2",
    "bert_cpu.bert_eval.data.batch_size=4",
    "transformer_inference.transformer_inference.data.batch_size=4",
    "transformer_train.transformer_train.data.batch_size=3",
    "c_compiler_benchmark.gcc_compile.data.func_size=130",
    "c_compiler_benchmark.clang_compile.data.func_size=180",
    "ffmpeg_benchmark.ffmpeg.data.duration=456",
    "lapack_benchmark.lapack_solve.workload.size=1024",
    "lapack_benchmark.lapack_eigen.workload.size=1843",
    "lapack_benchmark.lapack_svd.workload.size=1331",
    "openssl_benchmark.openssl.data.size=50",
    "redis_benchmark.redis-benchmark.workload.requests=3600000",
    "zstd_benchmark.zstd.data.size=40",
    "rocksdb_benchmark.rocksdb_cpu.workload.num=2600000",
    "opencv_benchmark.background_sub.workload.size=918",
    "opencv_benchmark.mandelbrot.workload.size=973",
    "opencv_benchmark.jacobi.workload.size=1434",
    "opencv_benchmark.canny.workload.size=1024",
    "opencv_benchmark.optical_flow.workload.size=614",
    "opencv_benchmark.color_tracking.workload.size=1728",
    "opencv_benchmark.feature_match.workload.size=768",
    "opencv_benchmark.fft_batch.workload.size=717",
    "opencv_benchmark.conv_heavy.workload.size=614",
    "opencv_benchmark.motion_blur.workload.size=1331",
    "biogo-benchmark.biogo-igor.workload.seq=75000",
    "bleve_benchmark.bleve-index.workload.documents=2200",
    "cockroachdb_benchmark.kv.workload.max-ops=660000",
    "cockroachdb_benchmark.tpcc.workload.max-ops=24000",
    "esbuild_benchmark.ThreeJS.data.complexity=1100",
    "esbuild_benchmark.RomeTS.data.complexity=1500",
    "gc_garbage.gc_garbage.data.size=75000",
    "go_compiler.go_compiler.data.complex=190",
    "gopher_lua.gopher_lua.data.size=700000",
    "go_json.json.data.size=25",
    "go_markdown.markdown_render.data.size=850",
    "tile38_sim.kdtree.workload.points=90000",
    "cassandra_benchmark.cassandra_stress_read.workload.write-n=1100000",
    "cassandra_benchmark.cassandra_stress_read.workload.read-n=1600000",
    "kafka_benchmark.kafka_producer_perf.workload.num-records=770000000",
    "guava_benchmark.guava_event.workload.dataSize=180000",
    "guava_benchmark.guava_cache.workload.dataSize=70000",
    "guava_benchmark.guava_graph.workload.dataSize=400000",
    "guava_benchmark.guava_bloom.workload.dataSize=380000",
    "guava_benchmark.guava_immutable.workload.dataSize=300000",
    "smile_benchmark.smile_kmeans.data.samples=95000",
    "smile_benchmark.smile_kmeans.data.features=65",
]

# 3
compiler_env_params = [
    "ffmpeg_benchmark._.setup.compiler=clang",
    "lapack_benchmark._.setup.compiler=clang",
    "openssl_benchmark._.setup.compiler=clang",
    "rocksdb_benchmark._.setup.compiler=clang",
    "opencv_benchmark._.setup.compiler=clang",
]

# 4
opt_env_params = [
    "ffmpeg_benchmark._.setup.opt=-O1",
    "lapack_benchmark._.setup.opt=-O2",
    "openssl_benchmark._.setup.opt=-O2",
    "redis_benchmark._.setup.opt=-O2",
    "zstd_benchmark._.setup.opt=-O3",
    "c_compiler_benchmark.gcc_compile.workload.opt=O2",
    "c_compiler_benchmark.clang_compile.workload.opt=O1",
    "rocksdb_benchmark._.setup.opt=-O2",
    "opencv_benchmark._.setup.opt=-O2",
]

# 5
threads_param = [
    "numpy_benchmark.matmul.workload.threads=8",
    "numpy_benchmark.svd.workload.threads=40",
    "numpy_benchmark.fft.workload.threads=10",
    "tuf_benchmark.tuf-metadata.workload.threads=50",
    "requests_benchmark.requests-json.workload.threads=64",
    "raytrace.raytrace.workload.threads=40",
    "chaos_fractal.chaos-fractal.workload.threads=40",
    "deltablue.deltablue.workload.threads=2",
    "pyflate.pyflate.workload.threads=32",
    "go_board_game.go-board-game.workload.threads=40",
    "resnet50_cpu.resnet50_inference.workload.threads=4",
    "resnet50_cpu.resnet50_training.workload.threads=30",
    "bert_cpu.bert_eval.workload.threads=50",
    "transformer_inference.transformer_inference.workload.threads=8",
    "transformer_train.transformer_train.workload.threads=4",
    "c_compiler_benchmark.gcc_compile.workload.threads=28",
    "c_compiler_benchmark.clang_compile.workload.threads=20",
    "ffmpeg_benchmark.ffmpeg.workload.threads=10",
    "lapack_benchmark.lapack_solve.workload.threads=64",
    "lapack_benchmark.lapack_eigen.workload.threads=40",
    "lapack_benchmark.lapack_svd.workload.threads=50",
    "openssl_benchmark.openssl.workload.threads=30",
    "redis_benchmark.redis-benchmark.workload.threads=8",
    "zstd_benchmark.zstd.workload.threads=40",
    "rocksdb_benchmark.rocksdb_cpu.workload.threads=16",
    "opencv_benchmark.background_sub.workload.threads=60",
    "opencv_benchmark.mandelbrot.workload.threads=56",
    "opencv_benchmark.jacobi.workload.threads=56",
    "opencv_benchmark.canny.workload.threads=1",
    "opencv_benchmark.optical_flow.workload.threads=8",
    "opencv_benchmark.color_tracking.workload.threads=60",
    "opencv_benchmark.feature_match.workload.threads=1",
    "opencv_benchmark.fft_batch.workload.threads=56",
    "opencv_benchmark.conv_heavy.workload.threads=16",
    "opencv_benchmark.motion_blur.workload.threads=20",
    "biogo-benchmark.biogo-igor.workload.threads=10",
    "bleve_benchmark.bleve-index.workload.threads=2",
    "cockroachdb_benchmark.kv.workload.threads=8",
    "cockroachdb_benchmark.tpcc.workload.threads=64",
    "esbuild_benchmark.ThreeJS.workload.threads=32",
    "esbuild_benchmark.RomeTS.workload.threads=64",
    "gc_garbage.gc_garbage.workload.threads=50",
    "go_compiler.go_compiler.workload.threads=16",
    "gopher_lua.gopher_lua.workload.threads=8",
    "go_json.json.workload.threads=40",
    "go_markdown.markdown_render.workload.threads=28",
    "tile38_sim.kdtree.workload.threads=20",
    "cassandra_benchmark.cassandra_stress_read.workload.threads=64",
    "kafka_benchmark.kafka_producer_perf.workload.threads=64",
    "guava_benchmark.guava_event.workload.threads=40",
    "guava_benchmark.guava_cache.workload.threads=28",
    "guava_benchmark.guava_graph.workload.threads=4",
    "guava_benchmark.guava_bloom.workload.threads=10",
    "guava_benchmark.guava_immutable.workload.threads=4",
    "smile_benchmark.smile_kmeans.workload.threads=8",
]

param_sets = {
    "v0.0.1": data_augmentation_params + compiler_env_params + opt_env_params + threads_param,
}

pairs = [
    ("all",        "v0.0.1",    True),
]


def parse_args():
    parser = argparse.ArgumentParser(
        description="Run benchmark presets or execute a JSON config replay."
    )
    parser.add_argument(
        "--config",
        help=(
            "Path to JSON config file with fields: tag, setup_env, workloads, params. "
            "Example: test/momentum_filter_config/round6.json"
        ),
    )
    parser.add_argument(
        "--tag",
        help="Override tag from config JSON (or default preset tag).",
    )
    return parser.parse_args()


def load_config(config_path: str):
    path = Path(config_path)
    if not path.is_absolute():
        path = PROJECT_ROOT / path
    path = path.resolve()

    if not path.exists():
        raise FileNotFoundError(f"Config file not found: {path}")

    with open(path, "r", encoding="utf-8") as f:
        cfg = json.load(f)

    workloads = cfg.get("workloads", [])
    params = cfg.get("params", [])
    setup_env = bool(cfg.get("setup_env", False))
    tag = cfg.get("tag", "config_run")

    if not isinstance(workloads, list) or not all(isinstance(x, str) for x in workloads):
        raise ValueError("Config 'workloads' must be a list of strings")
    if not isinstance(params, list) or not all(isinstance(x, str) for x in params):
        raise ValueError("Config 'params' must be a list of strings")

    return path, tag, setup_env, workloads, params



def run_cmd(cmd):
    """Run a command and return its output as list of lines."""
    try:
        out = subprocess.check_output(cmd, shell=True, text=True)
        return out.strip().split("\n")
    except Exception:
        return []

def parse_key_value_lines(lines):
    """Parse lines like 'Key: Value' into dict."""
    data = {}
    for ln in lines:
        if ":" in ln:
            k, v = ln.split(":", 1)
            data[k.strip()] = v.strip()
    return data

def collect_memory_hardware():
    devices = []
    current = None
    for line in run_cmd("dmidecode -t memory"):
        stripped = line.strip()
        if stripped == "Memory Device":
            if current and current.get("Size") != "No Module Installed":
                devices.append(current)
            current = {}
        elif current is not None and ":" in stripped:
            key, value = stripped.split(":", 1)
            current[key.strip()] = value.strip()
    if current and current.get("Size") != "No Module Installed":
        devices.append(current)

    configured_speed = None
    if devices:
        for key in ("Configured Memory Speed", "Speed"):
            match = re.search(r"(\d+)\s*MT/s", devices[0].get(key, ""))
            if match:
                configured_speed = int(match.group(1))
                break

    return {
        "installed_dimm_count": len(devices),
        "devices": devices,
        "configured_speed_mt_s": configured_speed,
        "theoretical_bandwidth_gb_s_per_64bit_channel": (
            configured_speed * 8 / 1000 if configured_speed else None
        ),
    }

def parse_os_release(lines):
    values = {}
    for line in lines:
        if "=" not in line:
            continue
        key, value = line.split("=", 1)
        values[key.strip()] = value.strip().strip('"')
    return values

def collect_system_info():
    sysinfo = {}

    lscpu_lines = run_cmd("lscpu")
    sysinfo["cpu"] = parse_key_value_lines(lscpu_lines)

    meminfo_lines = run_cmd("cat /proc/meminfo")
    sysinfo["memory"] = parse_key_value_lines(meminfo_lines)
    sysinfo["memory_hardware"] = collect_memory_hardware()

    osrelease_lines = run_cmd("cat /etc/os-release")
    sysinfo["os"] = parse_os_release(osrelease_lines)

    sysinfo["uname"] = run_cmd("uname -a")

    sysinfo["software"] = {
        "gcc_version": run_cmd("gcc --version"),
        "clang_version": run_cmd("clang --version"),
        "python_version": run_cmd("python3 --version"),
        "java_version": run_cmd("java --version"),
        "go_version": run_cmd("go version"),
    }

    # if shutil.which("dmidecode"):
    #     cpu_detail = run_cmd("sudo dmidecode -t processor")
    #     mem_detail = run_cmd("sudo dmidecode -t memory")
    #     sysinfo["dmidecode"] = {
    #         "processor": cpu_detail,
    #         "memory": mem_detail
    #     }

    return sysinfo


def write_unique_snapshot(output_dir: Path, capture_fn, file_prefix: str = "system_info") -> Path | None:
    """Collect a snapshot and write a timestamped JSON only when the data changed."""
    current = capture_fn()

    output_dir = Path(output_dir)
    output_dir.mkdir(parents=True, exist_ok=True)

    for candidate in sorted(output_dir.glob(f"{file_prefix}_*.json")):
        try:
            with candidate.open("r", encoding="utf-8") as fh:
                previous = json.load(fh)
        except (json.JSONDecodeError, OSError):
            continue

        if previous == current:
            return None

    timestamp = datetime.now().strftime("%Y-%m-%d_%H-%M-%S")
    target = output_dir / f"{file_prefix}_{timestamp}.json"

    counter = 1
    while target.exists():
        target = output_dir / f"{file_prefix}_{timestamp}_{counter}.json"
        counter += 1

    with target.open("w", encoding="utf-8") as f:
        json.dump(current, f, indent=2, sort_keys=True)
        f.write("\n")

    return target


def save_system_info_json(path):
    """Backward-compatible wrapper that keeps a unique timestamped system snapshot."""
    path = Path(path)
    return write_unique_snapshot(path.parent, collect_system_info, file_prefix=path.stem)


def write_system_info_json(output_path):
    """Write collected system info to a new timestamped JSON when it differs."""
    output_path = Path(output_path)
    return write_unique_snapshot(output_path.parent, collect_system_info, file_prefix=output_path.stem)


def run_workloads_set(tag: str, workloads: list[str], params: list[str], setup_env: bool = False):
    timestamp = datetime.now().strftime("%Y-%m-%d_%H-%M-%S")
    result_file = RES_DIR / f"results_{tag}_{timestamp}.csv"
    log_file = LOG_DIR / f"logs_{tag}_{timestamp}.log"

    base_cmd = [
        sys.executable,
        str(RUN_CPU),
        "--verbose",
        "--out", str(result_file),
        "--log", str(log_file),
        # "--use-perf"
    ]

    if setup_env:
        base_cmd.append("--setup-env")

    if workloads:
        base_cmd.extend(["--workloads"] + workloads)

    for p in params:
        base_cmd.extend(["--set-param", p])


    print(f"\n=== Running config: {tag} ===")
    print("Command:", " ".join(base_cmd))
    print(f"Working directory: {PROJECT_ROOT}")

    try:
        subprocess.run(base_cmd, check=True, cwd=PROJECT_ROOT)
        print(f"[OK] {tag} finished successfully.")
        print(f"    Result: {result_file}")
        print(f"    Log:    {log_file}")
    except subprocess.CalledProcessError as e:
        print(f"[ERROR] {tag} failed with code {e.returncode}")
        print(f"    Check log: {log_file}")


def main():
    args = parse_args()

    print(f"[INFO] Starting test batch from {PROJECT_ROOT}")
    print(f"[INFO] Logs → {LOG_DIR}")
    print(f"[INFO] Results → {RES_DIR}")
    print(f"[INFO] System info → {SYSTEM_INFO_FILE}")

    write_system_info_json(SYSTEM_INFO_FILE)

    if args.config:
        config_path, cfg_tag, setup_env, workloads, params = load_config(args.config)
        tag = args.tag if args.tag else cfg_tag

        print(f"[INFO] Running config mode: {config_path}")
        print(f"[INFO] Tag: {tag}")
        print(f"[INFO] Workloads: {len(workloads)}")
        print(f"[INFO] Params: {len(params)}")

        run_workloads_set(tag, workloads, params, setup_env)
        print("\n[INFO] Config replay finished.")
        return

    for workloads_set_name, param_set_name, setup_env in pairs:
        workloads = workloads_sets[workloads_set_name]
        params = param_sets[param_set_name]
        tag = args.tag if args.tag else f"{param_set_name}"
        run_workloads_set(tag, workloads, params, setup_env)

    print("\n[INFO] All tests finished.")


if __name__ == "__main__":
    main()

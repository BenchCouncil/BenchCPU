#!/bin/bash
# ============================================================
# BBV + 19 PMC — Remote Server Deployment Script
# 用法: bash bbv_remote.sh /path/to/benchcpu
# ============================================================
set -euo pipefail

BENCHCPU="${1:-$(pwd)}"
if [ ! -d "$BENCHCPU" ]; then
    echo "Usage: bash bbv_remote.sh /path/to/cpu_bench"
    exit 1
fi

TIMESTAMP=$(date +%Y%m%d_%H%M%S)
WORK_DIR="${BENCHCPU}/results/bbv_remote_${TIMESTAMP}"
mkdir -p "$WORK_DIR"
LOG="${WORK_DIR}/run.log"
exec > >(tee -a "$LOG") 2>&1

echo "============================================"
echo "  BBV + 19 PMC — Remote Run"
echo "  Host:     $(hostname)"
echo "  CPU:      $(cat /proc/cpuinfo | grep 'model name' | head -1 | cut -d: -f2-)"
echo "  Cores:    $(nproc)"
echo "  Started:  $(date)"
echo "  BenchCPU: $BENCHCPU"
echo "  Work dir: $WORK_DIR"
echo "============================================"

# ── 0. Auto-install dependencies ──────────────────────
echo ""
echo "[0/6] Installing dependencies..."

MISSING=""
for cmd in valgrind g++ python3; do
    command -v $cmd &>/dev/null || MISSING="$MISSING $cmd"
done
# Go is optional (only for gc_garbage)
command -v go &>/dev/null || echo "  [WARN] go not found — gc_garbage will be skipped"

if [ -n "$MISSING" ]; then
    echo "  Installing: $MISSING"
    if command -v apt-get &>/dev/null; then
        apt-get update -qq && apt-get install -y -qq $MISSING 2>&1 | tail -3
    elif command -v yum &>/dev/null; then
        yum install -y $MISSING 2>&1 | tail -3
    else
        echo "  [ERROR] Cannot auto-install. Please install: $MISSING"
    fi
fi

VALGRIND=$(command -v valgrind 2>/dev/null || echo "valgrind")
echo "  valgrind: $($VALGRIND --version 2>&1 | head -1 || echo 'NOT FOUND')"

# ── PMU event auto-detection ──────────────────────────
echo ""
echo "[*] Auto-detecting PMU events for this CPU..."

CPU_VENDOR=$(grep -m1 vendor_id /proc/cpuinfo | awk '{print $3}')
echo "  Vendor: $CPU_VENDOR"

# Test which events are available
test_event() { perf list "$1" 2>/dev/null | head -1 | grep -q "$1" && echo "1" || echo "0"; }

EVT_L2_MISS="l2_rqsts.all_demand_miss"
EVT_TOPDOWN="topdown-total-slots,topdown-fetch-bubbles,topdown-slots-retired,topdown-recovery-bubbles,topdown-slots-issued"
EVT_FP_128="fp_arith_inst_retired.128b_packed_double"
EVT_FP_256="fp_arith_inst_retired.256b_packed_double"
EVT_STLB="frontend_retired.stlb_miss"
EVT_DTLB_WALK="dtlb_load_misses.miss_causes_a_walk"

# Check Intel-specific events
HAS_L2=$(test_event "l2_rqsts.all_demand_miss")
HAS_TOPDOWN=$(test_event "topdown-total-slots")
HAS_FP_128=$(test_event "fp_arith_inst_retired.128b_packed_double")
HAS_FP_256=$(test_event "fp_arith_inst_retired.256b_packed_double")
HAS_STLB=$(test_event "frontend_retired.stlb_miss")
HAS_DTLB_WALK=$(test_event "dtlb_load_misses.miss_causes_a_walk")

# Fallback to generic events
if [ "$HAS_L2" = "0" ]; then
    EVT_L2_MISS="cache-misses"
    echo "  [WARN] l2_rqsts not available, using cache-misses as L2 proxy"
fi

if [ "$HAS_STLB" = "0" ]; then
    EVT_STLB="dTLB-load-misses"
    EVT_DTLB_WALK="dTLB-store-misses"
fi

# Build perf event groups with fallbacks
PERF_G1="instructions,cpu-cycles,branch-instructions,branch-misses,\
L1-icache-load-misses,L1-dcache-load-misses,${EVT_L2_MISS}"

PERF_G2="instructions,cpu-cycles,LLC-load-misses,\
iTLB-load-misses,dTLB-load-misses,\
mem_inst_retired.all_loads,mem_inst_retired.all_stores"

if [ "$HAS_TOPDOWN" = "1" ]; then
    PERF_G3="instructions,cpu-cycles,${EVT_TOPDOWN}"
else
    PERF_G3="instructions,cpu-cycles,cache-misses,LLC-load-misses,\
branch-misses,L1-dcache-load-misses"
    echo "  [WARN] Top-down events not available, using fallback"
fi

PERF_G4="instructions,cpu-cycles,\
fp_arith_inst_retired.scalar_double,fp_arith_inst_retired.scalar_single"

if [ "$HAS_FP_128" = "1" ]; then
    PERF_G4="${PERF_G4},fp_arith_inst_retired.128b_packed_double"
fi
if [ "$HAS_FP_256" = "1" ]; then
    PERF_G4="${PERF_G4},fp_arith_inst_retired.256b_packed_double"
fi
PERF_G4="${PERF_G4},${EVT_STLB},${EVT_DTLB_WALK}"

echo "  PMU events configured for $CPU_VENDOR"

# ── Benchmark config ──────────────────────────────────
echo ""
echo "[*] Benchmark configuration — threads=1, matching benchcpu momentum search"

declare -A BM_DIR BM_DATA_CMD BM_RUN_CMD BM_BBV_ITERS BM_PERF_ITERS BM_LABEL
BENCHMARKS=("openssl" "opencv_fft" "gc_garbage")

# openssl
BM_DIR["openssl"]="${BENCHCPU}/src/languages/c/openssl_benchmark"
BM_DATA_CMD["openssl"]="cd ${BM_DIR[openssl]} && python3 generate_data.py --size 30555 --output ./data/data.bin"
BM_RUN_CMD["openssl"]="${BM_DIR[openssl]}/bin/openssl_benchmark --input ${BM_DIR[openssl]}/data/data.bin --threads 1"
BM_BBV_ITERS["openssl"]=300
BM_PERF_ITERS["openssl"]=300
BM_LABEL["openssl"]="openssl"

# opencv/fft_batch
BM_DIR["opencv_fft"]="${BENCHCPU}/src/languages/cpp/opencv_benchmark"
BM_DATA_CMD["opencv_fft"]="echo 'no data needed'"
BM_RUN_CMD["opencv_fft"]="${BM_DIR[opencv_fft]}/bin/opencv_benchmark --workload fft_batch --size 625 --threads 1 --images 50"
BM_BBV_ITERS["opencv_fft"]=10
BM_PERF_ITERS["opencv_fft"]=10
BM_LABEL["opencv_fft"]="opencv_fft"

# gc_garbage (Go)
if command -v go &>/dev/null; then
    BM_DIR["gc_garbage"]="${BENCHCPU}/src/languages/go/garbage"
    BM_DATA_CMD["gc_garbage"]="cd ${BM_DIR[gc_garbage]} && python3 generate_data.py --size 94444 --output ./data/input.go && go build -o /tmp/gc_garbage_bbv garbage.go"
    BM_RUN_CMD["gc_garbage"]="env GOMAXPROCS=1 GOGC=100 /tmp/gc_garbage_bbv --input ${BM_DIR[gc_garbage]}/data/input.go --threads 1"
    BM_BBV_ITERS["gc_garbage"]=60
    BM_PERF_ITERS["gc_garbage"]=60
    BM_LABEL["gc_garbage"]="gc_garbage"
    USE_GC=1
else
    USE_GC=0
    BENCHMARKS=("openssl" "opencv_fft")
fi

# ── Helper functions ──────────────────────────────────
run_perf() {
    local label=$1 events=$2; shift 2
    local out="${WORK_DIR}/perf_${label}.csv"
    echo "  [$label] $(date)..."
    perf stat -x, --metric-only -e "$events" -o "$out" "$@" 2>&1 || {
        echo "  [WARN] perf failed for $label — some events may be unsupported"
        echo "error,$label" > "$out"
    }
    echo "  [$label] done ($(wc -l < "$out" 2>/dev/null || echo 0) lines)"
}

run_bbv() {
    local label=$1; shift
    local out="${WORK_DIR}/bbv_${label}.txt"
    echo "  [$label] Starting Valgrind BBV at $(date)..."
    $VALGRIND --tool=exp-bbv \
        --bb-out-file="$out" \
        --interval-size=10000000 \
        --log-file="${WORK_DIR}/valgrind_${label}.log" \
        "$@" 2>&1
    local n=$(wc -l < "$out" 2>/dev/null || echo 0)
    echo "  [$label] Done at $(date). BBV vectors: $n"
}

# ── 1. Generate data ──────────────────────────────────
echo ""
echo "[1/6] Generating data..."
for bm in "${BENCHMARKS[@]}"; do
    echo "  [${BM_LABEL[$bm]}] Generating..."
    eval "${BM_DATA_CMD[$bm]}"
done

# ── 2. Native timing ──────────────────────────────────
echo ""
echo "[2/6] Native timing reference..."
for bm in "${BENCHMARKS[@]}"; do
    label="${BM_LABEL[$bm]}"
    iters="${BM_BBV_ITERS[$bm]}"
    echo "  [$label] Running..."
    /usr/bin/time -o "${WORK_DIR}/time_${label}.txt" -f "%e real, %U user, %S sys" \
        ${BM_RUN_CMD[$bm]} --iters "$iters" --warmup 1 2>&1
    cat "${WORK_DIR}/time_${label}.txt"
done

# ── 3. Valgrind BBV ───────────────────────────────────
echo ""
echo "[3/6] Valgrind BBV (the slow part)..."
for bm in "${BENCHMARKS[@]}"; do
    label="${BM_LABEL[$bm]}"
    iters="${BM_BBV_ITERS[$bm]}"
    run_bbv "$label" ${BM_RUN_CMD[$bm]} --iters "$iters" --warmup 1
done

# ── 4. perf PMC ───────────────────────────────────────
echo ""
echo "[4/6] perf PMC collection..."
for bm in "${BENCHMARKS[@]}"; do
    label="${BM_LABEL[$bm]}"
    iters="${BM_PERF_ITERS[$bm]}"
    cmd="${BM_RUN_CMD[$bm]} --iters $iters --warmup 1"
    echo "  == $label =="
    run_perf "${label}_g1_core"      "$PERF_G1" $cmd
    run_perf "${label}_g2_cache_tlb" "$PERF_G2" $cmd
    run_perf "${label}_g3_stalls"    "$PERF_G3" $cmd
    run_perf "${label}_g4_fpvec"     "$PERF_G4" $cmd
done

# ── 5. Compute 19 metrics ─────────────────────────────
echo ""
echo "[5/6] Computing 19 derived metrics..."

python3 << 'PYEOF' > "${WORK_DIR}/metrics_19.csv"
import os, glob, re, sys

work = os.environ.get('WORK_DIR', '.')

def parse_perf_csv(path):
    events = {}
    try:
        with open(path) as f:
            for line in f:
                line = line.strip()
                if not line or line.startswith('#'):
                    continue
                parts = line.split(',')
                if len(parts) >= 2:
                    try:
                        v = float(parts[0].replace('<not counted>', '0').replace('<not supported>', '0'))
                        events[parts[1].strip()] = v
                    except ValueError:
                        pass
    except FileNotFoundError:
        pass
    return events

def compute_19(bench, perf_dir):
    all_ev = {}
    for g in sorted(glob.glob(f"{perf_dir}/perf_{bench}_g*.csv")):
        all_ev.update(parse_perf_csv(g))

    inst = max(all_ev.get('instructions', 1), 1)
    cyc  = max(all_ev.get('cpu-cycles', 1), 1)

    m = {}
    m['IPC'] = inst / cyc
    m['L1I_MPKI']  = all_ev.get('L1-icache-load-misses', 0) / (inst/1000)
    m['L1D_MPKI']  = all_ev.get('L1-dcache-load-misses', 0) / (inst/1000)
    m['L2_MPKI']   = all_ev.get('l2_rqsts.all_demand_miss', all_ev.get('cache-misses', 0)) / (inst/1000)
    m['L3_MPKI']   = all_ev.get('LLC-load-misses', 0) / (inst/1000)
    m['L1_iTLB_MPMI'] = all_ev.get('iTLB-load-misses', 0) / (inst/1e6)
    m['L1_dTLB_MPMI'] = all_ev.get('dTLB-load-misses', 0) / (inst/1e6)
    stlb = all_ev.get('frontend_retired.stlb_miss', 0) + all_ev.get('dtlb_load_misses.miss_causes_a_walk', 0)
    m['L2_TLB_MPMI']  = stlb / (inst/1e6)
    m['Branch_MPKI']  = all_ev.get('branch-misses', 0) / (inst/1000)

    slots = max(all_ev.get('topdown-total-slots', 1), 1)
    fetch = all_ev.get('topdown-fetch-bubbles', 0)
    retire = all_ev.get('topdown-slots-retired', 0)
    recovery = all_ev.get('topdown-recovery-bubbles', 0)
    m['Frontend_stall_pct'] = (fetch / slots) * 100
    m['Backend_stall_pct']  = max(0, 100 - (retire/slots)*100 - m['Frontend_stall_pct'] - (recovery/slots)*100)

    m['Load_pct']   = (all_ev.get('mem_inst_retired.all_loads', 0) / inst) * 100
    m['Store_pct']  = (all_ev.get('mem_inst_retired.all_stores', 0) / inst) * 100
    m['Branch_pct'] = (all_ev.get('branch-instructions', 0) / inst) * 100

    fp_s = all_ev.get('fp_arith_inst_retired.scalar_double', 0) + all_ev.get('fp_arith_inst_retired.scalar_single', 0)
    fp_v = sum(all_ev.get(k, 0) for k in [
        'fp_arith_inst_retired.128b_packed_double', 'fp_arith_inst_retired.256b_packed_double',
        'fp_arith_inst_retired.128b_packed_single', 'fp_arith_inst_retired.256b_packed_single'])
    m['FP_pct']     = (fp_s / inst) * 100
    m['Vector_pct'] = (fp_v / inst) * 100
    m['Mem_bytes_per_cycle'] = all_ev.get('LLC-load-misses', 0) * 64 / cyc

    # Kernel/User: approximate via perf if :u/:k collected, else N/A
    m['Kernel_pct'] = 0
    m['User_pct']   = 100

    return m

METRIC_NAMES = [
    'IPC', 'L1I_MPKI', 'L1D_MPKI', 'L2_MPKI', 'L3_MPKI',
    'L1_iTLB_MPMI', 'L1_dTLB_MPMI', 'L2_TLB_MPMI',
    'Branch_MPKI', 'Frontend_stall_pct', 'Backend_stall_pct',
    'Kernel_pct', 'User_pct', 'Load_pct', 'Store_pct', 'Branch_pct',
    'FP_pct', 'Vector_pct', 'Mem_bytes_per_cycle'
]

# Auto-detect which benchmarks ran
benchmarks = []
for prefix in ['openssl', 'opencv_fft', 'gc_garbage']:
    if glob.glob(f"{work}/bbv_{prefix}.txt"):
        benchmarks.append(prefix)

print("benchmark," + ",".join(METRIC_NAMES))
for bm in benchmarks:
    m = compute_19(bm, work)
    print(bm + "," + ",".join(f"{m.get(k, 0):.4f}" for k in METRIC_NAMES))

print(f"\n[DONE] Processed {len(benchmarks)} benchmarks", file=sys.stderr)
PYEOF

echo "  → ${WORK_DIR}/metrics_19.csv"
head -3 "${WORK_DIR}/metrics_19.csv"

# ── 6. Package results ────────────────────────────────
echo ""
echo "[6/6] Packaging results..."

cat > "${WORK_DIR}/README.md" << READMEEOF
# BBV + 19 PMC Analysis — Remote Run

- **Host**: $(hostname)
- **CPU**:  $(cat /proc/cpuinfo | grep 'model name' | head -1 | cut -d: -f2-)
- **Date**: $(date)

## Benchmarks (threads=1)

| Benchmark | Language | Parameters | Native time | BBV vectors |
|-----------|----------|------------|-------------|-------------|
EOF

for bm in "${BENCHMARKS[@]}"; do
    label="${BM_LABEL[$bm]}"
    time_file="${WORK_DIR}/time_${label}.txt"
    bbv_file="${WORK_DIR}/bbv_${label}.txt"
    native_t=$(cat "$time_file" 2>/dev/null | grep -oP '^\d+' || echo "?")
    bbv_lines=$(wc -l < "$bbv_file" 2>/dev/null || echo 0)
    echo "| $label | — | — | ${native_t}s | $bbv_lines |" >> "${WORK_DIR}/README.md"
done

cat >> "${WORK_DIR}/README.md" << READMEEOF

## Output Files

- `bbv_*.txt` — Valgrind BBV vectors (recurrence plot input)
- `perf_*_g*.csv` — Raw perf stat outputs
- `metrics_19.csv` — 19 derived PMC metrics
- `run.log` — Full execution log

## Post-processing: BBV Recurrence Plot

```python
import numpy as np
from scipy.spatial.distance import pdist, squareform
import matplotlib.pyplot as plt

for bench in ['openssl', 'opencv_fft', 'gc_garbage']:
    bbv = np.loadtxt(f'bbv_{bench}.txt')
    dist = squareform(pdist(bbv, metric='euclidean'))
    plt.figure(figsize=(8,6))
    plt.imshow(dist, cmap='hot', aspect='auto', origin='lower')
    plt.colorbar(label='BBV Distance')
    plt.title(f'BBV Self-Similarity: {bench}')
    plt.savefig(f'bbv_heatmap_{bench}.png', dpi=150)
```

## PCA of 19 Metrics (cf. SPEC Fig 3)

```python
import pandas as pd
from sklearn.decomposition import PCA

df = pd.read_csv('metrics_19.csv', index_col=0)
pca = PCA(n_components=2)
coords = pca.fit_transform(df.values)
# Plot alongside SPEC CPU26 reference points
```
READMEEOF

# Create tarball
TARBALL="${WORK_DIR}/../bbv_results_${TIMESTAMP}.tar.gz"
cd "${WORK_DIR}/.."
tar czf "$TARBALL" "$(basename $WORK_DIR)" \
    --exclude='*.o' --exclude='*.bin' --exclude='data.bin' --exclude='input.go'

echo ""
echo "============================================"
echo "  Complete!"
echo "  Finished: $(date)"
echo "  Results:  $WORK_DIR"
echo "  Tarball:  $TARBALL"
echo "============================================"
echo ""
echo "=== To copy results back ==="
echo "scp $(hostname):${TARBALL} ./"

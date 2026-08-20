#!/bin/bash
# ============================================================
# BBV + 19 PMC Analysis for 3 single-threaded benchmarks
#   openssl (C), opencv/fft_batch (C++), gc_garbage (Go)
# ============================================================
set -euo pipefail

TIMESTAMP=$(date +%Y%m%d_%H%M%S)
WORK_DIR="/sd7/syc/cpu_bench/results/bbv_3bench_${TIMESTAMP}"
mkdir -p "$WORK_DIR"

LOG="${WORK_DIR}/run.log"
exec > >(tee -a "$LOG") 2>&1

echo "============================================"
echo "  BBV + 19 PMC Pipeline — 3 Benchmarks"
echo "  Started: $(date)"
echo "  Work dir: $WORK_DIR"
echo "============================================"

# ── 0. Prerequisites ───────────────────────────────────
echo ""
echo "[0/6] Checking prerequisites..."

for cmd in valgrind clang g++; do
    if ! command -v $cmd &>/dev/null; then
        case $cmd in
            valgrind) apt-get install -y -qq valgrind ;;
            *) echo "[ERROR] $cmd not found"; exit 1 ;;
        esac
    fi
done

VALGRIND=$(command -v valgrind)
echo "  valgrind: $VALGRIND ($($VALGRIND --version 2>&1 | head -1))"
echo "  g++:      $(g++ --version 2>&1 | head -1)"
echo "  go:       $(go version 2>&1)"

# ── Benchmark definitions ──────────────────────────────

# Benchmark 1: openssl (C)
OPENSSL_DIR="/sd7/syc/cpu_bench/src/languages/c/openssl_benchmark"
OPENSSL_DATA_SIZE=30555      # from round_03
OPENSSL_BBV_ITERS=300        # ~65s native → ~32min BBV @30x
OPENSSL_PERF_ITERS=300       # same as BBV for consistency

# Benchmark 2: opencv/fft_batch (C++)
OPENCV_DIR="/sd7/syc/cpu_bench/src/languages/cpp/opencv_benchmark"
OPENCV_IMG_SIZE=625          # from round_13
OPENCV_BBV_ITERS=10          # ~59s native → ~30min BBV @30x
OPENCV_PERF_ITERS=10

# Benchmark 3: gc_garbage (Go)
GC_DIR="/sd7/syc/cpu_bench/src/languages/go/garbage"
GC_DATA_SIZE=94444           # from round_04
GC_BBV_ITERS=60              # ~60s native → ~50min BBV @30x
GC_PERF_ITERS=60

# ── 1. Prepare data ────────────────────────────────────
echo ""
echo "[1/6] Generating benchmark data..."

# openssl
echo "  [openssl] Generating data (size=$OPENSSL_DATA_SIZE)..."
cd "$OPENSSL_DIR"
python3 generate_data.py --size "$OPENSSL_DATA_SIZE" --output ./data/data.bin
ls -lh ./data/data.bin

# opencv (no data generation needed — uses in-memory images)
echo "  [opencv/fft_batch] No data generation needed."

# gc_garbage
echo "  [gc_garbage] Generating data (size=$GC_DATA_SIZE)..."
cd "$GC_DIR"
python3 generate_data.py --size "$GC_DATA_SIZE" --output ./data/input.go
ls -lh ./data/input.go
# Build Go binary
go build -o /tmp/gc_garbage_bbv garbage.go 2>&1
echo "  [gc_garbage] Binary built at /tmp/gc_garbage_bbv"

cd /sd7/syc/cpu_bench

# ── 2. Native timing ───────────────────────────────────
echo ""
echo "[2/6] Native timing (sanity check)..."

run_native() {
    local label=$1; shift
    echo "  [$label] $(date)..."
    /usr/bin/time -o "${WORK_DIR}/time_${label}.txt" -f "%e real, %U user, %S sys" "$@" 2>&1
    cat "${WORK_DIR}/time_${label}.txt"
}

# openssl native
run_native "openssl" \
    "${OPENSSL_DIR}/bin/openssl_benchmark" \
    --input "${OPENSSL_DIR}/data/data.bin" \
    --threads 1 --iters "$OPENSSL_BBV_ITERS" --warmup 1

# opencv native
run_native "opencv_fft" \
    "${OPENCV_DIR}/bin/opencv_benchmark" --workload fft_batch \
    --size "$OPENCV_IMG_SIZE" --threads 1 --iters "$OPENCV_BBV_ITERS" --warmup 1 --images 50

# gc_garbage native
run_native "gc_garbage" \
    env GOMAXPROCS=1 GOGC=100 \
    /tmp/gc_garbage_bbv \
    --input "${GC_DIR}/data/input.go" \
    --iterations "$GC_BBV_ITERS" --threads 1

# ── 3. Valgrind BBV ─────────────────────────────────────
echo ""
echo "[3/6] Valgrind BBV collection..."

run_bbv() {
    local label=$1; local out_prefix="${WORK_DIR}/bbv_${label}"
    shift
    echo "  [$label] Starting BBV at $(date)..."
    echo "  Command: valgrind --tool=exp-bbv $@"

    $VALGRIND --tool=exp-bbv \
        --bb-out-file="${out_prefix}.txt" \
        --interval-size=10000000 \
        --log-file="${out_prefix}.log" \
        "$@" 2>&1

    local total_lines=$(wc -l < "${out_prefix}.txt" 2>/dev/null || echo 0)
    echo "  [$label] Done at $(date). BBV lines: $total_lines"
    head -3 "${out_prefix}.txt" > "${out_prefix}.preview" 2>/dev/null || true
}

# openssl BBV
run_bbv "openssl" \
    "${OPENSSL_DIR}/bin/openssl_benchmark" \
    --input "${OPENSSL_DIR}/data/data.bin" \
    --threads 1 --iters "$OPENSSL_BBV_ITERS" --warmup 1

# opencv BBV
run_bbv "opencv_fft" \
    "${OPENCV_DIR}/bin/opencv_benchmark" --workload fft_batch \
    --size "$OPENCV_IMG_SIZE" --threads 1 --iters "$OPENCV_BBV_ITERS" --warmup 1 --images 50

# gc_garbage BBV (Go binary needs env vars)
run_bbv "gc_garbage" \
    env GOMAXPROCS=1 GOGC=100 \
    /tmp/gc_garbage_bbv \
    --input "${GC_DIR}/data/input.go" \
    --iterations "$GC_BBV_ITERS" --threads 1

# ── 4. perf PMC (19 metrics, 4 groups × 3 benchmarks) ──
echo ""
echo "[4/6] perf PMC collection (19 metrics)..."

run_perf() {
    local label=$1; local events="$2"
    local out="${WORK_DIR}/perf_${label}.csv"
    shift 2
    echo "  [$label] $(date)..."
    perf stat -x, --metric-only \
        -e "$events" \
        -o "$out" \
        "$@" 2>&1
    echo "  [$label] → $out ($(wc -l < "$out") lines)"
}

# perf groups for ALL benchmarks
# G1: IPC, L1I/L1D/L2 MPKI, Branch MPKI (4 programmable)
PERF_G1="instructions,cpu-cycles,branch-instructions,branch-misses,\
L1-icache-load-misses,L1-dcache-load-misses,l2_rqsts.all_demand_miss"

# G2: L3 MPKI, TLB MPMI, Load/Store% (4 programmable)
PERF_G2="instructions,cpu-cycles,LLC-load-misses,\
iTLB-load-misses,dTLB-load-misses,\
mem_inst_retired.all_loads,mem_inst_retired.all_stores"

# G3: Top-down: Frontend/Backend stall% (4 programmable)
PERF_G3="instructions,cpu-cycles,\
topdown-total-slots,topdown-fetch-bubbles,\
topdown-slots-retired,topdown-recovery-bubbles,\
topdown-slots-issued"

# G4: FP/Vector%, L2 TLB (4 programmable)
PERF_G4="instructions,cpu-cycles,\
fp_arith_inst_retired.scalar_double,fp_arith_inst_retired.scalar_single,\
fp_arith_inst_retired.128b_packed_double,fp_arith_inst_retired.256b_packed_double,\
frontend_retired.stlb_miss,dtlb_load_misses.miss_causes_a_walk"

# Helper: run all 4 perf groups for one benchmark
run_all_perf() {
    local label=$1; shift
    # $@ = the command to run

    run_perf "${label}_g1_core"        "$PERF_G1" "$@"
    run_perf "${label}_g2_cache_tlb"   "$PERF_G2" "$@"
    run_perf "${label}_g3_topdown"     "$PERF_G3" "$@"
    run_perf "${label}_g4_fpvec_tlb2"  "$PERF_G4" "$@"
}

# --- openssl perf ---
run_all_perf "openssl" \
    "${OPENSSL_DIR}/bin/openssl_benchmark" \
    --input "${OPENSSL_DIR}/data/data.bin" \
    --threads 1 --iters "$OPENSSL_PERF_ITERS" --warmup 1

# --- opencv perf ---
run_all_perf "opencv_fft" \
    "${OPENCV_DIR}/bin/opencv_benchmark" --workload fft_batch \
    --size "$OPENCV_IMG_SIZE" --threads 1 --iters "$OPENCV_PERF_ITERS" --warmup 1 --images 50

# --- gc_garbage perf ---
run_all_perf "gc_garbage" \
    env GOMAXPROCS=1 GOGC=100 \
    /tmp/gc_garbage_bbv \
    --input "${GC_DIR}/data/input.go" \
    --iterations "$GC_PERF_ITERS" --threads 1

# ── 5. Build 19-metric table ───────────────────────────
echo ""
echo "[5/6] Computing 19 derived metrics..."

python3 << PYEOF > "${WORK_DIR}/metrics_19.csv"
import glob, re, os

work = "${WORK_DIR}"

def parse_perf(path):
    """Parse perf CSV and return dict of event->value."""
    events = {}
    with open(path) as f:
        for line in f:
            line = line.strip()
            if not line: continue
            # perf -x, output: value,eventname,running%,...
            parts = line.split(',')
            if len(parts) >= 2:
                try:
                    val = float(parts[0].replace('<not counted>','0'))
                    name = parts[1].strip()
                    events[name] = val
                except: pass
    return events

def compute_19(bench, perf_dir):
    """Merge 4 perf groups into 19 metrics."""
    all_ev = {}
    for g in glob.glob(f"{perf_dir}/perf_{bench}_g*.csv"):
        all_ev.update(parse_perf(g))

    inst = all_ev.get('instructions', 1)
    cyc  = all_ev.get('cpu-cycles', 1)
    if inst == 0: inst = 1
    if cyc == 0: cyc = 1

    m = {}

    # 1. IPC
    m['IPC'] = inst / cyc if cyc else 0

    # 2-5. Cache MPKI
    m['L1I_MPKI'] = all_ev.get('L1-icache-load-misses',0) / (inst/1000)
    m['L1D_MPKI'] = all_ev.get('L1-dcache-load-misses',0) / (inst/1000)
    m['L2_MPKI']  = all_ev.get('l2_rqsts.all_demand_miss',0) / (inst/1000)
    m['L3_MPKI']  = all_ev.get('LLC-load-misses',0) / (inst/1000)

    # 6-8. TLB MPMI (misses per million instructions)
    m['L1_iTLB_MPMI'] = all_ev.get('iTLB-load-misses',0) / (inst/1e6)
    m['L1_dTLB_MPMI'] = all_ev.get('dTLB-load-misses',0) / (inst/1e6)
    stlb = all_ev.get('frontend_retired.stlb_miss',0) + all_ev.get('dtlb_load_misses.miss_causes_a_walk',0)
    m['L2_TLB_MPMI'] = stlb / (inst/1e6)

    # 9. Branch MPKI
    m['Branch_MPKI'] = all_ev.get('branch-misses',0) / (inst/1000)

    # 10-11. Top-down stall%
    slots = all_ev.get('topdown-total-slots',1)
    if slots == 0: slots = 1
    fetch = all_ev.get('topdown-fetch-bubbles',0)
    retire = all_ev.get('topdown-slots-retired',0)
    recovery = all_ev.get('topdown-recovery-bubbles',0)
    m['Frontend_stall_pct'] = (fetch / slots) * 100
    m['Backend_stall_pct']  = max(0, 100 - (retire/slots)*100 - m['Frontend_stall_pct'] - (recovery/slots)*100)

    # 12-13. Kernel/User % (approximate — all instructions from perf stat are user+kernel)
    # On Skylake, need :u and :k separation. Use fallback: assume user-dominated.
    m['Kernel_pct'] = 0  # placeholder, need instructions:u/k
    m['User_pct']   = 100

    # 14-16. Inst Mix
    m['Load_pct']   = (all_ev.get('mem_inst_retired.all_loads',0) / inst) * 100
    m['Store_pct']  = (all_ev.get('mem_inst_retired.all_stores',0) / inst) * 100
    m['Branch_pct'] = (all_ev.get('branch-instructions',0) / inst) * 100

    # 17-18. FP/Vector %
    fp_scalar = all_ev.get('fp_arith_inst_retired.scalar_double',0) + all_ev.get('fp_arith_inst_retired.scalar_single',0)
    fp_vector = sum(all_ev.get(k,0) for k in [
        'fp_arith_inst_retired.128b_packed_double',
        'fp_arith_inst_retired.256b_packed_double',
        'fp_arith_inst_retired.128b_packed_single',
        'fp_arith_inst_retired.256b_packed_single'])
    m['FP_pct']    = (fp_scalar / inst) * 100
    m['Vector_pct'] = (fp_vector / inst) * 100

    # 19. Mem access (bytes/cycle) — approximate
    m['Mem_bytes_per_cycle'] = all_ev.get('LLC-load-misses',0) * 64 / cyc

    return m

# Compute for all 3
print("benchmark," + ",".join(compute_19("openssl", work).keys()))
for bench in ["openssl", "opencv_fft", "gc_garbage"]:
    m = compute_19(bench, work)
    print(bench + "," + ",".join(f"{v:.4f}" for v in m.values()))

print("", file=__import__('sys').stderr)
print("[INFO] 19 metrics saved to metrics_19.csv", file=__import__('sys').stderr)
PYEOF

echo "  19-metric table: ${WORK_DIR}/metrics_19.csv"
cat "${WORK_DIR}/metrics_19.csv"

# ── 6. Summary ─────────────────────────────────────────
echo ""
echo "[6/6] Generating summary..."

cat > "${WORK_DIR}/README.md" << READMEEOF
# BBV + 19 PMC Analysis — 3 Benchmarks

## Configurations

| Benchmark | Language | Param | Threads | BBV iters | Perf iters |
|-----------|----------|-------|:------:|:---------:|:----------:|
| openssl | C | size=30555 | 1 | 300 | 300 |
| opencv/fft_batch | C++ | size=625 | 1 | 10 | 10 |
| gc_garbage | Go | size=94444 | 1 | 60 | 60 |

## Output Files

\`\`\`
bbv_openssl.txt       — Valgrind BBV vectors (openssl)
bbv_opencv_fft.txt    — Valgrind BBV vectors (opencv/fft_batch)
bbv_gc_garbage.txt    — Valgrind BBV vectors (gc_garbage)
perf_*_g*.csv         — perf stat outputs (4 groups × 3 benchmarks)
metrics_19.csv        — Computed 19 derived PMC metrics
time_*.txt            — Native execution timings
run.log               — Full log
\`\`\`

## Post-processing

\`\`\`python
import numpy as np
import matplotlib.pyplot as plt
from scipy.spatial.distance import pdist, squareform

for bench in ['openssl', 'opencv_fft', 'gc_garbage']:
    bbv = np.loadtxt(f'bbv_{bench}.txt')
    dist = squareform(pdist(bbv, metric='euclidean'))
    plt.figure(figsize=(8,6))
    plt.imshow(dist, cmap='hot', aspect='auto', origin='lower')
    plt.colorbar(label='BBV Distance')
    plt.title(f'BBV Self-Similarity: {bench}')
    plt.savefig(f'bbv_heatmap_{bench}.png', dpi=150)
\`\`\`
READMEEOF

echo ""
echo "============================================"
echo "  Pipeline Complete!"
echo "  Finished: $(date)"
echo "  Results:  $WORK_DIR"
echo "============================================"
echo ""
echo "Output files:"
ls -lh "$WORK_DIR/" | grep -v "^total"

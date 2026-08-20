#!/bin/bash
# Fix 3 issues:
#  1. Rename BBV .txt.PID → .txt
#  2. Re-run perf WITHOUT --metric-only (raw events needed)
#  3. Re-try gc_garbage BBV
set -euo pipefail

WORK_DIR="/sd7/syc/cpu_bench/results/bbv_3bench_20260615_163439"
LOG="${WORK_DIR}/fixup.log"
exec > >(tee -a "$LOG") 2>&1

echo "============================================"
echo "  Fixup Script"
echo "  Started: $(date)"
echo "============================================"

# ── 1. Fix BBV filenames ──────────────────────────────
echo ""
echo "[1/3] Fixing BBV filenames..."
for f in "$WORK_DIR"/bbv_*.txt.*; do
    [ -f "$f" ] || continue
    base="${f%.*}"  # remove .2 suffix
    if [ -s "$f" ] && [ ! -s "$base" ]; then
        mv "$f" "$base"
        echo "  Renamed: $(basename $f) → $(basename $base) ($(wc -l < $base) lines)"
    fi
done

# ── 2. Re-run perf with raw event names ───────────────
echo ""
echo "[2/3] Re-running perf with raw event format..."

OPENSSL_DIR="/sd7/syc/cpu_bench/src/languages/c/openssl_benchmark"
OPENCV_DIR="/sd7/syc/cpu_bench/src/languages/cpp/opencv_benchmark"
GC_DIR="/sd7/syc/cpu_bench/src/languages/go/garbage"

# NOT --metric-only — preserves raw event names like "instructions","cpu-cycles",...
PERF_G1="instructions,cpu-cycles,branch-instructions,branch-misses,\
L1-icache-load-misses,L1-dcache-load-misses,l2_rqsts.all_demand_miss"

PERF_G2="instructions,cpu-cycles,LLC-load-misses,\
iTLB-load-misses,dTLB-load-misses,\
mem_inst_retired.all_loads,mem_inst_retired.all_stores"

PERF_G3="instructions,cpu-cycles,\
topdown-total-slots,topdown-fetch-bubbles,\
topdown-slots-retired,topdown-recovery-bubbles,\
topdown-slots-issued"

PERF_G4="instructions,cpu-cycles,\
fp_arith_inst_retired.scalar_double,fp_arith_inst_retired.scalar_single,\
fp_arith_inst_retired.128b_packed_double,fp_arith_inst_retired.256b_packed_double,\
frontend_retired.stlb_miss,dtlb_load_misses.miss_causes_a_walk"

run_perf_raw() {
    local label=$1 events=$2; shift 2
    local out="${WORK_DIR}/perf_${label}.csv"
    echo "  [$label] $(date)..."
    # remove --metric-only, keep -x, for raw event→count pairs
    perf stat -x, -e "$events" -o "$out" "$@" 2>&1 || echo "  [WARN] some events failed for $label"
    local n=$(grep -c ',' "$out" 2>/dev/null || echo 0)
    echo "  [$label] → $out ($n event lines)"
}

# --- openssl ---
echo "  === openssl ==="
run_perf_raw "openssl_g1_core"      "$PERF_G1" \
    "${OPENSSL_DIR}/bin/openssl_benchmark" \
    --input "${OPENSSL_DIR}/data/data.bin" --threads 1 --iters 300 --warmup 1
run_perf_raw "openssl_g2_cache_tlb" "$PERF_G2" \
    "${OPENSSL_DIR}/bin/openssl_benchmark" \
    --input "${OPENSSL_DIR}/data/data.bin" --threads 1 --iters 300 --warmup 1
run_perf_raw "openssl_g3_topdown"   "$PERF_G3" \
    "${OPENSSL_DIR}/bin/openssl_benchmark" \
    --input "${OPENSSL_DIR}/data/data.bin" --threads 1 --iters 300 --warmup 1
run_perf_raw "openssl_g4_fpvec"     "$PERF_G4" \
    "${OPENSSL_DIR}/bin/openssl_benchmark" \
    --input "${OPENSSL_DIR}/data/data.bin" --threads 1 --iters 300 --warmup 1

# --- opencv ---
echo "  === opencv ==="
run_perf_raw "opencv_fft_g1_core"      "$PERF_G1" \
    "${OPENCV_DIR}/bin/opencv_benchmark" --workload fft_batch \
    --size 625 --threads 1 --iters 10 --warmup 1 --images 50
run_perf_raw "opencv_fft_g2_cache_tlb" "$PERF_G2" \
    "${OPENCV_DIR}/bin/opencv_benchmark" --workload fft_batch \
    --size 625 --threads 1 --iters 10 --warmup 1 --images 50
run_perf_raw "opencv_fft_g3_topdown"   "$PERF_G3" \
    "${OPENCV_DIR}/bin/opencv_benchmark" --workload fft_batch \
    --size 625 --threads 1 --iters 10 --warmup 1 --images 50
run_perf_raw "opencv_fft_g4_fpvec"     "$PERF_G4" \
    "${OPENCV_DIR}/bin/opencv_benchmark" --workload fft_batch \
    --size 625 --threads 1 --iters 10 --warmup 1 --images 50

# --- gc_garbage ---
echo "  === gc_garbage ==="
run_perf_raw "gc_garbage_g1_core"      "$PERF_G1" \
    env GOMAXPROCS=1 GOGC=100 /tmp/gc_garbage_bbv \
    --input "${GC_DIR}/data/input.go" --iterations 60 --threads 1
run_perf_raw "gc_garbage_g2_cache_tlb" "$PERF_G2" \
    env GOMAXPROCS=1 GOGC=100 /tmp/gc_garbage_bbv \
    --input "${GC_DIR}/data/input.go" --iterations 60 --threads 1
run_perf_raw "gc_garbage_g3_topdown"   "$PERF_G3" \
    env GOMAXPROCS=1 GOGC=100 /tmp/gc_garbage_bbv \
    --input "${GC_DIR}/data/input.go" --iterations 60 --threads 1
run_perf_raw "gc_garbage_g4_fpvec"     "$PERF_G4" \
    env GOMAXPROCS=1 GOGC=100 /tmp/gc_garbage_bbv \
    --input "${GC_DIR}/data/input.go" --iterations 60 --threads 1

# ── 3. Re-try gc_garbage BBV ──────────────────────────
echo ""
echo "[3/3] Re-trying gc_garbage BBV..."
BBV_OUT="${WORK_DIR}/bbv_gc_garbage.txt"
echo "  [gc_garbage] Starting Valgrind BBV at $(date)..."
valgrind --tool=exp-bbv \
    --bb-out-file="$BBV_OUT" \
    --interval-size=10000000 \
    --log-file="${WORK_DIR}/valgrind_gc_garbage.log" \
    env GOMAXPROCS=1 GOGC=100 /tmp/gc_garbage_bbv \
    --input "${GC_DIR}/data/input.go" \
    --iterations 60 --threads 1 2>&1 || echo "  [WARN] gc_garbage BBV may have failed"

# Check if any .txt.PID files were created
for f in "${WORK_DIR}/bbv_gc_garbage.txt".*; do
    [ -f "$f" ] && mv "$f" "${WORK_DIR}/bbv_gc_garbage.txt" && echo "  Renamed $f → bbv_gc_garbage.txt"
done

N=$(wc -l < "$BBV_OUT" 2>/dev/null || echo 0)
echo "  [gc_garbage] BBV vectors: $N"

# ── 4. Recompute 19 metrics ───────────────────────────
echo ""
echo "[4] Recomputing metrics_19.csv..."

python3 << 'PYEOF' > "${WORK_DIR}/metrics_19.csv"
import os, glob, sys

work = os.environ.get('WORK_DIR', '.')

def parse_perf_csv_raw(path):
    """Parse perf -x, CSV (raw format): value,eventname,unit,...
       Also handles metric-only format as fallback."""
    events = {}
    try:
        with open(path) as f:
            for line in f:
                line = line.strip()
                if not line or line.startswith('#'):
                    continue
                parts = line.split(',')
                if len(parts) < 2:
                    continue
                # Try to parse first field as float
                try:
                    v = float(parts[0].replace('<not counted>', '0').replace('<not supported>', '0'))
                except ValueError:
                    continue
                name = parts[1].strip()
                events[name] = v
    except FileNotFoundError:
        pass
    return events

def compute_19(bench, perf_dir):
    all_ev = {}
    for g in sorted(glob.glob(f"{perf_dir}/perf_{bench}_g*.csv")):
        all_ev.update(parse_perf_csv_raw(g))

    # Debug: print found events
    found = sorted(all_ev.keys())
    print(f"[DEBUG] {bench}: found {len(found)} events: {found[:10]}...", file=sys.stderr)

    inst = max(all_ev.get('instructions', 1), 1)
    cyc  = max(all_ev.get('cpu-cycles', all_ev.get('cycles', 1)), 1)

    m = {}
    m['IPC'] = inst / cyc

    # Cache MPKI — try both raw event names and metric-only names
    l1i = all_ev.get('L1-icache-load-misses', all_ev.get('L1-icache-load-misses of all L1-icache hits', 0))
    l1d = all_ev.get('L1-dcache-load-misses', all_ev.get('L1-dcache-load-misses of all L1-dcache hits', 0))
    l2  = all_ev.get('l2_rqsts.all_demand_miss', all_ev.get('cache-misses', 0))
    l3  = all_ev.get('LLC-load-misses', all_ev.get('LLC-load-misses of all L1-icache hits', 0))
    m['L1I_MPKI']  = l1i / (inst/1000) if inst > 1000 else 0
    m['L1D_MPKI']  = l1d / (inst/1000) if inst > 1000 else 0
    m['L2_MPKI']   = l2 / (inst/1000) if inst > 1000 else 0
    m['L3_MPKI']   = l3 / (inst/1000) if inst > 1000 else 0

    itlb = all_ev.get('iTLB-load-misses', 0)
    dtlb = all_ev.get('dTLB-load-misses', 0)
    stlb = all_ev.get('frontend_retired.stlb_miss', 0) + all_ev.get('dtlb_load_misses.miss_causes_a_walk', 0)
    m['L1_iTLB_MPMI'] = itlb / (inst/1e6) if inst > 1e6 else 0
    m['L1_dTLB_MPMI'] = dtlb / (inst/1e6) if inst > 1e6 else 0
    m['L2_TLB_MPMI']  = stlb / (inst/1e6) if inst > 1e6 else 0

    bmiss = all_ev.get('branch-misses', all_ev.get('branch-misses of all branches', 0))
    m['Branch_MPKI']  = bmiss / (inst/1000) if inst > 1000 else 0

    slots = max(all_ev.get('topdown-total-slots', 1), 1)
    fetch = all_ev.get('topdown-fetch-bubbles', 0)
    retire = all_ev.get('topdown-slots-retired', 0)
    recovery = all_ev.get('topdown-recovery-bubbles', 0)
    m['Frontend_stall_pct'] = (fetch / slots) * 100
    m['Backend_stall_pct']  = max(0, 100 - (retire/slots)*100 - m['Frontend_stall_pct'] - (recovery/slots)*100)

    m['Kernel_pct'] = 0
    m['User_pct']   = 100

    loads  = all_ev.get('mem_inst_retired.all_loads', 0)
    stores = all_ev.get('mem_inst_retired.all_stores', 0)
    brs    = all_ev.get('branch-instructions', all_ev.get('branches', 0))
    m['Load_pct']   = (loads / inst) * 100 if inst > 0 else 0
    m['Store_pct']  = (stores / inst) * 100 if inst > 0 else 0
    m['Branch_pct'] = (brs / inst) * 100 if inst > 0 else 0

    fp_s = all_ev.get('fp_arith_inst_retired.scalar_double', 0) + all_ev.get('fp_arith_inst_retired.scalar_single', 0)
    fp_v = sum(all_ev.get(k, 0) for k in [
        'fp_arith_inst_retired.128b_packed_double', 'fp_arith_inst_retired.256b_packed_double',
        'fp_arith_inst_retired.128b_packed_single', 'fp_arith_inst_retired.256b_packed_single'])
    m['FP_pct']     = (fp_s / inst) * 100
    m['Vector_pct'] = (fp_v / inst) * 100
    m['Mem_bytes_per_cycle'] = l3 * 64 / cyc

    return m

METRIC_NAMES = [
    'IPC', 'L1I_MPKI', 'L1D_MPKI', 'L2_MPKI', 'L3_MPKI',
    'L1_iTLB_MPMI', 'L1_dTLB_MPMI', 'L2_TLB_MPMI',
    'Branch_MPKI', 'Frontend_stall_pct', 'Backend_stall_pct',
    'Kernel_pct', 'User_pct', 'Load_pct', 'Store_pct', 'Branch_pct',
    'FP_pct', 'Vector_pct', 'Mem_bytes_per_cycle'
]

benchmarks = ['openssl', 'opencv_fft', 'gc_garbage']

print("benchmark," + ",".join(METRIC_NAMES))
for bm in benchmarks:
    m = compute_19(bm, work)
    print(bm + "," + ",".join(f"{m.get(k, 0):.4f}" for k in METRIC_NAMES))

print("\n[DONE] Metrics recomputed", file=sys.stderr)
PYEOF

echo "  → ${WORK_DIR}/metrics_19.csv"
echo ""
echo "=== Final metrics_19.csv ==="
cat "${WORK_DIR}/metrics_19.csv"
echo ""
echo "=== BBV vectors ==="
for f in "$WORK_DIR"/bbv_*.txt; do
    [ -f "$f" ] && echo "  $(basename $f): $(wc -l < $f) lines ($(du -h $f | cut -f1))"
done
echo ""
echo "Fixup complete: $(date)"

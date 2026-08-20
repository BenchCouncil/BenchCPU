#!/bin/bash
# ============================================================
# BBV + PMC Analysis for clang_compile (O1 vs O3)
# 复现 SPEC CPU2026 Fig1 (BBV heatmap) + Fig3 (19 PMC metrics)
# ============================================================
set -euo pipefail

BENCH_DIR="/sd7/syc/cpu_bench/src/languages/c/c_compiler_benchmark"
WORK_DIR="/sd7/syc/cpu_bench/results/bbv_analysis_$(date +%Y%m%d_%H%M%S)"
LOG_FILE="$WORK_DIR/run.log"

mkdir -p "$WORK_DIR"
exec > >(tee -a "$LOG_FILE") 2>&1

echo "============================================"
echo "  BBV + PMC Analysis Pipeline"
echo "  Started: $(date)"
echo "  Work dir: $WORK_DIR"
echo "============================================"

# ── 0. Pre-flight ──────────────────────────────────────
echo ""
echo "[0/5] Checking prerequisites..."

if ! command -v valgrind &>/dev/null; then
    echo "[INSTALL] Installing valgrind..."
    apt-get update -qq && apt-get install -y -qq valgrind 2>&1 | tail -3
fi

if ! command -v clang &>/dev/null; then
    echo "[ERROR] clang not found, aborting."
    exit 1
fi

VALGRIND=$(command -v valgrind)
CLANG=$(command -v clang)
echo "  valgrind: $VALGRIND ($($VALGRIND --version 2>&1 | head -1))"
echo "  clang:    $CLANG  ($($CLANG --version 2>&1 | head -1))"

cd "$BENCH_DIR"

# ── 1. Generate source files ──────────────────────────
echo ""
echo "[1/5] Generating source files..."

# Config A: Round 8 style (O1, func_size=100)
echo "  Generating func_size=100..."
python3 generate_data.py --func_size 100
mkdir -p "$WORK_DIR/src_func100"
cp -r data/src/* "$WORK_DIR/src_func100/"

# Config B: Round 3 style (O3, func_size=188)
echo "  Generating func_size=188..."
python3 generate_data.py --func_size 188
mkdir -p "$WORK_DIR/src_func188"
cp -r data/src/* "$WORK_DIR/src_func188/"

SRC_FILES=$(ls data/src/*.c | tr '\n' ' ')
echo "  Source files: $(echo $SRC_FILES | wc -w) C files"

# ── 2. Single clang baseline timing ───────────────────
echo ""
echo "[2/5] Baseline single-clang timing..."

run_clang_native() {
    local opt=$1
    local func_size=$2
    local src_dir="$WORK_DIR/src_func${func_size}"
    local SRC=$(ls "$src_dir"/*.c | tr '\n' ' ')

    echo "  Clang -$opt func_size=$func_size (native, single run)..."
    /usr/bin/time -o "$WORK_DIR/time_${opt}_f${func_size}.txt" -f "%e real, %U user, %S sys" \
        clang -$opt -pthread $SRC -o /tmp/clang_bbv_test -lm 2>&1
    rm -f /tmp/clang_bbv_test
    cat "$WORK_DIR/time_${opt}_f${func_size}.txt"
}

run_clang_native "O1" "100"
run_clang_native "O3" "188"

# ── 3. Valgrind BBV ───────────────────────────────────
echo ""
echo "[3/5] Valgrind BBV collection (this is the slow part)..."

run_bbv() {
    local opt=$1
    local func_size=$2
    local label="${opt}_f${func_size}"
    local src_dir="$WORK_DIR/src_func${func_size}"
    local SRC=$(ls "$src_dir"/*.c | tr '\n' ' ')
    local bbv_out="$WORK_DIR/bbv_${label}.txt"
    local valgrind_log="$WORK_DIR/valgrind_${label}.log"

    echo "  [$label] Starting Valgrind BBV at $(date)..."
    echo "  Command: valgrind --tool=exp-bbv clang -$opt $SRC"

    $VALGRIND --tool=exp-bbv \
        --bb-out-file="$bbv_out" \
        --interval-size=10000000 \
        --trace-children=yes \
        --log-file="$valgrind_log" \
        clang -$opt -pthread $SRC -o /tmp/clang_bbv_out -lm 2>&1

    rm -f /tmp/clang_bbv_out

    # Filter BBV vectors (T: lines) from summary (# lines)
    grep "^T:" "$bbv_out" > "${bbv_out}.vectors" 2>/dev/null || true
    local bbv_total=$(wc -l < "$bbv_out" 2>/dev/null || echo 0)
    local bbv_vecs=$(wc -l < "${bbv_out}.vectors" 2>/dev/null || echo 0)
    echo "  [$label] Done at $(date). Total lines: $bbv_total, BBV vectors: $bbv_vecs"
    echo "  Output: $bbv_out (vectors: ${bbv_out}.vectors)"

    # Save first few BBV vectors for preview
    head -3 "${bbv_out}.vectors" > "${bbv_out}.preview" 2>/dev/null || true
}

run_bbv "O1" "100"
run_bbv "O3" "188"

# ── 4. perf PMC collection (19 metrics, 4 groups) ────
echo ""
echo "[4/5] perf PMC collection..."

run_perf_group() {
    local opt=$1
    local func_size=$2
    local group_name=$3
    local events="$4"
    local label="perf_${opt}_f${func_size}_${group_name}"
    local src_dir="$WORK_DIR/src_func${func_size}"
    local SRC=$(ls "$src_dir"/*.c | tr '\n' ' ')

    echo "  [$label] $(date)..."

    perf stat -x, --metric-only \
        -e "$events" \
        -o "$WORK_DIR/${label}.csv" \
        clang -$opt -pthread $SRC -o /tmp/clang_perf_out -lm 2>&1

    rm -f /tmp/clang_perf_out
    echo "  [$label] Done."
}

for opt_func in "O1 100" "O3 188"; do
    opt=$(echo $opt_func | awk '{print $1}')
    fs=$(echo $opt_func | awk '{print $2}')

    # Group 1: Core IPC + Cache + Branch
    run_perf_group $opt $fs "g1_core" \
        "instructions,cpu-cycles,branch-instructions,branch-misses,\
L1-icache-load-misses,L1-dcache-load-misses,\
l2_rqsts.all_demand_miss,LLC-load-misses"

    # Group 2: TLB + STLB
    run_perf_group $opt $fs "g2_tlb" \
        "instructions,iTLB-load-misses,dTLB-load-misses,\
frontend_retired.stlb_miss,frontend_retired.itlb_miss,\
dtlb_load_misses.miss_causes_a_walk,\
mem_inst_retired.stlb_miss_loads"

    # Group 3: Top-down + Inst Mix
    run_perf_group $opt $fs "g3_topdown_mix" \
        "instructions,cpu-cycles,\
topdown-total-slots,topdown-fetch-bubbles,\
topdown-slots-retired,topdown-recovery-bubbles,\
topdown-slots-issued,\
mem_inst_retired.all_loads,mem_inst_retired.all_stores"

    # Group 4: FP/Vector
    run_perf_group $opt $fs "g4_fpvec" \
        "instructions,\
fp_arith_inst_retired.scalar_double,\
fp_arith_inst_retired.scalar_single,\
fp_arith_inst_retired.128b_packed_double,\
fp_arith_inst_retired.256b_packed_double,\
fp_arith_inst_retired.128b_packed_single,\
fp_arith_inst_retired.256b_packed_single"
done

# ── 5. Summary ────────────────────────────────────────
echo ""
echo "[5/5] Generating summary..."

cat > "$WORK_DIR/summary.md" << 'SUMMARYEOF'
# BBV + PMC Analysis Summary

## Configurations

| Config | opt | func_size | Source |
|--------|-----|-----------|--------|
| A (simple) | O1 | 100 | Round 8 style |
| B (complex) | O3 | 188 | Round 3 style |

## Output Files

### BBV Vectors (Valgrind exp-bbv)
- `bbv_O1_f100.txt` — Config A BBV vectors
- `bbv_O3_f188.txt` — Config B BBV vectors

### 19 PMC Metrics (perf stat)
| Group | Metrics |
|-------|---------|
| g1_core | IPC, L1I/L1D/L2/L3 MPKI, Branch MPKI |
| g2_tlb | L1 iTLB, L1 dTLB, L2 STLB MPMI |
| g3_topdown_mix | Frontend/Backend stall%, Load/Store% |
| g4_fpvec | FP%, Vector% |

### Raw Data
- All perf CSVs: `perf_*.csv`
- Valgrind logs: `valgrind_*.log`
- Native timing: `time_*.txt`
- Full run log: `run.log`

## Post-processing (Python)

```python
import numpy as np
from scipy.spatial.distance import pdist, squareform
import matplotlib.pyplot as plt

# BBV → heatmap
bbv = np.loadtxt('bbv_O3_f188.txt')
dist = squareform(pdist(bbv, metric='euclidean'))
plt.imshow(dist, cmap='hot', aspect='auto', origin='lower')
plt.title('BBV Self-Similarity (clang -O3)')
plt.savefig('bbv_heatmap_O3.png', dpi=150)
```
SUMMARYEOF

echo ""
echo "============================================"
echo "  Pipeline Complete!"
echo "  Finished: $(date)"
echo "  Results:  $WORK_DIR"
echo "============================================"

# Quick file listing
echo ""
echo "Output files:"
ls -lh "$WORK_DIR/"

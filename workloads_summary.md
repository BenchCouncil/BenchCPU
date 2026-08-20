# CPU Bench 54-Workload 全景总结

> 配置函数：`test/lab1_momentum.py` → `get_lab_config(16)` 生成 16 轮随机参数

---

## 参数空间（4 类，每轮随机采样）

### 1. data/size 参数
默认基准值 `base`，每轮从 `[base, base×2)` 区间均匀取 10 个点随机选一：
```
val = random.choice([base + (base * i) // 9 for i in range(10)])
```

### 2. compiler 参数
`random.choice(["clang", "gcc"])` — 仅影响有 `--setup-env` 的 C/C++ 项目

### 3. opt 优化级别
`random.choice(["-O1", "-O2", "-O3"])` — c_compiler 用 `O1/O2/O3` 无横线

### 4. threads 参数
`random.randint(1, 64)` — 54个 workload 各自独立随机

---

## 54 个 Workload 详情

### 一、Python（15 个）

| # | Workload | 做什么 | 输入 | 参数空间 |
|---|----------|--------|------|----------|
| 1 | **numpy/matmul** | 稠密矩阵乘法 (BLAS) | size 默认 2048 | size ∈ [2048, 4096), threads ∈ [1,64] |
| 2 | **numpy/svd** | 奇异值分解 (SVD) | size 默认 1024 | size ∈ [1024, 2048), threads ∈ [1,64] |
| 3 | **numpy/fft** | 一维快速傅里叶变换 | size 默认 4.2M | size ∈ [4.2M, 8.4M), threads ∈ [1,64] |
| 4 | **tuf/metadata** | TUF 安全元数据 SHA256 哈希 | size 默认 256 MiB | size ∈ [256M, 512M), threads ∈ [1,64] |
| 5 | **requests/json** | 本地 JSON 反序列化 (模拟 HTTP) | size 默认 128K | size ∈ [128K, 256K), threads ∈ [1,64] |
| 6 | **raytrace** | 纯 Python 3D 光线追踪渲染 | width 默认 2048 | width ∈ [2048, 4096), threads ∈ [1,64] |
| 7 | **chaos_fractal** | 混沌游戏分形 (50M 迭代) | width 默认 2048 | width ∈ [2048, 4096), threads ∈ [1,64] |
| 8 | **deltablue** | 增量约束求解器 (DeltaBlue) | n 默认 100K 约束 | n ∈ [100K, 200K), threads ∈ [1,64] |
| 9 | **pyflate** | 纯 Python gzip/bzip2 解压 (BWT + Huffman) | size 默认 5MB | size ∈ [5M, 10M), threads ∈ [1,64] |
| 10 | **go_board_game** | 围棋 MCTS (蒙特卡洛树搜索) AI | size 默认 100 棋盘 | size ∈ [100, 200), threads ∈ [1,64] |
| 11 | **resnet50/inference** | ResNet50 推理 (PyTorch) | img_size 默认 256 | img_size ∈ [256, 512), threads ∈ [1,64] |
| 12 | **resnet50/training** | ResNet50 训练 (前向+反向+SGD) | img_size 默认 256 | img_size ∈ [256, 512), threads ∈ [1,64] |
| 13 | **bert/eval** | BERT Transformer 推理 | seq_len 默认 512 | seq_len ∈ [512, 1024), threads ∈ [1,64] |
| 14 | **transformer_inference** | Transformer Encoder-Decoder 推理 (24层) | seq_len 默认 128 | seq_len ∈ [128, 256), threads ∈ [1,64] |
| 15 | **transformer_train** | Transformer 训练 (12层 + Adam) | seq_len 默认 128 | seq_len ∈ [128, 256), threads ∈ [1,64] |

### 二、C/C++（20 个）

| # | Workload | 做什么 | 输入 | 参数空间 |
|---|----------|--------|------|----------|
| 16 | **ffmpeg** | FFmpeg 视频处理 (缩放+模糊+锐化) | duration 默认 240s | duration ∈ [240, 480), compiler ∈ {clang,gcc}, opt ∈ {-O1,-O2,-O3}, threads ∈ [1,64] |
| 17 | **redis** | Redis 多实例读写压测 | requests 默认 2M | requests ∈ [2M, 4M), opt ∈ {-O1,-O2,-O3}, threads ∈ [1,64] |
| 18 | **openssl** | AES-256-CBC + SHA-256/512 加密循环 | size 默认 25KB | size ∈ [25K, 50K), compiler ∈ {clang,gcc}, opt ∈ {-O1,-O2,-O3}, threads ∈ [1,64] |
| 19 | **zstd** | Zstd 压缩/解压 (level 19) | size 默认 25KB | size ∈ [25K, 50K), compiler ∈ {clang,gcc}, opt ∈ {-O1,-O2,-O3}, threads ∈ [1,64] |
| 20 | **gcc_compile** | 合成 C 代码 GCC 编译 (30文件×300函数) | func_size 默认 100 | func_size ∈ [100, 200), opt ∈ {O1,O2,O3}, threads ∈ [1,64] |
| 21 | **clang_compile** | 同上，用 Clang 编译 | func_size 默认 100 | func_size ∈ [100, 200), opt ∈ {O1,O2,O3}, threads ∈ [1,64] |
| 22 | **lapack/solve** | 稠密线性方程组 LU 分解 (dgesv) | size 默认 1024 | size ∈ [1024, 2048), compiler ∈ {clang,gcc}, opt ∈ {-O1,-O2,-O3}, threads ∈ [1,64] |
| 23 | **lapack/eigen** | 对称矩阵特征值分解 (dsyev) | size 默认 1024 | size ∈ [1024, 2048), compiler ∈ {clang,gcc}, opt ∈ {-O1,-O2,-O3}, threads ∈ [1,64] |
| 24 | **lapack/svd** | 稠密矩阵 SVD (dgesvd) | size 默认 1024 | size ∈ [1024, 2048), compiler ∈ {clang,gcc}, opt ∈ {-O1,-O2,-O3}, threads ∈ [1,64] |
| 25 | **rocksdb** | RocksDB 嵌入式 KV 存储 (写+读+Snappy压缩) | num 默认 2M 条 | num ∈ [2M, 4M), compiler ∈ {clang,gcc}, opt ∈ {-O1,-O2,-O3}, threads ∈ [1,64] |
| 26 | **opencv/fft_batch** | 图像批量 DFT 傅里叶变换 | size 默认 512 | size ∈ [512, 1024), compiler ∈ {clang,gcc}, opt ∈ {-O1,-O2,-O3}, threads ∈ [1,64] |
| 27 | **opencv/conv_heavy** | 大核高斯卷积 (模拟 CNN) | size 默认 512 | size ∈ [512, 1024), compiler ∈ {clang,gcc}, opt ∈ {-O1,-O2,-O3}, threads ∈ [1,64] |
| 28 | **opencv/mandelbrot** | Mandelbrot 分形 (逃逸时间算法) | size 默认 512 | size ∈ [512, 1024), compiler ∈ {clang,gcc}, opt ∈ {-O1,-O2,-O3}, threads ∈ [1,64] |
| 29 | **opencv/jacobi** | 2D Poisson PDE Jacobi 迭代求解 | size 默认 1024 | size ∈ [1024, 2048), compiler ∈ {clang,gcc}, opt ∈ {-O1,-O2,-O3}, threads ∈ [1,64] |
| 30 | **opencv/canny** | Canny 边缘检测 | size 默认 1024 | size ∈ [1024, 2048), compiler ∈ {clang,gcc}, opt ∈ {-O1,-O2,-O3}, threads ∈ [1,64] |
| 31 | **opencv/optical_flow** | 稠密光流 (Farneback) | size 默认 512 | size ∈ [512, 1024), compiler ∈ {clang,gcc}, opt ∈ {-O1,-O2,-O3}, threads ∈ [1,64] |
| 32 | **opencv/motion_blur** | 运动模糊 (对角线卷积) | size 默认 1024 | size ∈ [1024, 2048), compiler ∈ {clang,gcc}, opt ∈ {-O1,-O2,-O3}, threads ∈ [1,64] |
| 33 | **opencv/background_sub** | MOG2 背景减除 | size 默认 540 | size ∈ [540, 1080), compiler ∈ {clang,gcc}, opt ∈ {-O1,-O2,-O3}, threads ∈ [1,64] |
| 34 | **opencv/color_tracking** | HSV 颜色追踪 (腐蚀+膨胀) | size 默认 1080 | size ∈ [1080, 2160), compiler ∈ {clang,gcc}, opt ∈ {-O1,-O2,-O3}, threads ∈ [1,64] |
| 35 | **opencv/feature_match** | ORB 特征检测+暴力匹配 | size 默认 512 | size ∈ [512, 1024), compiler ∈ {clang,gcc}, opt ∈ {-O1,-O2,-O3}, threads ∈ [1,64] |

### 三、Java（7 个）

| # | Workload | 做什么 | 输入 | 参数空间 |
|---|----------|--------|------|----------|
| 36 | **guava/event** | 事件流聚合 (LinkedHashMultimap + HashMultiset) | dataSize 默认 100K | dataSize ∈ [100K, 200K), threads ∈ [1,64] |
| 37 | **guava/cache** | 并发缓存模拟 (热点/冷 key 模式) | dataSize 默认 50K | dataSize ∈ [50K, 100K), threads ∈ [1,64] |
| 38 | **guava/graph** | 有向图遍历 (BFS + 拓扑排序 + 环检测) | dataSize 默认 200K | dataSize ∈ [200K, 400K), threads ∈ [1,64] |
| 39 | **guava/bloom** | Bloom filter 插入+查询 + SHA-256/Murmur3 | dataSize 默认 200K | dataSize ∈ [200K, 400K), threads ∈ [1,64] |
| 40 | **guava/immutable** | 不可变集合快照+交集差集 | dataSize 默认 200K | dataSize ∈ [200K, 400K), threads ∈ [1,64] |
| 41 | **cassandra** | Cassandra NoSQL 读压测 (2M 读) | read-n 默认 1M | read-n ∈ [1M, 2M), threads ∈ [1,64] |
| 42 | **kafka** | Kafka 生产者压测 (10 亿条消息) | num-records 默认 700M | num-records ∈ [700M, 1400M), threads ∈ [1,64] |

### 四、Go（12 个）

| # | Workload | 做什么 | 输入 | 参数空间 |
|---|----------|--------|------|----------|
| 43 | **biogo/igor** | 基因组序列比对 (GFF 聚类) | seq 默认 50K | seq ∈ [50K, 100K), threads ∈ [1,64] |
| 44 | **bleve/index** | Bleve 全文索引 (Zipf 词频) | documents 默认 2000 | documents ∈ [2000, 4000), threads ∈ [1,64] |
| 45 | **cockroachdb/kv** | CockroachDB KV 事务 (1.2M/core) | max-ops 默认 600K | max-ops ∈ [600K, 1.2M), threads ∈ [1,64] |
| 46 | **cockroachdb/tpcc** | TPC-C OLTP 供应链模拟 | max-ops 默认 15K | max-ops ∈ [15K, 30K), threads ∈ [1,64] |
| 47 | **esbuild/ThreeJS** | 合成 JS 项目打包 (500 文件) | complexity 默认 1000 | complexity ∈ [1000, 2000), threads ∈ [1,64] |
| 48 | **esbuild/RomeTS** | 合成 TS 项目编译打包 | complexity 默认 1000 | complexity ∈ [1000, 2000), threads ∈ [1,64] |
| 49 | **gc_garbage** | Go GC 压力测试 (10 万行解析) | size 默认 50K 行 | size ∈ [50K, 100K), threads ∈ [1,64] |
| 50 | **go_compiler** | 合成 Go 包编译 (100 包) | complex 默认 100 | complex ∈ [100, 200), threads ∈ [1,64] |
| 51 | **gopher_lua** | Lua 解释器跑 k-nucleotide 生物信息 | size 默认 500K | size ∈ [500K, 1M), threads ∈ [1,64] |
| 52 | **go_json** | JSON 树结构序列化/反序列化 | size 默认 25KB | size ∈ [25K, 50K), threads ∈ [1,64] |
| 53 | **go_markdown** | Markdown→HTML 渲染 | size 默认 500B | size ∈ [500, 1000), threads ∈ [1,64] |
| 54 | **tile38/kdtree** | 地理空间 KD-Tree 查询 (KNN+范围+相交) | points 默认 50K | points ∈ [50K, 100K), threads ∈ [1,64] |

---

## 领域分布

| 领域 | 数量 | 代表 |
|------|------|------|
| 深度学习/ML | 5 | resnet×2, bert, transformer×2 |
| 线性代数/科学计算 | 7 | numpy×3, lapack×3, jacobi |
| 计算机视觉/图像 | 10 | opencv×10 + raytrace + chaos |
| 加密/安全 | 2 | openssl, tuf |
| 压缩 | 3 | pyflate, zstd, rocksdb(Snappy) |
| 编译/构建 | 4 | gcc, clang, go_compiler, esbuild×2 |
| 数据库/存储 | 5 | redis, rocksdb, cassandra, kv, tpcc |
| 序列化/解析 | 2 | requests-json, go_json |
| 约束求解/AI | 3 | deltablue, go-board-game, bleve |
| 消息/流 | 1 | kafka |
| 运行时/GC | 1 | gc_garbage |
| 数据结构/集合 | 5 | guava×5 |
| 视频/多媒体 | 1 | ffmpeg |
| 生物信息 | 2 | biogo, gopher_lua |
| 文本/标记 | 1 | go_markdown |
| 地理空间 | 1 | tile38 |

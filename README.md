# Filesystem Benchmark

A distributed filesystem benchmarking framework for evaluating storage performance across one or more Linux nodes.

The benchmark suite measures:

* Sequential write throughput (`dd`)
* Sequential read throughput (`dd`)
* Sequential write throughput (`fio`)
* Sequential read throughput (`fio`)
* Random write IOPS / bandwidth (`fio`)
* Random read IOPS / bandwidth (`fio`)
* Random write IOPS (`RandIo.py`)
* Random read IOPS (`RandIo.py`)
* File creation performance
* File open/read performance
* File removal performance

Results are collected from all benchmark nodes and automatically converted into:

* PNG performance plots
* Markdown reports
* PDF reports

## Features

* Multi-node benchmarking
* Shared filesystem testing (NFS, Lustre, BeeGFS, CephFS, Gluster, GPFS, etc.)
* Sequential and random I/O workloads
* Metadata performance tests
* Direct I/O or buffered I/O modes
* On-the-fly report generation
* Historical result preservation
* No third-party dependencies beyond standard distribution packages

## Configuration

Edit `setting.mk` to define:

* Benchmark nodes
* Mount point
* Test directory
* Workloads
* Workload sizes
* Number of concurrent tasks
* Direct or buffered I/O mode

Typical parameters include:

```make
Nodes           = node1 node2 node3
MountPoint      = /mnt/fs
TestDir         = filesystem-benchmark

Tasks           = 1 2 4 8 16

MBPerTask       = 1024
MBPerSeqIO      = 8

BytesPerRandIO  = 4096
RandRunSeconds  = 60

Direct          = 1
```

## Running Benchmarks

Initialize all nodes:

```bash
make init
```

Run the complete benchmark suite once:

```bash
make
```

The benchmark framework will:

1. Prepare worker nodes.
2. Execute all configured workloads.
3. Collect results.
4. Generate plots.
5. Produce a report.

## Available Workloads

### Sequential I/O (dd)

* SeqWriteDd
* SeqReadDd

Measures raw sequential throughput.

### Sequential I/O (fio)

* SeqWriteFio
* SeqReadFio

Measures throughput using fio with configurable I/O depth.

### Random I/O (fio)

* RandWriteFio
* RandReadFio

Measures random read/write performance.

### Random I/O (Python)

* RandWritePy
* RandReadPy

Measures random I/O performance using a lightweight Python workload generator.

### Metadata

* FileCreate
* FileOpen
* FileRemove

Measures filesystem metadata performance using large numbers of files.

## Generated Reports

After each benchmark run completes, the framework generates:

```
var/
├── report.md
├── report.pdf
└── plot/
```

## Cleaning Previous Runs

Remove benchmark data:

```bash
make clean
```

## Preserving Results

Completed runs are automatically renamed using timestamps:

```
var/test-2026-06-14T10:00:00
```

Allowing historical comparisons between benchmark runs with `bin/merge-multiple-benchmarks`

## Example Use Cases

### Compare Filesystems

* XFS
* EXT4
* ZFS
* Lustre
* BeeGFS
* CephFS

### Compare Storage Hardware

* HDD arrays
* SATA SSDs
* NVMe SSDs

### Compare Cluster Configurations

* Single-node storage
* Distributed filesystems
* Different network fabrics

## Output Metrics

Depending on workload type, results may be reported as:

* MiB/s
* Operations/second

## Author

[Manhong Dai](mailto:daimh@umich.edu)

Originally developed at the University of Michigan.

## License

MIT License

Copyright (c) 2016 The Regents of the University of Michigan

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

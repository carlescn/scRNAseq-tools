# SRA scripts

## get-fastq-dump.sh

### Description

  Downloads the [SRA-toolkit](https://github.com/ncbi/sra-tools/wiki/01.-Downloading-SRA-Toolkit)
  and creates a symlink to the fastq-dump executable.

### Arguments

- **`--bindir` (optional):**
  path to directory where fastq-dump executable should be saved.
  *Default: $PWD/bin*

### Example

```bash
get-fastq-dump.sh --bindir ./bin
```

## sra-to-cellranger-count.sh

### Description

  Downloads data from the SRA ID(s) provided
  and extracts the original FASTQ files from cellranger count.
  Only read 2 (CB+UMI), renamed to *_barcode.fastq
  and read 3 (cDNA), renamed to \*_cdna.fastq, are kept.
  Read 1 (GEM ID) is discarded.

### Dependencies

- fastq-dump executable from the [SRA-toolkit](https://github.com/ncbi/sra-tools/wiki/01.-Downloading-SRA-Toolkit).
  It can be obtained running the script `get-fastq-dump.sh`
  provided in this repository.

### Arguments

- **`--bin-dir` (optional):**
  path to directory containing the fastq-dump executable.
  *Default: $PWD/bin*
- **`--out-dir` (optional):**
  path to directory where the fastq files will be saved.
  *Default: $PWD/fastq*
- List of SRA IDs of the runs to download (space separated).

### Example

```bash
sra-to-cellranger-count.sh --bindir ./bin --outdir ./fastq SRR13839953 SRR13839961 SRR13839973
```

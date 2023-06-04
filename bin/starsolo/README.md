# STARsolo scripts

## starsolo-setup-linux-x86_64.sh

### Description

  Downloads the [STAR executable](https://github.com/alexdobin/STAR/)
  (for the Linux_x86_64 architecture)
  and the [whitelists from 10xGenomics](https://kb.10xgenomics.com/hc/en-us/articles/115004506263-What-is-a-barcode-whitelist-)
  for the chemistries v2 and v3,
  necessary to run the STARsolo algorithm.

### Arguments

- **`--bin-dir` (optional):**
  path to directory where the STAR executable should go.
  *Default: $PWD/bin*
- **`--wl-dir` (optional):**
  path to directory where the whitelists files should go.
  *Default: $PWD/star/whitelist*

### Example

```bash
starsolo-setup-linux-x86_64.sh --bindir ./bin --wldir ./star/whitelist/
```

## starsolo-gen-idx-danio-rerio.sh

### Description

  Generates the STAR genome indices
  (necessary to run the STARsolo algorithm)
  for the sp. Danio_rerio (zebrafish).

  This script downloads the reference genome GRCz11 from
  [ENSEMBL](https://www.ensembl.org/Danio_rerio/Info/Index).
  It expects the downloaded files to be GZ compressed.

  **WARNING:** this process consumes a lot for RAM!
  (about 30 GB for this particular genome).

  **Note:** The script could be easily modified
  for another species, reference genome or source.

### Dependencies

- [STAR executable](https://github.com/alexdobin/STAR),
  can be obtained running the script `starsolo-setup-linux-x86_64.sh`
  provided in this repository.

### Arguments

- **`--threads` (optional):**
  number of CPU threads use.
  *Default: max CPU threads available.*
- **`--bin-dir` (optional):**
  path to directory containing the STAR executable.
  *Default: $PWD/bin*
- **`--genome-dir` (optional):**
  path to directory where the genome references should be downloaded.
  *Default: $PWD/star/ENSEMBL*
- **`--index-dir` (optional):**
  path to directory where the generated indices should be stored.
  *Default: $PWD/star/danio_rerio_index*

### Example

```bash
starsolo-gen-idx-danio-rerio.sh --threads 8 --bindir ./bin --genomedir ./star/ENSEMBL --indexdir ./star/danio_rerio_index
```

## run-starsolo.sh

### Description

  Runs the STARsolo algorithm on the provided FASTQ files.
  It sets the the correct parameters for 10xGenomics chemistry v2 or v3.
  If the files are gzipped (\*.fastq.gz or \*.FASTQ.GZ),
  it automatically passes the correct option to STAR.
  Works with both trimmed and untrimmed (with the adapter sequences) files.

### Dependencies

- [STAR executable](https://github.com/alexdobin/STAR),
  can be obtained running the script `starsolo-setup-linux-x86_64.sh`
  provided in this repository.
- STAR genome index.
  It can be prepared by running the script `starsolo-gen-idx-danio-rerio.sh`
  provided in this repository
  (or a modified one).

### Arguments

- **`--chem [v2|v3]`:**
  version of the 10xGenomics chemistry used to prepare the libraries.
- **`--threads` (optional):**
  number of CPU threads use.
  *Default: max CPU threads available.*
- **`--bin-dir` (optional):**
  path to directory containing the STAR executable.
  *Default: $PWD/bin*
- **`--wl-dir` (optional):**
  path to directory where the whitelist files are located.
  *Default: $PWD/star/whitelist*
- **`--index-dir` (optional):**
  path to directory where the generated indices should be stored.
  *Default: $PWD/star/genome_index*
- **`--out-dir` (optional):**
  path to directory where the output files for STARsolo should be stored.
  *Default: $PWD/data/starsolo_out/*
- **`--read-dir` (optional):**
  path to directory where the input files are located.
  *Default: $PWD/data/fastq/*
- **`--manifest-path` (optional):**
  path to the manifest file.
  The manifest file must contain 3 tab-separated columns:
  cDNA.fastq [TAB] BarCode.fastq [TAB] ID
  where:
  - cDNA.fastq contains the cDNA reads,
  - BarCode.fastq contains the barcode reads (CB+UMI), and
  - ID is an arbitrary identifier name.
  *Default: $PWD/data/fastq/manifest*
- **`--run-individually`:**
  set to run one STARsolo instance for every line in the manifest.
  This outputs one count matrix for every line.
  Let it unset to run one STARsolo instance
  that reads all the files in the manifest
  and outputs only one count matrix.
  *Default (unset):*

### Example

```bash
run-starsolo.sh --chem v2 --threads 8 --bin-dir ./bin --index-dir ./star/danio_rerio_index --out-dir ./data/starsolo_out/ --read-dir ./data/fastq/ --manifest-path ./data/fastq/manifest
```

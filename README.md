# scRNAseq-tools

[![GPLv3 license](https://img.shields.io/badge/License-GPLv3.0-blue.svg)](https://github.com/carlescn/scRNAseq-tools/blob/main/LICENSE)
[![made-with-bash-5.1](https://img.shields.io/badge/Made%20with-Bash%205.1-1f425f.svg?logo=gnubash)](https://www.gnu.org/software/bash/)
[![Linux](https://img.shields.io/badge/OS-Linux-yellow.svg?logo=linux)](https://www.linux.org/)
[![STAR-2.7.9a](https://img.shields.io/badge/STAR-2.7.10b-darkgreen.svg)](https://github.com/alexdobin/STAR)

  This is a set of bash scripts I wrote 
  as a wrapper for [STAR](https://github.com/alexdobin/STAR/)
  to simplify it's setup 
  and for calling it with a set of pre-defined parameters.
  
- **`starsolo-setup-linux-x86_64.sh`**:
  downloads the [STAR executable](https://github.com/alexdobin/STAR/)
  and the [whitelists from 10xGenomics](https://kb.10xgenomics.com/hc/en-us/articles/115004506263-What-is-a-barcode-whitelist-).
- **`starsolo-gen-idx-danio-rerio.sh`**:
  downloads the referenge genome GRCz11 for the sp. Danio_rerio
  from [ENSEMBL](https://www.ensembl.org/Danio_rerio/Info/Index)
  and generates the STAR genome index.
- **`run-starsolo.sh`**:
  runs the STARsolo algorithm with some preset parameters.

Also, 
  I wrote a couple of scripts 
  for automatically downloading raw data files from the SRA repository 
  and extracting the original FASTQ files
  using the fastq-dump tool from
  [SRA-toolkit](https://github.com/ncbi/sra-tools/wiki/01.-Downloading-SRA-Toolkit),
  These FASTQ file should be equivalent to the output of
  [cellranger count](https://support.10xgenomics.com/single-cell-gene-expression/software/pipelines/latest/what-is-cell-ranger).

- **`get-fastq-dump.sh`:**
  downloads the tool fastq-dump from the
  [SRA-toolkit](https://github.com/ncbi/sra-tools/wiki/01.-Downloading-SRA-Toolkit).
- **`sra-to-cellranger-count.sh`:**
  downloads the raw data from the SRA repositories
  for the given ID(s) and extracts the original FASTQ files.

Finally,
  I wrote a script called `example.sh`,
  which is an example workflow that uses these scripts
  to download and setup all the tools,
  then downloads some data from the SRA repositories,
  extracts the original FASTQ files,
  and runs the STARsolo algorithm to obtain a cell-feature count matrix.

## starsolo-setup-linux-x86_64.sh

#### Description:

  Downloads the [STAR executable](https://github.com/alexdobin/STAR/)
  (for the Linux_x86_64 architecture)
  and the [whitelists from 10xGenomics](https://kb.10xgenomics.com/hc/en-us/articles/115004506263-What-is-a-barcode-whitelist-)
  for the chemistries v2 and v3,
  necessary to run the STARsolo algorithm.

#### Arguments:

- **`--bin-dir` (optional):**
  path to directory where the STAR executable should go.
  *Default: $PWD/bin*
- **`--wl-dir` (optional):**
  path to directory where the whitelists files should go.
  *Default: $PWD/star/whitelist*
  
#### Example:

```
starsolo-setup-linux-x86_64.sh --bindir ./bin --wldir ./star/whitelist/
```



## starsolo-gen-idx-danio-rerio.sh

#### Description:

  Generates the STAR genome indices
  (necessary to run the STARsolo algorithm)
  for the sp. Danio_rerio (zebrafish).

  This script downloads the referenge genome GRCz11 from 
  [ENSEMBL](https://www.ensembl.org/Danio_rerio/Info/Index).
  It expects the downloaded files to be GZ compressed.

  **WARNING:** this process consumes a lot for RAM!
  (about 30 GB for this particular genome).

  **Note:** The script could be easily modified
  for another species, reference genome or source.

#### Dependencies:

- [STAR executable](https://github.com/alexdobin/STAR),
  can be obtained running the script `starsolo-setup-linux-x86_64.sh`
  provided in this repository.

#### Arguments:

- **`--threads` (optional):** 
  number of CPU threads use.
  *Default: max CPU threads available.*
- **`--bin-dir` (optional):**
  path to directory containing the STAR executable.
  *Default: $PWD/bin*
- **`--genome-dir` (optional):**
  path to directory where the genome references should be downladed.
  *Default: $PWD/star/ENSEMBL*
- **`--index-dir` (optional):**
  path to directory where the generated indices should be stored.
  *Default: $PWD/star/danio_rerio_index*
  
#### Example:

```
starsolo-gen-idx-danio-rerio.sh --threads 8 --bindir ./bin --genomedir ./star/ENSEMBL --indexdir ./star/danio_rerio_index
```



## run-starsolo.sh

#### Description:

  Runs the STARsolo algorithm on the provided FASTQ files.
  It sets the the correct parameters for 10xGenomics chemistry v2 or v3.


#### Dependencies:

- [STAR executable](https://github.com/alexdobin/STAR),
  can be obtained running the script `starsolo-setup-linux-x86_64.sh`
  provided in this repository.
- STAR genome index.
  It can be prepared by running the script `starsolo-gen-idcx-danio-rerio.sh`
  provided in this repository
  (or a modified one).


#### Arguments:

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
  path to directory where the otput files for STARsolo should be stored.
  *Default: $PWD/data/starsolo_out/*
- **`--read-dir` (optional):** 
  path to directory where the input files are located.
  *Default: $PWD/data/fastq/*
- **`--manifest-path` (optional):** 
  path to the manifest file.
  The manifest file must cointain 3 tab-separated columns:
  
  Read2filename [TAB] Read1filename [TAB] ID
  - Read1 contain the cDNA reads, and
  - Read2 contain the barcode reads (CB+UMI).
  - ID is an arbitrary identifier name
  *Default: $PWD/data/fastq/manifest*
- **`--run-separated`:** 
  set to run one STARsolo instance for every line in the manifest.
  This outputs one count matrix for every line.
  Let it unset to run one STARsolo instance
  that reads all the files in the manifest
  and outputs only one count matrix.
  *Default (unset):*
  
#### Example:

```
run-starsolo.sh --chem v2 --threads 8 --bin-dir ./bin --index-dir ./star/danio_rerio_index --out-dir ./data/starsolo_out/ --read-dir ./data/fastq/ --manifest-path ./data/fastq/manifest
```
 

 
## get-fastq-dump.sh

#### Description:

  Downloads the [SRA-toolkit](https://github.com/ncbi/sra-tools/wiki/01.-Downloading-SRA-Toolkit)
  and creates a symlink to the fastq-dump executable.

#### Arguments:

- **`--bindir` (optional):**
  path to directory where fastq-dump executable should be saved.
  *Default: $PWD/bin*
  
#### Example:

```
get-fastq-dump.sh --bindir ./bin
```



## sra-to-cellranger-count.sh

#### Description:

  Downloads data from the SRA ID(s) provided
  and extracts the original FASTQ files from cellranger count.
  Only read 2 (CB+UMI) and read 3 (cDNA) are kept.
  Read 1 (GEM ID) is discarted.

#### Dependencies:
- fastq-dump executable from the [SRA-toolkit](https://github.com/ncbi/sra-tools/wiki/01.-Downloading-SRA-Toolkit).
  It can be obtained running the script `get-fastq-dump.sh`
  provided in this repository.

#### Arguments:

- **`--bin-dir` (optional):**
  path to directory containing the fastq-dump executable.
  *Default: $PWD/bin*
- **`--out-dir` (optional):**
  path to directory where the fastq files will be saved.
  *Default: $PWD/fastq*
- List of SRA IDs of the runs to download (space separated).
  
#### Example:

```
sra-to-cellranger-count.sh --bindir ./bin --outdir ./fastq SRR13839953 SRR13839961 SRR13839973
```

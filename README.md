# scRNAseq-tools

[![GPLv3 license](https://img.shields.io/badge/License-GPLv3.0-blue.svg)](https://github.com/carlescn/scRNAseq-tools/blob/main/LICENSE)
[![made-with-bash-5.1](https://img.shields.io/badge/Made%20with-Bash%205.1-1f425f.svg?logo=gnubash)](https://www.gnu.org/software/bash/)
[![Linux](https://img.shields.io/badge/OS-Linux-yellow.svg?logo=linux)](https://www.linux.org/)
[![STAR-2.7.9a](https://img.shields.io/badge/STAR-2.7.10b-darkgreen.svg)](https://github.com/alexdobin/STAR)

## STARsolo scripts

This is a set of bash scripts I wrote
as a wrapper for [STARsolo](https://github.com/alexdobin/STAR/blob/master/docs/STARsolo.md)
to simplify it's setup
and for running it with a set of parameters
which try to replicate the output of
[10x Genomics Cell Ranger](https://support.10xgenomics.com/single-cell-gene-expression/software/pipelines/latest/what-is-cell-ranger).

The scripts are located under the directory `./bin/starsolo`
([see documentation](/bin/starsolo/README.md)):

- **`starsolo-setup-linux-x86_64.sh`**:
  downloads the [STAR executable](https://github.com/alexdobin/STAR/)
  and the [whitelists from 10xGenomics](https://kb.10xgenomics.com/hc/en-us/articles/115004506263-What-is-a-barcode-whitelist-).
- **`starsolo-gen-idx-danio-rerio.sh`**:
downloads the reference genome GRCz11 for the sp. Danio_rerio
  from [ENSEMBL](https://www.ensembl.org/Danio_rerio/Info/Index)
  and generates the STAR genome index.
- **`run-starsolo.sh`**:
  runs the STARsolo algorithm with some preset parameters.

## SRA scripts

Because I needed some experiment data to test the STARsolo scripts,
I also wrote a couple of scripts
to obtain FASTQ files from the
[SRA repository](https://www.ncbi.nlm.nih.gov/sra/docs/).

These download the raw data files from the SRA repository
and extract the original FASTQ files
using the `fastq-dump` tool from
[SRA-toolkit](https://github.com/ncbi/sra-tools/wiki/01.-Downloading-SRA-Toolkit).
The obtained FASTQ files should be equivalent to the output of
[cellranger count](https://support.10xgenomics.com/single-cell-gene-expression/software/pipelines/latest/what-is-cell-ranger).

The scripts are located under the directory `./bin/sra`
([see documentation](/bin/sra/README.md)):

- **`get-fastq-dump.sh`:**
  downloads the tool fastq-dump from the
  [SRA-toolkit](https://github.com/ncbi/sra-tools/wiki/01.-Downloading-SRA-Toolkit).
- **`sra-to-cellranger-count.sh`:**
  downloads the raw data from the SRA repositories
  for the given ID(s) and extracts the original FASTQ files.

## Workflow example

Finally,
I provide a workflow example
(`workflow_example.sh`)
that uses all these scripts to:

1. Download and setup all the tools.
1. Download some example data from the SRA repositories.
1. Run STARsolo to obtain a cell-feature count matrix.

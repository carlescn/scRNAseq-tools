#!/usr/bin/env bash

# -e script ends on error (exit != 0)
# -u error if undefined variable
# -o pipefail script ends if piped command fails
set -euo pipefail

# Example script that downloads the necessary tools and generates the STAR genome index for Danio_rerio,
# then downloads the raw data from three scRNA-seq runs from the SRA repository and runs STARsolo
# to obtain the cell-feature count matrix.
# The data comes from an experiment by Tatarakis D, Cang Z, Wu X, Sharma PP et al. (2021),
# available at the GEO repositories with the accession GSE168133.

# The scrips can be obtained from the github repository https://github.com/carlescn/scRNAseq-tools:
# This script assumes they have been already downloaded and stored in the following directory:
readonly path_to_scripts="./bin"


# Prepare the folder structure
# This script will use the default paths for the rest of the scripts, when possible
#mkdir ./bin  # It is assumed this directory already exist and cointains the script files
mkdir -p ./star/ENSEMBL
mkdir -p ./star/danio_rerio_index
mkdir -p ./star/whitelist
mkdir -p ./data/fastq
mkdir -p ./data/starsolo_out/


# Get the necessary tools and create the STAR genome indices (ONLY NECESSARY THE FIRST TIME!)
# Get the STAR executable
"$path_to_scripts"/starsolo-setup-linux-x86_64.sh
# Get the fastq-dump executable
"$path_to_scripts"/get-fastq-dump.sh
# Create the STAR genome indices for Danio_rerio
"$path_to_scripts"/starsolo-gen-idx-danio-rerio.sh

# Get the experiment data
IDs="SRR13839953 SRR13839961 SRR13839973"
"$path_to_scripts"/sra-to-cellranger-count.sh "$IDs"

# Create the manifest file
readonly manifest_file="./data/fastq/manifest"
[[ -f $manifest_file ]] && rm "$manifest_file"
for id in $IDs; do
    echo -e "$id""_cdna.fastq\t""$id""_barcode.fastq\t""$id" >> "$manifest_file"
done

echo "Manifest file:"
cat $manifest_file

# Execute the STARsolo algorithm: get the cell-feature count matrix.
"$path_to_scripts"/run-starsolo.sh --chem v2
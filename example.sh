#!/bin/bash

# Example script that downloads the necessary tools and generates the STAR genome index for Danio_rerio,
# then downloads the raw data from three scRNA-seq runs from the SRA repository and runs STARsolo
# to obtain the cell-feature count matrix.
# The data comes from an experiment by Tatarakis D, Cang Z, Wu X, Sharma PP et al. (2021),
# available at the GEO repositories with the accession GSE168133.

# The scrips can be obtained from the github repository https://github.com/carlescn/scRNAseq-tools:
# This script assumes they have been already downloaded and stored in the following directory:
path_to_scripts="./bin"


## Prepare the folder structure
# This script will use the default paths for the rest of the scripts, when possible
#mkdir ./bin  # It is assumed this directory already exist and cointains the script files
mkdir ./star
mkdir ./star/ENSEMBL
mkdir ./star/danio_rerio_idx
mkdir ./star/whitelist
mkdir ./data
mkdir ./data/fastq
mkdir ./data/starsolo_out/


## Get the necessary tools and create the STAR genome indices (RUN ONLY THE FIRST TIME!)
# Get the STAR executable
$path_to_scripts/starsolo-setup-linux-x86_64.sh
# Get the fastq-dump executable
$path_to_scripts/get-fastq-dump.sh
# Create the STAR genome indices for Danio_rerio
$path_to_scripts/starsolo-gen-idx-danio-rerio.sh --index-dir ./star/danio_rerio_index

## Get the experiment data
IDs="SRR13839953 SRR13839961 SRR13839973"
$path_to_scripts/sra-to-cellranger-count.sh $IDs


## Execute the STARsolo algorithm: get the cell-feature count matrix.
manifest_file="./data/fastq/manifest"
rm $manifest_file
for id in $IDs; do
  echo -e $id"_3.fastq\t"$id"_2.fastq\t-" >> $manifest_file
done

echo "Manifest file:"
cat $manifest_file

$path_to_scripts/run-starsolo.sh --chem v2 --index-dir ./star/danio_rerio_index


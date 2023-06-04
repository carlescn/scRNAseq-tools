#!/usr/bin/env bash

###################################################################
# Script Name : sra-to-cellranger-count.sh
# Description : Downloads data from the SRA ID(s) provided and extracts
#               the original FASTQ files from cellranger count.
#               Only read 2 (CB+UMI), renamed to *_barcode.fastq
#               and read 3 (cDNA), renamed to *_cdna.fastq, are kept.
# Dependencies: fastq-dump executable from the SRA-toolkit. Can be
#               obtained running the get-fastq-dump.sh script provided
#               in this repository.
# Args        : --bin-dir (optional): path to directory containing
#                 the fastq-dump executable.
#                 Default: $PWD/bin
#               --out-dir (optional): path to directory where the
#                 fastq files will be saved.
#                 Default: $PWD/fastq
#               List of SRA IDs of the runs to download, space separated
# Example     : sra-to-cellranger-count.sh --bindir ./bin --outdir ./fastq SRR13839953 SRR13839961 SRR13839973
# Author      : CarlesCN
# E-mail      : carlesbioinformatics@gmail.com
# License     : GNU General Public License v3.0
###################################################################

# -e script ends on error (exit != 0)
# -u error if undefined variable
# -o pipefail script ends if piped command fails
set -euo pipefail

readonly usage_msg="USAGE: sra-to-cellranger-count.sh [--bin-dir /path/to/bin/dir] [--out-dir /path/to/output/dir] ID1 [ID2] [...]"

# READ ARGUMENTS
# Set the default paths (if arguments are not provided)
fastqdump_path="$PWD/bin/fastq-dump"
out_dir="$PWD/data/fastq"

# Read the arguments
for arg in "$@"; do
    case $arg in
        -h|--help) echo "$usage_msg" &&            exit 0       ;;
        --bin-dir) fastqdump_path="$2/fastq-dump"; shift; shift ;;
        --out-dir) out_dir=$2;                     shift; shift ;;
    esac
done
readonly fastqdump_path out_dir

readonly sra_id_list=("$@")

# SOME CHECKS
# Check if fast-dump executable exists
error_message="ERROR: $fastqdump_path not found. Check the --bin-dir argument."
[[ ! -f $fastqdump_path ]] && echo "$error_message" && exit 1

# Check if the output directory exists, and create it if necessary
error_message="ERROR: $out_dir already exists but is a file (should be a directory). Check the --outd-ir argument."
[[ -f $out_dir ]] && echo "$error_message" && exit 1
[[ -d $out_dir ]] || mkdir -p "$out_dir"

# Check that the files list is not empty
error_message="ERROR: List of files is empty. Did you provide any arguments?"
[[ ${#sra_id_list[@]} == 0 ]] && echo -e "$error_message\n$usage_msg" && exit 1

# DOWNLOAD AND EXTRACT THE FILES
cd "$out_dir"

for file in "${sra_id_list[@]}"; do
    wget "https://sra-pub-run-odp.s3.amazonaws.com/sra/$file/$file"
    echo "Extracting .fastq files with fastq-dump..."
    "$fastqdump_path" --split-files "$file"
    rm "$file" "$file"_1.fastq
    mv "$file"_2.fastq "$file"_barcode.fastq
    mv "$file"_3.fastq "$file"_cdna.fastq
done

exit 0
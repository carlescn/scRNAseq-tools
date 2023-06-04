#!/usr/bin/env bash

###################################################################
# Script Name : run-starsolo.sh
# Description : Runs the STARsolo algorithm on the provided FASTQ files.
#               It sets the the correct parameters for 10xGenomics
#               chemistry v2 or v3.
#               If the files are in the format FASTQ.GZ, it automatically
#               passes the correct option to STAR.
#               It needs a generated STAR genome index. It can be prepared
#               by running the script starsolo-gen-idcx-danio-rerio.sh
#               provided in this repository (or a modified one).
# Dependencies: STAR executable (https://github.com/alexdobin/STAR)
#               can be obtained running the starsolo-setup-linux-x86_64.sh
#               script provided in this repository.
# Args        : --chem [v2|v3]: version of the 10xGenomics chemistry
#                 used to prepare the libraries.
#               --threads (optional): number of CPU threads use.
#                 Default: max CPU threads available.
#               --bin-dir (optional): path to directory containing
#                 the STAR executable.
#                 Default: $PWD/bin
#               --wl-dir (optional): path to directory where the
#                 whitelist files are located.
#                 Default: $PWD/star/whitelist
#               --index-dir (optional): path to directory where the
#                 generated indices should be stored.
#                 Default: $PWD/star/danio_rerio_index
#               --out-dir (optional): path to directory where the
#                 otput files for STARsolo should be stored.
#                 Default: $PWD/data/starsolo_out/
#               --read-dir (optional): path to directory where the
#                 input files are located.
#                 Default: $PWD/data/fastq/
#               --manifest-path (optional): path to the manifest file.
#                 The manifest file must cointain 3 tab-separated columns:
#                 cDNAfilename [TAB] BarCodefilename [TAB] ID
#                   where:
#                   cDNAfilename contains the cDNA reads (read2 on 10x), and
#                   BarCodefilename contains the barcode reads (CB+UMI) (read1 on 10x),
#                   ID is an arbitrary identifier name.
#                 Default: $PWD/data/fastq/manifest
#               --run-individually: set to run one STARsolo instance for
#                 every line in the manifest. Outputs one count matrix
#                 for every line.
#                 Default (unset): run one STARsolo instance that
#                 reads all the files in the manifest and outputs
#                 only one count matrix.
# Example     : run-starsolo.sh --chem v2 --threads 8 --bin-dir ./bin --index-dir ./star/danio_rerio_index --out-dir ./data/starsolo_out/ --read-dir ./data/fastq/ --manifest-path ./data/fastq/manifest
# Author      : CarlesCN
# E-mail      : carlesbioinformatics@gmail.com
# License     : GNU General Public License v3.0
###################################################################

# -e script ends on error (exit != 0)
# -u error if undefined variable
# -o pipefail script ends if piped command fails
set -euo pipefail

readonly usage_msg="USAGE: run-starsolo.sh --chem [v2|v3] [--threads numberOfCores] [--bin-dir /path/to/bin/dir/] [--wl-dir /path/to/whitelist/dir/] [--index-dir /path/to/index/dir/] [--out-dir /path/to/output/dir/] [--read-dir /path/to/read/dir/] [--manifest-path /path/to/manifest/file] [--run-individually]"

# READ ARGUMENTS
# Set the default arguments (if not provided)
star_path="$PWD/bin/STAR"
wl_dir="$PWD/star/whitelist"
index_dir="$PWD/star/danio_rerio_index"
out_dir="$PWD/data/starsolo_out"
read_dir="$PWD/data/fastq"
manifest_path="$read_dir/manifest"
max_threads=$(nproc --all)
threads=$max_threads
run_individually=FALSE
chem=""

# Read the arguments
for arg in "$@"; do
    case $arg in
        -h|--help)          echo "$usage_msg" &&   exit 0       ;;
        --chem)             chem=$2;               shift; shift ;;
        --bin-dir)          star_path="$2/STAR";   shift; shift ;;
        --wl-dir)           wl_dir=$2;             shift; shift ;;
        --index-dir)        index_dir=$2;          shift; shift ;;
        --out-dir)          out_dir=$2;            shift; shift ;;
        --read-dir)         read_dir=$2;           shift; shift ;;
        --manifest-path)    manifest_path=$2;      shift; shift ;;
        --threads)          threads=$2;            shift; shift ;;
        --run-individually) run_individually=TRUE; shift        ;;
    esac
done
readonly chem star_path wl_dir index_dir out_dir read_dir manifest_path

# SOME CHECKS
# Check if STAR executable and manifest file exist
message="ERROR: $star_path not found. Check the --bin-dir argument."
[[ ! -f $star_path ]] && echo "$message" && exit 1

message="ERROR: $manifest_path not found. Check the --manifest-path argument."
[[ ! -f $manifest_path ]] && echo "$message" && exit 1

# Check if the directories exist and create them if possible
message="ERROR: $index_dir doesn't exist or isn't a directory. Check the --index-dir argument."
[[ ! -d $index_dir ]] && echo "$message" && exit 1

message="ERROR: $read_dir doesn't exist or isn't a directory. Check the --read-dir argument."
[[ ! -d $read_dir ]] && echo "$message" && exit 1

message="ERROR: $out_dir already exists but is a file (should be a directory). Check the --out-dir argument."
[[ -f $out_dir ]] && echo "$message" && exit 1
[[ -d $out_dir ]] || mkdir -p "$out_dir"

# Check the number of threads against the machine max
message="Number of threads $threads exceeds this machine capacity ($max_threads CPU threads). Setting to $max_threads."
[[ $threads > $max_threads ]] && threads=$max_threads && echo "$message"
readonly threads

# STARsolo won't run with the --readFilesManifest option if it has only one line
[[ $(wc -l < "$manifest_path") == 1 ]] && run_individually=TRUE
readonly run_individually

## RUN THE STARsolo ALGORITHM
# Description of arguments passed to STAR:
# (for reference, see: https://github.com/alexdobin/STAR/raw/master/doc/STARmanual.pdf )
# --runThreadN [NUM]: number of CPU threads to use.
# --soloType CB_UMI_Simple: execute the STARsolo algorithm for files with one CB and one UMI per read.
# --soloCBstart 1: start position for the CB part of the barcode (valid for chemistry v2 and v3).
# --soloCBlen 16: lenght of the CB part of the barcode (valid for chemistry v2 and v3).
# --soloUMIstart 17: start position for the UMI part of the barcode (valid for chemistry v2 and v3).
# --soloUMIlen [10|12]: lenght of the the UMI part of the barcode (10 for v2, 12 for v3).
# --soloCBwhitelist [FILE]: file containing the 10xGenmoics barcode whitelist for the corresponding chemistry.
# --soloBarcodeReadLength 0: don't check the length of the reads on BarCodefilename. Use when processing untrimmed FASTQ files, containing the PCR adapters (not only the CB+UMI)
# --genomeDir [DIR]: directory containing the genome indices
# --outFileNamePrefix [STR]: string that will be prefixed to the output files. In this script, is used to set an output directory.
# --outSAMtype None: don't output a SAM file containing the aligned reads. We only want the cell-feature count matrix.
# --readFilesPrefix [STR]: string that is prefixed to the input files. In this script, is used to set an input directory.
# --readFilesManifest [FILE]: file containing the filenames of the FASTQ files to read.
# --readFilesCommand zcat: must use when FASTQ files are GZ compressed.

# Set the correct arguments for chemistry v2 or v3
case $chem in
    "v2")
        barcode=("--soloCBstart 1 --soloCBlen 16 --soloUMIstart 17 --soloUMIlen 10")
        whitelist_file="$wl_dir/737K-august-2016.txt"
        ;;
    "v3")
        barcode=("--soloCBstart 1 --soloCBlen 16 --soloUMIstart 17 --soloUMIlen 12")
        whitelist_file="$wl_dir/3M-february-2018.txt"
        ;;
    *)
        echo "--chem argument is unset or not a valid chemistry."
        exit 1
        ;;
esac
readonly barcode whitelist_file

# Set the options for STARsolo
starsolo_options=()
starsolo_options+=("--runThreadN $threads")
starsolo_options+=("--soloType CB_UMI_Simple")
starsolo_options+=("$barcode")
starsolo_options+=("--soloCBwhitelist $whitelist_file")
starsolo_options+=("--soloBarcodeReadLength 0")
starsolo_options+=("--genomeDir $index_dir")
starsolo_options+=("--outSAMtype None")
starsolo_options+=("--readFilesPrefix $read_dir/")

# Check if first file in manifest is GZ compressed, and set the appropriate option
first_file="$(awk -F"\t" '{print $1; exit}' "$manifest_path")"; readonly first_file
[[ $first_file == *.fastq.gz ]] && starsolo_options+=("--readFilesCommand zcat")
[[ $first_file == *.FASTQ.GZ ]] && starsolo_options+=("--readFilesCommand zcat")

if [[ $run_individually == TRUE ]]; then
    # Run one instance of the STARsolo algorithm for each line of the manifest
    while read -r line; do
    IFS=$'\t' read -r -a line_array <<< "$line" # Separate $line fields using separator=TAB, store in array $line_array
        starsolo_options+=("--outFileNamePrefix $out_dir\_${line_array[2]}/")
        starsolo_options+=("--readFilesIn ${line_array[0]} ${line_array[1]}")
        $star_path "${starsolo_options[@]}"
    done < "$manifest_path"
else
    # Run the STARsolo algorithm for the full manifest
    starsolo_options+=("--outFileNamePrefix $out_dir/")
    starsolo_options+=("--readFilesManifest $manifest_path")
    $star_path "${starsolo_options[@]}"
fi

exit 0
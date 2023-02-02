#!/usr/bin/env bash

###################################################################
# Script Name : starsolo-gen-idx-danio-rerio.sh
# Description : Generates the STAR genome indices (necessary to run the
#               STARsolo algorithm) for the sp. Danio_rerio (zebrafish).
#               This script downloads the referenge genome GRCz11
#               from ENSEMBL.
#               It expects the downloaded files to be GZ compressed.
#               WARNING: this process consumes a lot for RAM!
#               (about 30 GB for this particular genome).
#               Note: The script could be easily modified for
#               another species, reference genome or source.
# Dependencies: STAR executable (https://github.com/alexdobin/STAR)
#               can be obtained running the starsolo-setup-linux-x86_64.sh
#               script provided in this repository.
# Args        : --threads (optional): number of CPU threads use.
#                 Default: max CPU threads available.
#               --bin-dir (optional): path to directory containing
#                 the STAR executable.
#                 Default: $PWD/bin
#               --genome-dir (optional): path to directory where the
#                 genome references should be downladed.
#                 Default: $PWD/star/ENSEMBL
#               --index-dir (optional): path to directory where the
#                 generated indices should be stored.
#                 Default: $PWD/star/danio_rerio_index
# Example     : starsolo-gen-idx-danio-rerio.sh --threads 8 --bindir ./bin --genomedir ./star/ENSEMBL --indexdir ./star/danio_rerio_index
# Author      : CarlesCN
# E-mail      : carlesbioinformatics@gmail.com
# License     : GNU General Public License v3.0
###################################################################

# -e script ends on error (exit != 0)
# -u error if undefined variable
# -o pipefail script ends if piped command fails
set -euo pipefail

# BEGIN CONFIG: you can change the genome references here
readonly gen_fasta_url="https://ftp.ensembl.org/pub/release-108/fasta/danio_rerio/dna/Danio_rerio.GRCz11.dna.primary_assembly.fa.gz"
readonly gen_gtf_url="https://ftp.ensembl.org/pub/release-108/gtf/danio_rerio/Danio_rerio.GRCz11.108.gtf.gz"
# END CONFIG

readonly usage_msg="USAGE: starsolo-gen-idx-danio-rerio.sh [--threads numberOfCores] [--bin-dir /path/to/bin/dir] [--genome-dir /path/to/genome/dir] [--index-dir /path/to/index/dir]"

# READ ARGUMENTS
# Set the default paths (if arguments are not provided)
star_path="$PWD/bin/STAR"
genome_dir="$PWD/star/ENSEMBL"
index_dir="$PWD/star/danio_rerio_index"
# Set the max number of threads
max_threads=$(nproc --all); readonly max_threads
threads="$max_threads"

# Read the arguments
for arg in "$@"; do
    case $arg in
        -h|--help)    echo "$usage_msg" && exit 0       ;;
        --threads)    threads=$2;          shift; shift ;;
        --bin-dir)    star_path="$2/STAR"; shift; shift ;;
        --genome-dir) genome_dir=$2;       shift; shift ;;
        --index-dir)  index_dir=$2;        shift; shift ;;
    esac
done
readonly star_path genome_dir index_dir

# SOME CHECKS
# Check if STAR executable exists
error_message="ERROR: $star_path not found. Check the --bin-dir argument."
[[ ! -f $star_path ]] && echo "$error_message" && exit 1

# Check if the directories exist, and create them if necessary
error_message="ERROR: $genome_dir already exists but is a file (should be a directory). Check the --genome-dir argument."
[[ -f $genome_dir ]]  && echo "$error_message" && exit 1
[[ -d $genome_dir ]] || mkdir -p "$genome_dir"

error_message="ERROR: $index_dir already exists but is a file (should be a directory). Check the --index-dir argument."
[[ -f $index_dir ]]  && echo "$error_message" && exit 1
[[ -d "$index_dir" ]] || mkdir -p "$index_dir"

# Check the number of threads against the machine max
message="Number of threads $threads exceeds this machine capacity ($max_threads CPU threats). Setting to $max_threads."
[[ $threads > $max_threads ]] && threads=$max_threads && echo "$message"
readonly threads

# GENERATE THE STAR GENOME INDEX
# Set the (compressed) file names
gen_fasta_gz="$genome_dir/$(basename "$gen_fasta_url")"; readonly gen_fasta_gz
gen_gtf_gz="$genome_dir/$(basename "$gen_gtf_url")";     readonly gen_gtf_gz
readonly gen_fasta="${gen_fasta_gz%.gz}"
readonly gen_gtf="${gen_gtf_gz%.gz}"

# Download the reference genome
wget --output-document "$gen_fasta_gz" "$gen_fasta_url"
wget --output-document "$gen_gtf_gz" "$gen_gtf_url"
gunzip "$gen_fasta_gz"
gunzip "$gen_gtf_gz"

# Generate the index (this consumes a lot of RAM!)
"$star_path" --runThreadN "$threads" --runMode genomeGenerate --genomeDir "$index_dir" --genomeFastaFiles "$gen_fasta" --sjdbGTFfile "$gen_gtf"

# Uncomment to remove the reference genome (no longer necessary)
# rm -r "$genome_dir"

exit 0
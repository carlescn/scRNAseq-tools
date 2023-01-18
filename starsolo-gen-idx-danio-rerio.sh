#!/bin/bash

###################################################################
#Script Name : starsolo-gen-idx-danio-rerio.sh
#Description : Generates the STAR genome indices (necessary to run the
#              STARsolo algorithm) for the sp. Danio_rerio (zebrafish).
#              This script downloads the referenge genome GRCz11 
#              from ENSEMBL.
#              It expects the downloaded files to be GZ compressed.
#              WARNING: this process consumes a lot for RAM!
#              (about 30 GB for this particular genome).
#              Note: The script could be easily modified for
#              another species, reference genome or source.
#Dependencies: STAR executable (https://github.com/alexdobin/STAR)
#              can be obtained running the starsolo-setup-linux-x86_64.sh
#              script provided in this repository.
#Args        : --threads (optional): number of CPU threads use.
#                Default: max CPU threads available.
#              --bin-dir (optional): path to directory containing
#                the STAR executable.
#                Default: $PWD/bin
#              --genome-dir (optional): path to directory where the
#                genome references should be downladed.
#                Default: $PWD/star/ENSEMBL
#              --index-dir (optional): path to directory where the
#                generated indices should be stored.
#                Default: $PWD/star/danio_rerio_index
#Author      : CarlesCN
#E-mail      : drtlof@gmail.com
#Example     : starsolo-gen-idx-danio-rerio.sh --threads 8 --bindir ./bin --genomedir ./star/ENSEMBL --indexdir ./star/danio_rerio_index
###################################################################
# CONFIG: you can change the genome references here
gen_fasta_url="https://ftp.ensembl.org/pub/release-108/fasta/danio_rerio/dna/Danio_rerio.GRCz11.dna.primary_assembly.fa.gz"
gen_gtf_url="https://ftp.ensembl.org/pub/release-108/gtf/danio_rerio/Danio_rerio.GRCz11.108.gtf.gz"
###################################################################

usage_msg="USAGE: starsolo-gen-idx-danio-rerio.sh [--threads numberOfCores] [--bin-dir /path/to/bin/dir] [--genome-dir /path/to/genome/dir] [--index-dir /path/to/index/dir]"

# Exit the script if any command exits non-zero status
set -e

## READ ARGUMENTS
# Set the default paths (if arguments are not provided)
star_path="$PWD/bin/STAR"
genome_dir="$PWD/star/ENSEMBL"
index_dir="$PWD/star/danio_rerio_index"
# Set the max number of threads
max_threads=$(nproc --all)
threads=$max_threads

# Read the arguments
for arg in "$@"; do
  case $arg in
    -h | --help)
      echo $usage_msg
      exit 0
      ;;
    --threads)
      threads=$2
      shift
      shift
      ;;  
    --bin-dir)
      star_path="$2/STAR"
      shift
      shift
      ;;
    --genome-dir)
      genome_dir=$2
      shift
      shift
      ;;
    --index-dir)
      index_dir=$2
      shift
      shift
      ;; 
  esac
done


## SOME CHECKS
# Check if STAR executable exists
if [[ ! -f $star_path ]]; then
  echo "ERROR: $star_path not found. Check the --bin-dir argument."
  exit 1
fi

# Check if the directories exist, and create them if necessary
if [[ -f $genome_dir ]]; then
  echo "ERROR: $genome_dir already exists but is a file (should be a directory). Check the --genome-dir argument."
  exit 1
elif [[ ! -d $genome_dir ]]; then
  mkdir -p $genome_dir
fi

if [[ -f $index_dir ]]; then
  echo "ERROR: $index_dir already exists but is a file (should be a directory). Check the --index-dir argument."
  exit 1
elif [[ ! -d $index_dir ]]; then
  mkdir -p $index_dir
fi

# Check the number of threads against the machine max
if [[ $threads > $max_threads ]]; then
  echo "Number of threads $threads exceeds this machine capacity ($max_threads CPU threats). Setting to $max_threads."
  threads=$max_threads
fi


# GENERATE THE STAR GENOME INDEX
# Set the (compressed) file names
gen_fasta_gz=$(basename $gen_fasta_url)
gen_gtf_gz=$(basename $gen_gtf_url)
gen_fasta="${gen_fasta_gz%.gz}"
gen_gtf="${gen_gtf_gz%.gz}"

# Download the reference genome
wget --output-document $genome_dir/$gen_fasta_gz $gen_fasta_url
wget --output-document $genome_dir/$gen_gtf_gz $gen_gtf_url
gunzip $genome_dir/$gen_fasta_gz
gunzip $genome_dir/$gen_gtf_gz

# Generate the index (this consumes a lot of RAM!)
$star_path --runThreadN $threads --runMode genomeGenerate --genomeDir $index_dir --genomeFastaFiles $genome_dir/$gen_fasta --sjdbGTFfile $genome_dir/$gen_gtf

# Remove the reference genome (no longer necessary)
rm -r $genome_dir

exit 0

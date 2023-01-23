#!/bin/bash

###################################################################
#Script Name : sra-to-cellranger-count.sh
#Description : Downloads data from the SRA ID(s) provided and extracts
#              the original FASTQ files from cellranger count. 
#              Only read 2 (CB+UMI), renamed to *_barcode.fastq
#              and read 3 (cDNA), renamed to *_cdna.fastq, are kept.
#Dependencies: fastq-dump executable from the SRA-toolkit. Can be
#              obtained running the get-fastq-dump.sh script provided
#              in this repository.
#Args        : --bin-dir (optional): path to directory containing
#                the fastq-dump executable.
#                Default: $PWD/bin
#              --out-dir (optional): path to directory where the
#                fastq files will be saved.
#                Default: $PWD/fastq
#              List of SRA IDs of the runs to download, space separated
#Author      : CarlesCN
#E-mail      : drtlof@gmail.com
#Example     : sra-to-cellranger-count.sh --bindir ./bin --outdir ./fastq SRR13839953 SRR13839961 SRR13839973
###################################################################

usage_msg="USAGE: sra-to-cellranger-count.sh [--bin-dir /path/to/bin/dir] [--out-dir /path/to/output/dir] ID1 [ID2] [...]"

# Exit the script if any command exits non-zero status
set -e


## READ ARGUMENTS
# Set the default paths (if arguments are not provided)
fd_path="$PWD/bin/fastq-dump"
out_dir="$PWD/data/fastq"

# Read the arguments
for arg in "$@"; do
  case $arg in
    -h | --help)
      echo $usage_msg
      exit 0
      ;;
    --bin-dir)
      fd_path="$2/fastq-dump"
      shift
      shift
      ;;
    --out-dir)
      out_dir=$2
      shift
      shift
      ;;   
  esac
done
sra_id_list=$@


## SOME CHECKS
# Check if fast-dump executable exists
if [[ ! -f $fd_path ]]; then
  echo "ERROR: $fd_path not found. Check the --bin-dir argument."
  exit 1
fi

# Check if the output directory exists, and create it if necessary
if [[ -f $out_dir ]]; then
  echo "ERROR: $out_dir already exists but is a file (should be a directory). Check the --outd-ir argument."
  exit 1
elif [[ ! -d $out_dir ]]; then
  mkdir -p $out_dir
fi

# Check that the files list is not empty
if [[ -z $sra_id_list ]]; then
  echo "ERROR: List of files is empty. Did you provide any arguments?"
  echo $usage_msg
  exit 1
fi


## DOWNLOAD AND EXTRACT THE FILES
cd $out_dir

for file in $sra_id_list; do
  wget "https://sra-pub-run-odp.s3.amazonaws.com/sra/$file/$file"
  echo "Extracting .fastq files with fastq-dump..."
  $fd_path --split-files $file
  rm $file $file\_1.fastq
  mv $file\_2.fastq $file\_barcode.fastq
  mv $file\_3.fastq $file\_cdna.fastq
done

exit 0

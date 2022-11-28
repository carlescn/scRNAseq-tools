#!/bin/bash

###################################################################
#Script Name : sra-to-cellranger-count.sh
#Description : Simple script for downloading SRA files and extracting
#              the original FASTQ files from cellranger count. 
#              Only read 2 (CB+UMI) and read 3 (cDNA) are kept.
#Dependencies: fastq-dump executable from the SRA-toolkit. Can be
#            : obtained running the get-fastq-dump.sh script.
#Args        : --bindir (optional): path to directory containing
#            :   the fastq-dump executable. Defaults to $PWD/bin
#            : --outdir (optional): path to directory where the
#            :   fastq files will be saved. Defaults to $PWD/fastq
#            : SRA run IDs of the files to download, space separated
#Author      : CarlesCN
#E-mail      : drtlof@gmail.com
#Example     : sra-to-cellranger-count.sh --bindir ./bin --outdir ./fastq SRR13839953 SRR13839961 SRR13839973
###################################################################

# Exit the script if any command exits non-zero status
set -e


usage_msg="USAGE: sra-to-cellranger-count.sh [--bindir /path/to/bin/dir] [--outdir /path/to/output/dir] FILE1 [FILE2] [...]"

## READ ARGUMENTS
# Set the default paths (if arguments not provided)
fd_path="$PWD/bin/fastq-dump"
out_dir="$PWD/fastq"

# Set the paths from arguments
for arg in "$@"; do
  case $arg in
    -h | --help)
      echo $usage_msg
      exit 0
      ;;
    --bindir)
      fd_path="$2/fastq-dump"
      shift
      shift
      ;;
    --outdir)
      out_dir=$2
      shift
      shift
      ;;   
  esac
done

# Set the list of SRA IDs from arguments
sra_list=$@


## SOME CHECKS
# Check if fast-dump executable exists in the set path
if [[ ! -f $fd_path ]]; then
  echo "ERROR: $fd_path not found. Check the --bindir argument."
  exit 1
fi

# Check if the output directory exists, and create it if necessary
if [[ -f $out_dir ]]; then
  echo "ERROR: $out_dir already exists and is a file (should be a directory). Check the --outdir argument."
  exit 1
elif [[ ! -d $out_dir ]]; then
  mkdir $out_dir
fi

# Check that the files list is not empty
if [[ -z $sra_list ]]; then
  echo "ERROR: List of files is empty. Did you provide any arguments?"
  echo $usage_msg
  exit 1
fi


## DOWNLOAD AND EXTRACT THE FILES
cd $out_dir

for file in $sra_list; do
  wget "https://sra-pub-run-odp.s3.amazonaws.com/sra/$file/$file"
  $fd_path --split-files $file
  rm $file $file\_1.fastq
done

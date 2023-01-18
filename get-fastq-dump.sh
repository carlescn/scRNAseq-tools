#!/bin/bash

###################################################################
#Script Name : get-fastq-dump.sh
#Description : Downloads the SRA-tooolkit and creates a symlink
#              to the fastq-dump executable.
#Args        : --bindir (optional): path to directory containing
#                where fastq-dump executable should be saved.
#                Default: $PWD/bin
#Author      : CarlesCN
#E-mail      : drtlof@gmail.com
#Example     : get-fastq-dump.sh --bindir ./bin
###################################################################

usage_msg="USAGE: get-fastq-dump.sh [--bindir /path/to/bin/dir]"

## READ ARGUMENTS
# Set the default paths (if arguments are not provided)
bin_dir="$PWD/bin"

# Read the arguments
case $1 in
  -h | --help)
    echo $usage_msg
    exit 0
    ;;
  --bindir)
    bin_dir=$2
    ;;
  *)
    echo "Argument --bin-dir not provided. Setting to the default value: $bin_dir"
    ;;
esac

# Check if the directory exists, and create it if necessary
if [[ -f $bin_dir ]]; then
  echo "ERROR: $bin_dir already exists but is a file (should be a directory). Check the --bindir argument."
  exit 1
elif [[ ! -d $bin_dir ]]; then
  mkdir -p $bin_dir
fi

# Get the SRA-toolkit and symlink to the fastq-dump executable
wget --output-document sratoolkit.tar.gz https://ftp-trace.ncbi.nlm.nih.gov/sra/sdk/current/sratoolkit.current-ubuntu64.tar.gz
tar -xzf sratoolkit.tar.gz
rm sratoolkit.tar.gz
mv sratoolkit.3.0.1-ubuntu64/ "$bin_dir/"
ln -s sratoolkit.3.0.1-ubuntu64/bin/fastq-dump "$bin_dir/fastq-dump"

exit 0

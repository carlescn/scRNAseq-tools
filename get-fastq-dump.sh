#!/bin/bash

###################################################################
#Script Name : get-fastq-dump.sh
#Description : Simple script for downloading the SRA-tooolkit and 
#              creating a symlink to the fastq-dump executable.
#Args        : --bindir (optional): path to directory containing
#            :   where fastq-dump executable should be located.
#                Defaults to $PWD/bin
#Author      : CarlesCN
#E-mail      : drtlof@gmail.com
#Example     : get-fastq-dump.sh --bindir ./bin
###################################################################

# Help message
if [[ $1 == "-h" || $1 == "--help" ]]; then
  echo "USAGE: get-fastq-dump.sh [--bindir /path/to/bin/dir]"
  exit 0
fi

# Check if --bindir argument is provided and the path is a valid directory
if [[ $1 == "--bindir" ]]; then
  bin_dir=$2
else
  bin_dir="$PWD/bin"
  echo "Argument --bindir not provided. Directory set to the default value: $bin_dir"
fi

# Check if the directory exists, and create it if necessary
if [[ -f $bin_dir ]]; then
  echo "ERROR: $bin_dir already exists and is a file (should be a directory). Check the --bindir argument."
  exit 1
elif [[ ! -d $bin_dir ]]; then
  mkdir $bin_dir
fi

# Get the SRA-toolkit and symlink to the fastq-dump executable
wget --output-document sratoolkit.tar.gz https://ftp-trace.ncbi.nlm.nih.gov/sra/sdk/current/sratoolkit.current-ubuntu64.tar.gz
tar -xzf sratoolkit.tar.gz
rm sratoolkit.tar.gz
mv sratoolkit.3.0.1-ubuntu64/ "$bin_dir/"
ln -s sratoolkit.3.0.1-ubuntu64/bin/fastq-dump "$bin_dir/fastq-dump"

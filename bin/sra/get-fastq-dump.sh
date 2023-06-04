#!/usr/bin/env bash

###################################################################
# Script Name : get-fastq-dump.sh
# Description : Downloads the SRA-tooolkit and creates a symlink
#               to the fastq-dump executable.
# Args        : --bindir (optional): path to directory containing
#                 where fastq-dump executable should be saved.
#                 Default: $PWD/bin
# Example     : get-fastq-dump.sh --bindir ./bin
# Author      : CarlesCN
# E-mail      : carlesbioinformatics@gmail.com
# License     : GNU General Public License v3.0
###################################################################

# -e script ends on error (exit != 0)
# -u error if undefined variable
# -o pipefail script ends if piped command fails
set -euo pipefail

readonly usage_msg="USAGE: get-fastq-dump.sh [--bindir /path/to/bin/dir]"

# READ ARGUMENTS
# Set the default paths (if arguments are not provided)
bin_dir="$PWD/bin"

# Read the arguments
message="Argument --bin-dir not provided. Setting to the default value: $bin_dir"
case $1 in
    -h|--help) echo "$usage_msg" && exit 0 ;;
    --bindir)  bin_dir=$2                  ;;
    *)         echo "$message"             ;;
esac
readonly bin_dir

# Check if the directory exists, and create it if necessary
error_message="ERROR: $bin_dir already exists but is a file (should be a directory). Check the --bindir argument."
[[ -f $bin_dir ]] && echo "$error_message" && exit 1
[[ -d $bin_dir ]] || mkdir -p "$bin_dir"

# Get the SRA-toolkit and symlink to the fastq-dump executable
wget --output-document "sratoolkit.tar.gz" "https://ftp-trace.ncbi.nlm.nih.gov/sra/sdk/current/sratoolkit.current-ubuntu64.tar.gz"
tar -xzf "sratoolkit.tar.gz"
rm "sratoolkit.tar.gz"
mv "sratoolkit.3.0.1-ubuntu64/" "$bin_dir/"
ln -s "sratoolkit.3.0.1-ubuntu64/bin/fastq-dump" "$bin_dir/fastq-dump"

exit 0
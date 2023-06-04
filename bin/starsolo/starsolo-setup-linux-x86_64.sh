#!/usr/bin/env bash

###################################################################
# Script Name : starsolo-setup-linux-x86_64.sh
# Description : Downloads STAR executable for Linux x86_64,
#               and the whitelists from 10xGenomics necessary to
#               run the STARsolo algorithm
# Args        : --bin-dir (optional): path to directory where the
#                 STAR executable should go.
#                 Default: $PWD/bin
#               --wl-dir (optional): path to directory where the
#                 whitelists files should go.
#                 Default: $PWD/star/whitelist
# Example     : starsolo-setup-linux-x86_64.sh --bindir ./bin --wldir ./star/whitelist/
# Author      : CarlesCN
# E-mail      : carlesbioinformatics@gmail.com
# License     : GNU General Public License v3.0
###################################################################

# -e script ends on error (exit != 0)
# -u error if undefined variable
# -o pipefail script ends if piped command fails
set -euo pipefail

readonly usage_msg="USAGE: starsolo-setup-linux-x86_64.sh [--bin-dir /path/to/bin/dir] [--wl-dir /path/to/whitelist/dir]"

# READ ARGUMENTS
# Set the default paths (if arguments are not provided)
bin_dir="$PWD/bin"
wl_dir="$PWD/star/whitelist"

# Read the arguments
for arg in "$@"; do
    case $arg in
        -h|--help) echo "$usage_msg" && exit 0 ;;
        --bin-dir) bin_dir=$2;   shift; shift  ;;
        --wl-dir)  wl_dir=$2;    shift; shift  ;;
    esac
done
readonly bin_dir wl_dir

# SOME CHECKS
# Check if the directories exist, and create them if necessary
error_message="ERROR: $bin_dir already exists but is a file (should be a directory). Check the --bin-dir argument."
[[ -f $bin_dir ]] && echo "$error_message" && exit 1
[[ -d $bin_dir ]] || mkdir -p "$bin_dir"

error_message="ERROR: $wl_dir already exists but is a file (should be a directory). Check the --wl-dir argument."
[[ -f $wl_dir ]] && echo "$error_message" && exit 1
[[ -d $wl_dir ]] || mkdir -p "$wl_dir"

# DOWNLOAD THE NECESSARY FILES
# Download the STAR executable
star_url="https://github.com/alexdobin/STAR/releases/download/2.7.10b/STAR_2.7.10b.zip"
star_zip="STAR_2.7.10b.zip"
star_folder="STAR_2.7.10b/Linux_x86_64"
wget --output-document="./bin/$star_zip" "$star_url"
unzip "$bin_dir/$star_zip" -d "$bin_dir"
rm "$bin_dir"/"$star_zip"
ln -s "$bin_dir/$star_folder/STAR" "$bin_dir/STAR"
chmod +x "$bin_dir/STAR"

# Download the 10xGenomics whitelists
# Chemistry v2
wget --output-document "$wl_dir"/737K-august-2016.txt  https://raw.githubusercontent.com/10XGenomics/cellranger/master/lib/python/cellranger/barcodes/737K-august-2016.txt
# Chemistri v3
wget --output-document "$wl_dir"/3M-february-2018.txt.gz https://github.com/10XGenomics/cellranger/raw/master/lib/python/cellranger/barcodes/3M-february-2018.txt.gz
gunzip "$wl_dir"/3M-february-2018.txt.gz

exit 0
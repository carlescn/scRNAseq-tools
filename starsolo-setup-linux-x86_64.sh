#!/bin/bash

###################################################################
#Script Name : starsolo-setup-linux-x86_64.sh
#Description : Downloads STAR executable for Linux x86_64,
#              and the whitelists from 10xGenomics necessary to
#              run the STARsolo algorithm
#Args        : --bin-dir (optional): path to directory where the
#                STAR executable should go.
#                Default: $PWD/bin
#              --wl-dir (optional): path to directory where the
#                whitelists files should go.
#                Default: $PWD/star/whitelist
#Author      : CarlesCN
#E-mail      : drtlof@gmail.com
#Example     : starsolo-setup-linux-x86_64.sh --bindir ./bin --wldir ./star/whitelist/
###################################################################

usage_msg="USAGE: starsolo-setup-linux-x86_64.sh [--bin-dir /path/to/bin/dir] [--wl-dir /path/to/whitelist/dir]"

# Exit the script if any command exits non-zero status
set -e


## READ ARGUMENTS
# Set the default paths (if arguments are not provided)
bin_dir="$PWD/bin"
wl_dir="$PWD/star/whitelist"

# Read the arguments
for arg in "$@"; do
  case $arg in
    -h | --help)
      echo $usage_msg
      exit 0
      ;;
    --bin-dir)
      bin_dir=$2
      shift
      shift
      ;;
    --wl-dir)
      wl_dir=$2
      shift
      shift
      ;;   
  esac
done


## SOME CHECKS
# Check if the directories exist, and create them if necessary
if [[ -f $bin_dir ]]; then
  echo "ERROR: $bin_dir already exists but is a file (should be a directory). Check the --bin-dir argument."
  exit 1
elif [[ ! -d $bin_dir ]]; then
  mkdir -p $bin_dir
fi

if [[ -f $wl_dir ]]; then
  echo "ERROR: $wl_dir already exists but is a file (should be a directory). Check the --wl-dir argument."
  exit 1
elif [[ ! -d $wl_dir ]]; then
  mkdir -p $wl_dir
fi


## DOWNLOAD THE NECESSARY FILES
# Download the STAR executable
star_url="https://github.com/alexdobin/STAR/releases/download/2.7.10b/STAR_2.7.10b.zip"
star_zip="STAR_2.7.10b.zip"
star_folder="STAR_2.7.10b/Linux_x86_64"
wget --output-document=./bin/$star_zip $star_url
unzip $bin_dir/$star_zip -d $bin_dir
rm $bin_dir/$star_zip
ln -s $bin_dir/$star_folder/STAR $bin_dir/STAR
chmod +x $bin_dir/STAR

# Download the 10xGenomics whitelists
# Chemistry v2
wget --output-document $wl_dir/737K-august-2016.txt  https://raw.githubusercontent.com/10XGenomics/cellranger/master/lib/python/cellranger/barcodes/737K-august-2016.txt
# Chemistri v3
wget --output-document $wl_dir/3M-february-2018.txt.gz https://github.com/10XGenomics/cellranger/raw/master/lib/python/cellranger/barcodes/3M-february-2018.txt.gz
gunzip $wl_dir/3M-february-2018.txt.gz

exit 0

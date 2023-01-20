#!/bin/bash

###################################################################
#Script Name : run-starsolo.sh
#Description : Runs the STARsolo algorithm on the provided FASTQ files.
#              It sets the the correct parameters for 10xGenomics
#              chemistry v2 or v3.
#              If the files are in the format FASTQ.GZ, it automatically
#              passes the correct option to STAR.
#              It needs a generated STAR genome index. It can be prepared
#              by running the script starsolo-gen-idcx-danio-rerio.sh
#              provided in this repository (or a modified one).
#Dependencies: STAR executable (https://github.com/alexdobin/STAR)
#              can be obtained running the starsolo-setup-linux-x86_64.sh
#              script provided in this repository.
#Args        : --chem [v2|v3]: version of the 10xGenomics chemistry
#                used to prepare the libraries.
#              --threads (optional): number of CPU threads use.
#                Default: max CPU threads available.
#              --bin-dir (optional): path to directory containing
#                the STAR executable.
#                Default: $PWD/bin
#              --wl-dir (optional): path to directory where the
#                whitelist files are located.
#                Default: $PWD/star/whitelist
#              --index-dir (optional): path to directory where the
#                generated indices should be stored.
#                Default: $PWD/star/danio_rerio_index
#              --out-dir (optional): path to directory where the
#                otput files for STARsolo should be stored.
#                Default: $PWD/data/starsolo_out/
#              --read-dir (optional): path to directory where the
#                input files are located.
#                Default: $PWD/data/fastq/
#              --manifest-path (optional): path to the manifest file.
#                The manifest file must cointain 3 tab-separated columns:
#                Read2filename [TAB] Read1filename [TAB] ID
#                Read1 contain the cDNA reads, and
#                Read2 contain the barcode reads (CB+UMI).
#                ID is an arbitrary identifier name
#                Default: $PWD/data/fastq/manifest
#              --run-individually: set to run one STARsolo instance for
#                every line in the manifest. Outputs one count matrix
#                for every line.
#                Default (unset): run one STARsolo instance that
#                reads all the files in the manifest and outputs 
#                only one count matrix.
#Author      : CarlesCN
#E-mail      : drtlof@gmail.com
#Example     : run-starsolo.sh --chem v2 --threads 8 --bin-dir ./bin --index-dir ./star/danio_rerio_index --out-dir ./data/starsolo_out/ --read-dir ./data/fastq/ --manifest-path ./data/fastq/manifest
###################################################################

usage_msg="USAGE: run-starsolo.sh --chem [v2|v3] [--threads numberOfCores] [--bin-dir /path/to/bin/dir/] [--wl-dir /path/to/whitelist/dir/] [--index-dir /path/to/index/dir/] [--out-dir /path/to/output/dir/] [--read-dir /path/to/read/dir/] [--manifest-path /path/to/manifest/file] [--run-individually]"

# Exit the script if any command exits non-zero status
set -e


## READ ARGUMENTS
# Set the default paths (if arguments ar not provided)
star_path="$PWD/bin/STAR"
wl_dir="$PWD/star/whitelist"
index_dir="$PWD/star/danio_rerio_index"
out_dir="$PWD/data/starsolo_out"
read_dir="$PWD/data/fastq"
manifest_path="$read_dir/manifest"
# Set the max number of threads
max_threads=$(nproc --all)
threads=$max_threads
# Set the --run-individually flag
run_individually=FALSE

# Read the arguments
for arg in "$@"; do
  case $arg in
    -h | --help)
      echo $usage_msg
      exit 0
      ;;
    --chem)
      chem=$2
      shift
      shift
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
    --wl-dir)
      wl_dir=$2
      shift
      shift
      ;;
    --index-dir)
      index_dir=$2
      shift
      shift
      ;;
    --out-dir)
      out_dir=$2
      shift
      shift
      ;;
    --read-dir)
      read_dir=$2
      shift
      shift
      ;;
    --manifest-path)
      manifest_path=$2
      shift
      shift
      ;;
    --run-individually)
      run_individually=TRUE
      shift
      ;;
  esac
done


## SOME CHECKS
# Check if STAR executable and manifest file exist
if [[ ! -f $star_path ]]; then
  echo "ERROR: $star_path not found. Check the --bin-dir argument."
  exit 1
fi

if [[ ! -f $manifest_path ]]; then
  echo "ERROR: $manifest_path not found. Check the --manifest-path argument."
  exit 1
fi

# Check if the directories exist and create them if possible
if [[ ! -d $index_dir ]]; then
  echo "ERROR: $index_dir doesn't exist or isn't a directory. Check the --index-dir argument."
  exit 1
fi

if [[ ! -d $read_dir ]]; then
  echo "ERROR: $read_dir doesn't exist or isn't a directory. Check the --read-dir argument."
  exit 1
fi

if [[ -f $out_dir ]]; then
  echo "ERROR: $out_dir already exists but is a file (should be a directory). Check the --out-dir argument."
  exit 1
elif [[ ! -d $out_dir ]]; then
  mkdir -p $out_dir
fi

# Check the number of threads against the machine max
if [[ $threads > $max_threads ]]; then
  echo "Number of threads $threads exceeds this machine capacity ($max_threads CPU threads). Setting to $max_threads."
  threads=$max_threads
fi

# STARsolo won't run with the --readFilesManifest option if it has only one line
if [[ $(wc -l < $manifest_path) == 1 ]]; then
  run_individually=TRUE
fi


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
# --soloBarcodeReadLength 0: don't check the length of read2. Useful when processing raw FASTQ files containing the adapters (not only the CB+UMI)
# --genomeDir [DIR]: directory containing the genome indices
# --outFileNamePrefix [STR]: string that will be prefixed to the output files. In this script, is used to set an output directory.
# --outSAMtype None: don't output a SAM file containing the aligned reads. We only want the cell-feature count matrix.
# --readFilesPrefix [STR]: string that is prefixed to the input files. In this script, is used to set an input directory.
# --readFilesManifest [FILE]: file containing the filenames of the FASTQ files to read.
# --readFilesCommand zcat: must use when FASTQ files are GZ compressed.

# Set the correct arguments for chemistry v2 or v3
case $chem in
  "v2")
    barcode="--soloCBstart 1 --soloCBlen 16 --soloUMIstart 17 --soloUMIlen 10"
    whitelist_file="$wl_dir/737K-august-2016.txt"
    ;;
  "v3")
    barcode="--soloCBstart 1 --soloCBlen 16 --soloUMIstart 17 --soloUMIlen 12"
    whitelist_file="$wl_dir/3M-february-2018.txt"
    ;;
  *)
    echo "$chem is not a valid chemistry. Check the --chem argument."
    exit 1
    ;;
esac

# Check if first file in manifest is GZ compressed, and set the appropriate option
read first_line < $manifest_path
first_file=($first_line)
if [[ $first_file == *.fastq.gz ]] || [[ $first_file == *.FASTQ.GZ ]]; then
  unzip_file="--readFilesCommand zcat"
else
  unzip_file=""
fi

common_options="--runThreadN $threads --soloType CB_UMI_Simple $barcode --soloCBwhitelist $whitelist_file --soloBarcodeReadLength 0 --genomeDir $index_dir --outSAMtype None --readFilesPrefix $read_dir/ $unzip_file"

echo $common_options

if [[ $run_individually == TRUE ]]; then
  # Run one instance of the STARsolo algorithm for each line of the manifest
  while read line; do
  line_array=($line)

  read2=${line_array[0]}
  read1=${line_array[1]}
  out_dir_sep=$out_dir"_${line_array[2]}"

  $star_path $common_options --outFileNamePrefix $out_dir_sep/  --readFilesIn $read2 $read1
  done < $manifest_path
else
  # Run the STARsolo algorithm for the full manifest
  $star_path $common_options --outFileNamePrefix $out_dir/  --readFilesManifest $manifest_path
fi

exit 0

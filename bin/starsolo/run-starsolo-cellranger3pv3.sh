#!/usr/bin/env bash

###################################################################
# Script Name : run-starsolo-cellranger3pv3
# Description : Runs the STARsolo algorithm on the provided FASTQ files,
#               Setting the correct parameters for 10x Genomics chemistry 3' v3
#               and for reproducing the output of CellRanger.
#               It auomatically detects if the input files ar GZ compressed.
# Dependencies: Requires the STAR executable (https://github.com/alexdobin/STAR)
#               and a pre-computed STAR genome index.
#               Both can be obtained running the following scripts,
#               provided in this repository:
#               - starsolo-setup-linux-x86_64.sh (onbtain STAR)
#               - starsolo-gen-idcx-danio-rerio.sh (generate gnome index)
# Author      : CarlesCN
# E-mail      : carlesbioinformatics@gmail.com
# License     : GNU General Public License v3.0
###################################################################

###################################################################
# IMPORTANT NOTE
# This script uses the STARsolo option "--soloCellFilter EmptyDrops CR".
# The STAR manual asks to cite the original EmptyDrops paper when using this option:
# A.T.L Lun et al, Genome Biology, 20, 63 (2019)
# https://genomebiology.biomedcentral.com/articles/10.1186/s13059-019-1662-y
###################################################################


# SET INTERPRETER OPTIONS

## -e: script ends on any error (exit != 0)
## -u: raise error if an undefined variable is called
## -o pipefail: script ends if piped command fails
set -euo pipefail


# SET THE SCRIPT PARAMETERS

## Paths
base_dir="$PWD"

star_path="$base_dir/bin/STAR"
wlist_dir="$base_dir/star/whitelist"
genome_dir="$base_dir/star/danio_rerio_index"
output_dir="$base_dir/data/starsolo_out"
input_dir="$base_dir/data/fastq"
manifest_path="$input_dir/manifest"

## Number of CPU threads
threads=$(nproc --all) # set max threads for this machine
# threads=4            # or set manually

## Wether to run each file individually or all files in a single run
run_individually=true


# SET THE PARAMETERS FOR STARsolo
# (see https://github.com/alexdobin/STAR/blob/master/doc/STARmanual.pdf)
starsolo_params=()

### Generic
starsolo_params+=("--runThreadN" "$threads")
starsolo_params+=("--soloType"   "CB_UMI_Simple")

### Chemistry 3' v3
starsolo_params+=("--soloBarcodeReadLength" "0")
starsolo_params+=("--soloCBstart"     "1")
starsolo_params+=("--soloCBlen"       "16")
starsolo_params+=("--soloUMIstart"    "17")
starsolo_params+=("--soloUMIlen"      "12")
starsolo_params+=("--soloStrand"      "Forward")
starsolo_params+=("--soloCBwhitelist" "$wlist_dir/3M-february-2018.txt")

### Reproduce CellRanger output
soloFeatures="Gene GeneFull"
starsolo_params+=("--soloFeatures"      "$soloFeatures")
starsolo_params+=("--soloUMIdedup"      "1MM_CR")
starsolo_params+=("--soloUMIfiltering"  "MultiGeneUMI_CR")
starsolo_params+=("--soloCBmatchWLtype" "1MM_multi_Nbase_pseudocounts")
starsolo_params+=("--clipAdapterType"   "CellRanger4")
starsolo_params+=("--outFilterScoreMin" "30")
starsolo_params+=("--soloMultiMappers"  "EM")
starsolo_params+=("--soloCellFilter"    "EmptyDrops_CR")
#### Note:
#### Option EmptyDrops_CR can be followed by 10 numeric parameters (The harcoded values below are from CellRanger):
#### ExpectedCells  maxPercentile  maxMinRatio  indMin  indMax  umiMin  umiMinFracMedian  candMaxN  FDR   simN
#### 3000           0.99           10           45000   90000   500     0.01              20000     0.01  10000

### Input / output
starsolo_params+=("--genomeDir"       "$genome_dir")
starsolo_params+=("--outSAMtype"      "None")
starsolo_params+=("--readFilesPrefix" "$input_dir/")

### Set output subdirs (for GZ compressing the output files)
output_subdirs=()
for subdir in $soloFeatures; do
    output_subdirs+=("/Solo.out/$subdir/filtered")
    output_subdirs+=("/Solo.out/$subdir/raw")
done


# PERFORM SOME CHECKS

## STAR executable and manifest file exist
for file in $star_path $manifest_path; do
    [[ ! -f $file ]] && echo "ERROR: $file not found." && exit 1
done

## Directories exist (create them if possible)
for dir in $input_dir $genome_dir $wlist_dir; do
    [[ ! -d $dir ]] && echo "ERROR: $dir doesn't exist or isn't a directory." && exit 1
done

[[ -f $output_dir ]] && echo "ERROR: $output_dir is a file but should be a directory." && exit 1
[[ -d $output_dir ]] || mkdir -p "$output_dir"

## Number of threads is valid
max_threads=$(nproc --all)
[[ $threads > $max_threads ]] && threads=$max_threads && echo "WARNING: 'threads' is set too high. Resetting to this machine's max: $max_threads."

## Wether FASTQ files are GZ compressed
first_file="$(awk -F"\t" '{print $1; exit}' "$manifest_path")";
[[ $first_file == *.gz ]] && starsolo_params+=("--readFilesCommand zcat")
[[ $first_file == *.GZ ]] && starsolo_params+=("--readFilesCommand zcat")

## Force to run individually if manifest has only one line (otherwise STARsolo won't run)
[[ $(wc -l < "$manifest_path") == 1 ]] && run_individually=true


# RUN STARsolo

if $run_individually; then
    # Run one instance of STARsolo for each line in the manifest
    while read -r line_string; do
        ## Read each line, split string into array using TAB as separator
        IFS=$'\t' read -r -a line_array <<< "$line_string"

        read_cDNA="${line_array[0]}"
        read_BC="${line_array[1]}"
        read_id="${line_array[2]}"

        ## Set input and output params
        output_dir_ind="$output_dir/$read_id"
        starsolo_params+=("--outFileNamePrefix $output_dir_ind/")
        starsolo_params+=("--readFilesIn $read_cDNA $read_BC")

        ## Run STARsolo
        $star_path "${starsolo_params[@]}"

        ## GZ compress output files (same as CellRanger)
        for subdir in "${output_subdirs[@]}"; do
            gzip "$output_dir_ind/$subdir/*"
        done
    done < "$manifest_path"

else
    # Run a single STARsolo instance with all the files in the manifest
    ## Set input and output params
    starsolo_params+=("--outFileNamePrefix $output_dir/")
    starsolo_params+=("--readFilesManifest $manifest_path")

    ## Run STARsolo
    $star_path "${starsolo_params[@]}"

    ## GZ compress output files (same as CellRanger)
    for subdir in "${output_subdirs[@]}"; do
        gzip "$output_dir/$subdir/*"
    done
fi


exit 0
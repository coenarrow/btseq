# This script runs the example, similar to btseq, but on our hpc system, with some modifications along the way

#!/bin/bash
if [ "$1" = "" ]; then
    echo "Run name is missing. Exiting"
        exit 1
fi

# add the present working directory to the path
export PATH=$PATH:$(pwd)
SCRIPT_DIR=$(pwd)/kaya_scripts

# set the directory to run. This directory contains the .fastq files and "sample_sheet.txt"
dir=$1

# First run prepare_trim on our directory
jid2=$(sbatch --job-name=prep_trim --output=prep_trim.out --partition='pophealth' $SCRIPT_DIR/prepare_trim.sh $dir)
jid2=${jid2:20}
jid3=$(sbatch --job-name=prepare_align --dependency=afterany:$jid2 --partition='pophealth' --output=prep_aln.out $SCRIPT_DIR/prepare_align.sh)
jid3=${jid3:20}
# sbatch --dependency=afterany:$jid3 --job-name=run --output=run.out btseq_run
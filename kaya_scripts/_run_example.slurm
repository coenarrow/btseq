#!/bin/bash

if [ "$1" = "" ]; then
    echo "Run name is missing. Exiting"
        exit 1
fi

# Define the directory as the first argument
# This directory contains all the fastq files and "sample_sheet.txt"
d=$1

export PATH=${PATH}:/group/pgh004/carrow/repo/btseq/
source /group/pgh004/carrow/repo/btseq/btseq_setup
jid1=$(sbatch --job-name=gr get_reads $1)
jid1=${jid1:20}
jid2=$(sbatch --job-name=pt --dependency=afterany:$jid1 --output=prep_trim.out btseq_prepare_trim)
jid2=${jid2:20}
jid3=$(sbatch --job-name=pa --dependency=afterany:$jid2 --output=prep_aln.out btseq_prepare_align)
jid3=${jid3:20}
sbatch --dependency=afterany:$jid3 --job-name=run --output=run.out btseq_run






 # Load system modules first
module load cuda/11.8
module load Anaconda3/2023.09

# This is to load the extra modules that are required for btseq
export MODULEPATH=/group/pgh004/carrow/repo/btseq/modulefiles:$MODULEPATH
module load bioinfo
module load cutadapt
module load trim-galore

# list the loaded modules
module list

if [ "$1" = "" ]; then
    echo "Run name is missing. Exiting"
        exit 1
fi

# 1. setup - prepare relevant input files for downstream analysis - fasta files for each sample-target pair, bc_ss.csv, BSTarget_input.txt.
# Add the btseq scripts to the path (it also runs the R script)
export PATH=${PATH}:/group/pgh004/carrow/repo/btseq/scripts
source /group/pgh004/carrow/repo/btseq/scripts/btseq_setup

# 2. (Optional) get_reads - extract fastq.gz files from BCL directory (will fail but not disrupt pipeline if no BCL input given).
    # We don't need to run get_reads if we already have them as fastqz files
    # jid1=$(sbatch --job-name=gr get_reads $1)
    # jid1=${jid1:20}

# 3. prepare_trim - prepare run files in trim_galore directory for trim_galore.
    # Next run btseq_prepare_trim
    # jid2=$(sbatch --job-name=pt --dependency=afterany:$jid1 --output=prep_trim.out btseq_prepare_trim)
    # jid2=${jid2:20}


# 4. prepare_align - prepare run files for bismark alignment in run directory.
    # Next you need to prepare and align them
    # jid3=$(sbatch --job-name=pa --dependency=afterany:$jid2 --output=prep_aln.out btseq_prepare_align)
    # jid3=${jid3:20}

# 5. trim_galore - trim_galore run seperately in each fastq file.
    # Finally we need to run them
    # sbatch --dependency=afterany:$jid3 --job-name=run --output=run.out btseq_run
# 6. alignment - dependent on completion of trim_galore. output summary are printed to Run directory. Results are printed to seperate directory for each sample (ex. './Sample_1/Output'). Output includes custom .hist and and .summary files which concisely summarize methylation results.
# 7. summary - creates Summary_results.txt file in main directory which summarizes methylation patterns for all samples.
# (8. redo_missing - not part of built-in pipeline. May be run if parts of run failed (ex. due to faulty cluster nodes). Command is 'btseq_redo_missing'.)
# (9. cleanup - not part of built-in pipeline but should be run after completion in order to remove unnecessary files. Command is 'btseq_cleanup'.)

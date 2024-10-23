#!/bin/bash

# Get the directory argument and change to that directory
# Check if the directory argument is provided, if not, set it to the present working directory.
if [ -z "$1" ]; then
    d=$(pwd)
else
    d="$1"
fi

cd $d

# Load R for running the script
module load r/4.4.0

# Don't think these are required...
# Load the modules we need to run the script
# export MODULEPATH=/group/pgh004/carrow/repo/btseq/env/modules:$MODULEPATH
# module load bioinfo
# module load bio
Rscript /group/pgh004/carrow/repo/btseq/scripts/make_summary.R
echo Done creating summary! Results are in Summary_results.txt

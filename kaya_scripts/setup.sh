#!/bin/bash

# read in the first argument and set it to a directory variable
if [ -z "$1" ]; then
    d=$(pwd)
else
    d="$1"
fi

# Add to the path
export PATH=$PATH:/group/pgh004/carrow/repo/btseq/scripts

# load r module
module load r/4.4.0

# move into the directory
cd $d

# run the R script given our directory
Rscript /group/pgh004/carrow/repo/btseq/scripts/btseq_setup.R
echo Done setup!
#!/bin/bash

# Check if the directory argument is provided, if not, set it to the present working directory.
if [ -z "$1" ]; then
    d=$(pwd)
else
    d="$1"
fi

SCRIPT_DIR=$(pwd)/kaya_scripts

# Runs all the trimming scripts
jidt=""
for f in $d/trim_galore/Run/A*q; do
  echo "Submitting trimming job for $f"
  jid=$(sbatch --job-name=trim --output=${f}.out --partition='pophealth' --mem=4GB --cpus-per-task=3 --time=5:00:00 $f)
  sleep 3
  jid=${jid:20}
  jidt="${jidt}:${jid}"
  echo "Job ID for $f: $jid"
done

# Runs all the alignment scripts
jida=""
for f in $d/Run/Sample*q; do
  jid=$(sbatch --job-name=aln --dependency=afterany$jidt --output=${f}.out --partition='pophealth'  --mem=4GB --cpus-per-task=5 --time=5:00:00 $f)
  sleep 3
  jid=${jid:20}
  jida="${jida}:${jid}"
  echo "Job ID for $f: $jid"
done

# Runs the summary script
sbatch --dependency=afterany$jida --job-name=sum --output=sum.out --partition='pophealth' $SCRIPT_DIR/summary.sh $d
sbatch --job-name=sum --output=sum.out --partition='pophealth' /group/pgh004/carrow/repo/btseq/kaya_scripts/summary.sh /group/pgh004/carrow/repo/btseq/example
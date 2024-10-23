#!/bin/bash

# The path to the modules so they can be loaded
MODULE_PATH="/group/pgh004/carrow/repo/btseq/modulefiles"

# Check if the directory argument is provided, if not, set it to the present working directory.
if [ -z "$1" ]; then
    d=$(pwd)
else
    d="$1"
fi

# Check if the directory exists
if [ ! -d "$d" ]; then
  echo "Error: Directory $d does not exist."
  exit 1
fi

echo "Working in directory: $d"

# Step 1: Rename any .gz files that begin with a number by prepending "R_"
# This is done because filenames starting with numbers may cause issues in some systems or scripts.
for file in "$d"/*.gz; do
  if [[ $file =~ ^[0-9] ]]; then
    new_file="$d/R_$(basename "$file")"
    echo "Renaming file $file to $new_file"
    mv "$file" "$new_file"
  fi
done

# Step 2: Create necessary directories for the trim_galore pipeline.
# The 'trim_galore' directory will contain all outputs related to the trimming process.
# Inside it, a 'Run' directory is created to store individual job scripts for each sample.
mkdir -p "$d/trim_galore/Run"
#echo "Created directory structure: $d/trim_galore/Run"

# Step 3: Create a master SLURM job submission script 'Run.q'.
# This script will serve as the master script that submits individual jobs to the SLURM scheduler.
touch "$d/trim_galore/Run/Run.q"
chmod +x "$d/trim_galore/Run/Run.q"
#echo "Created master SLURM script: $d/trim_galore/Run/Run.q"

# Step 4: Loop through all .gz files in the directory and create a corresponding job script for each file.
# Each file will have its own SLURM script to handle the execution of trim_galore for that specific file.
for f in "$d"/*.gz; do
  if [[ ! -f "$f" ]]; then
    echo "No .gz files found in the directory."
    exit 0
  fi
  
  # Create a new shell script specific to this file in the 'Run' directory.
  # This script will load necessary bioinformatics modules and run the trim_galore tool on the input file.
  qfile="$d/trim_galore/Run/$(basename "$f")_trim_galore.q"
  echo '#! /bin/sh' > "$qfile"
  echo "Created job script: $qfile"

  # Step 5: Append module load commands to the job script.
  echo "Appending module load commands to the job script."
  # update the module path for these tools first
  echo "module use $MODULE_PATH" >> "$qfile"
  echo module load bioinfo >> "$qfile"
  echo module load cutadapt >> "$qfile"
  echo module load trim_galore >> "$qfile"

  # Step 6: Append the trim_galore command to process the current .gz file.
  echo "Appending trim_galore command to the job script for file $f."
  echo trim_galore -a GATCGGAAGAGCA -o "$d/trim_galore" "$f" >> "$qfile"

  # Make the script executable so it can be run by SLURM.
  chmod +x "$qfile"
  echo "Made job script executable: $qfile"
  
  # Step 7: Append job submission information to the master SLURM script (Run.q).
  echo "Adding job submission command for file $f to the master script."
  echo sbatch --job-name=trim --output="$d/trim_galore/Run/$(basename "$f")_trim.out" --partition=pophealth --mem=4GB --cpus-per-task=3 --time=5:00:00 "$qfile" >> "$d/trim_galore/Run/Run.q"
done

echo "Job script generation complete. To submit all jobs, run: bash $d/trim_galore/Run/Run.q"

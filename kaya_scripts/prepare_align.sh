#!/bin/bash

# Check if the directory argument is provided, if not, set it to the present working directory.
if [ -z "$1" ]; then
    outdir=$(pwd)
else
    outdir="$1"
fi

# Set the input file containing the definitions for the job
defs="${outdir}/sample_sheet.txt"

# Create a directory named "Run" within the current working directory
mkdir -p "${outdir}/Run"

# Create an empty shell script file named "Run.q" inside the "Run" directory
touch "${outdir}/Run/Run.q"

# Make the newly created "Run.q" script executable
chmod +x "${outdir}/Run/Run.q"

# Append a shebang line (#!/bin/sh) to the "Run.q" script to specify that it should be run in a shell environment
echo '#! /bin/sh' >> "${outdir}/Run/Run.q"

# Read the input definitions from the file, line by line, and use awk to generate individual job scripts
# Each job script will be named using the second and first columns of the input file, and will include commands to 
# execute a series of bioinformatics steps
awk -v d="${outdir}" '
{
    # Create a variable Qout that holds the path to the job script for each task
    Qout=d "/Run/" $2 "_" $1 ".q";
    
    # Create the job script by appending the following commands:

    # 1. Create the job script file for the specific task
    print "touch " d "/Run/" $2 "_" $1 ".q\n" \
    
    # 2. Add the shebang line for the job script
    "echo \047\043\\\041/bin/sh\047 >> " Qout "\n" \
    
    # 3. Create a directory for the task using the second and first columns from the input file
    "echo mkdir " d "/" $2 "_" $1 ">> " Qout "\n" \
    
    # 4. Add a command to create symbolic links to the input file (fourth column in the input file)
    "echo ln -s " $4 " " d "/" $2 "_" $1 " >> " Qout "\n" \
    
    # 5. Load the bioinformatics environment modules needed to run the commands (bioinfo and bio)
    "echo module load bioinfo >> " Qout "\n" \
    "echo module load bio >> " Qout "\n" \
    
    # 7. Run Bismarks genome preparation step using Bowtie2 on the created directory
    "echo bismark_genome_preparation --bowtie2 " d "/" $2 "_" $1 " >> " Qout "\n" \
    
    # 8. Run the Bismark alignment tool using Bowtie2, with options for SAM output format and setting output directory
    "echo bismark " d "/" $2 "_" $1 " " $3 " --sam --bowtie2 -o " d "/" $2 "_" $1 "/Output --temp_dir " d "/" $2 "_" $1 "/Output >> " Qout "\n" \
    
    # 9. Analyze the result using a custom script (Analyze_Result.csh) for the alignment result
    "echo /cs/icore/joshua.moss/scripts/btseq/scripts/Analyze_Result.csh " $3 " " d "/" $2 "_" $1 " >> " Qout "\n" \
    
    # 10. Submit the job script to the SLURM scheduler with specified resources (4GB memory, 3 CPUs, 5 hours runtime)
    # and direct its output log to a corresponding .q.out file
    "echo sbatch --mem=4GB --cpus-per-task=3 --partition='pophealth' --time=5:00:00 --output=" d "/Run/" $2 "_" $1 ".q.out " d "/Run/" $2 "_" $1 ".q >> " d "/Run/Run.q"
}' $defs

# At the end of the script, you can use the following to zip the results
# The commented-out code below will:
# - Extract the unique values from the second column of Def.txt
# - Search for files ending with 'summary' or 'hist' and matching the value from the second column
# - Zip all those results into a file named according to the second column

#for n in $(awk '{print $2}' Def.txt | sort | uniq); do
#    zip ${n}_Results $(du -a | grep -P 'summary$|hist$' | grep ${n} | awk '{print $2}')
#done

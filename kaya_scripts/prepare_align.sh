#!/bin/bash

# Check if the directory argument is provided, if not, set it to the present working directory.
if [ -z "$1" ]; then
    outdir=$(pwd)
else
    outdir="$1"
fi

# This isn't a variable that's used, but it's the path to the modules so they can be loaded
ENV_MODULE_PATH="/group/pgh004/carrow/repo/btseq/env/modules"

# Set the input file containing the definitions for the job
defs="${outdir}/BSTarget_input.txt"

# Create a directory named "Run" within the current working directory
mkdir -p "${outdir}/Run"

# Create an empty shell script file named "Run.q" inside the "Run" directory
touch "${outdir}/Run/Run.q"

# Make the newly created "Run.q" script executable
chmod +x "${outdir}/Run/Run.q"

# Append a shebang line (#!/bin/sh) to the "Run.q" script to specify that it should be run in a shell environment
echo '#! /bin/sh' >> "${outdir}/Run/Run.q"

# Read the input definitions from the file, line by line, and use awk to generate individual job scripts
awk -v outdir="${outdir}" '
{
    # Define the path for the job script to be created
    Qout=outdir "/Run/" $2 "_" $1 ".q";
    
    # 1. Create the job script file for the specific task
    print "#! /bin/sh" > Qout;  # Write shebang directly into the job script
    
    # 2. Create a directory for the task using the second and first columns from the input file
    print "mkdir -p " outdir "/" $2 "_" $1 >> Qout;
    
    # 3. Add a command to create symbolic links to the input file (fourth column in the input file)
    print "ln -s " $4 " " outdir "/" $2 "_" $1 >> Qout;
    
    # 4. Load the bioinformatics environment modules needed to run the commands (samtools, bowtie2 and bismark)
    print "export MODULEPATH=/group/pgh004/carrow/repo/btseq/env/modules:$MODULEPATH" >> Qout;
    print "module load samtools" >> Qout;
    print "module load bowtie2" >> Qout;
    print "module load bismark" >> Qout;
    
    # 5. Run Bismark genome preparation step using Bowtie2 on the created directory
    print "bismark_genome_preparation --bowtie2 " outdir "/" $2 "_" $1 >> Qout;
    
    # 6. Run the Bismark alignment tool using Bowtie2, with options for SAM output format and setting output directory
    print "bismark " outdir "/" $2 "_" $1 " " $3 " --sam --bowtie2 -o " outdir "/" $2 "_" $1 "/Output --temp_dir " outdir "/" $2 "_" $1 "/Output" >> Qout;
    
    # 7. Analyze the result using a custom script (Analyze_Result.csh) for the alignment result
    print "/cs/icore/joshua.moss/scripts/btseq/scripts/Analyze_Result.csh " $3 " " outdir "/" $2 "_" $1 >> Qout;
    
    # 8. Add job submission command to the master "Run.q" script
    print "sbatch --mem=4GB --cpus-per-task=3 --partition=pophealth --time=5:00:00 --output=" outdir "/Run/" $2 "_" $1 ".q.out " Qout >> outdir "/Run/Run.q";
}' "$defs"

echo "Script created at ${outdir}/Run/Run.q"
# At the end of the script, you can use the following to zip the results
# The commented-out code below will:
# - Extract the unique values from the second column of Def.txt
# - Search for files ending with 'summary' or 'hist' and matching the value from the second column
# - Zip all those results into a file named according to the second column

#for n in $(awk '{print $2}' Def.txt | sort | uniq); do
#    zip ${n}_Results $(du -a | grep -P 'summary$|hist$' | grep ${n} | awk '{print $2}')
#done

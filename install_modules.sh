#!/bin/bash

module load Anaconda3

# Exit on error
set -e

# Variables (Adjust these as needed)
MODULE_DIR="$PWD/modulefiles"
ENV_DIR="$PWD/modules"
CONDA_CHANNELS="-c bioconda -c defaults"
CONDA_PACKAGES="bioconda::trim-galore bioconda::cutadapt auto::bioinfo"
MODULE_FILES=("trim-galore" "cutadapt" "bioinfo")

# Step 1: Create the Conda environment if it doesn't exist
if [ ! -d "$ENV_DIR" ]; then
    echo "Creating Conda environment at $ENV_DIR..."
    conda create --yes --prefix "$ENV_DIR" $CONDA_CHANNELS $CONDA_PACKAGES
else
    echo "Conda environment already exists at $ENV_DIR"
fi

# Step 2: Activate the Conda environment
source activate "$ENV_DIR"

# Step 3: Create the modulefiles directory if it doesn't exist
if [ ! -d "$MODULE_DIR" ]; then
    echo "Creating modulefiles directory at $MODULE_DIR..."
    mkdir -p "$MODULE_DIR"
fi

# Step 4: Create module files for each tool
create_modulefile() {
    TOOL_NAME=$1
    MODULE_PATH="$MODULE_DIR/$TOOL_NAME/1.0"

    echo "Creating modulefile for $TOOL_NAME at $MODULE_PATH..."

    mkdir -p "$(dirname "$MODULE_PATH")"
    cat > "$MODULE_PATH" <<EOL
#%Module1.0
proc ModulesHelp { } {
    puts stderr "$TOOL_NAME 1.0"
}
module-whatis "Loads the $TOOL_NAME tool"

# Set up the environment (path to the Conda environment)
set root $ENV_DIR

prepend-path PATH \$root/bin
EOL
}

for TOOL in "${MODULE_FILES[@]}"; do
    create_modulefile "$TOOL"
done

echo "All module files have been created."

# Step 5: Instructions for SLURM Script Usage
echo -e "\n===================================================="
echo "To use the modules in your SLURM script, add the following lines:"
cat <<EOL

# Load system-wide modules if needed
module load <some_system_module>

# Temporarily add your local modules directory to the MODULEPATH
export MODULEPATH=$MODULE_DIR:\$MODULEPATH

# Load your custom modules
module load trim-galore/1.0
module load cutadapt/1.0
module load bioinfo/1.0

# Now use the tools
trim_galore --help
cutadapt --help
EOL

echo -e "====================================================\n"

#!/bin/bash

module load Anaconda3

# Exit on error
set -e

# Variables (Adjust these as needed)
ENV_DIR="$PWD/env"
MODULE_DIR="$ENV_DIR/modules"
CONDA_CHANNELS="-c bioconda -c defaults"
CONDA_PACKAGES=("bioconda::trim-galore" "bioconda::cutadapt" "auto::bioinfo" "bioconda::bowtie2" "bioconda::samtools" "bioconda::bismark")

# Initialize empty array for package names
PACKAGE_NAMES=()

# Extract package names from CONDA_PACKAGES
for pkg_spec in "${CONDA_PACKAGES[@]}"; do
    pkg_name="${pkg_spec##*::}"
    PACKAGE_NAMES+=("$pkg_name")
done

# Step 1: Create or update the Conda environment
if [ ! -d "$ENV_DIR" ]; then
    echo "Creating Conda environment at $ENV_DIR..."
    conda create --yes --prefix "$ENV_DIR" $CONDA_CHANNELS "${CONDA_PACKAGES[@]}"
else
    echo "Conda environment already exists at $ENV_DIR"
    echo "Updating Conda environment with any new packages..."
    conda install --yes --prefix "$ENV_DIR" $CONDA_CHANNELS "${CONDA_PACKAGES[@]}"
fi

# Step 2: Activate the Conda environment
source activate "$ENV_DIR"

# Step 2.5: Ensure that the binaries have executable permissions
chmod +x "$ENV_DIR/bin/"*

# Step 3: Create the modulefiles directory if it doesn't exist
if [ ! -d "$MODULE_DIR" ]; then
    echo "Creating modulefiles directory at $MODULE_DIR..."
    mkdir -p "$MODULE_DIR"
fi

# Function to create modulefile
create_modulefile() {
    TOOL_NAME=$1
    VERSION=$2
    MODULE_PATH="$MODULE_DIR/$TOOL_NAME/$VERSION"

    # Check if modulefile already exists
    if [ -f "$MODULE_PATH" ]; then
        echo "Modulefile for $TOOL_NAME version $VERSION already exists at $MODULE_PATH"
        return
    fi

    echo "Creating modulefile for $TOOL_NAME at $MODULE_PATH..."

    mkdir -p "$(dirname "$MODULE_PATH")"
    cat > "$MODULE_PATH" <<EOL
#%Module1.0
proc ModulesHelp { } {
    puts stderr "$TOOL_NAME $VERSION"
}
module-whatis "Loads the $TOOL_NAME tool"

# Set up the environment (path to the Conda environment)
set root $ENV_DIR

prepend-path PATH \$root/bin
EOL
}

# Step 4: Create module files for each tool
for pkg_name in "${PACKAGE_NAMES[@]}"; do
    # Get the version from conda list
    version=$(conda list --prefix "$ENV_DIR" | awk -v pkg="$pkg_name" '$1==pkg {print $2}')
    if [ -z "$version" ]; then
        echo "Warning: Package $pkg_name not found in environment."
        continue
    fi
    create_modulefile "$pkg_name" "$version"
done

echo "All module files have been created."

# Step 5: Instructions for SLURM Script Usage
echo -e "\n===================================================="
echo "To use the modules in your SLURM script, add the following lines:"
echo

echo "# Load system-wide modules if needed"
echo "module load <some_system_module>"
echo

echo "# Temporarily add your local modules directory to the MODULEPATH"
echo "export MODULEPATH=$MODULE_DIR:\$MODULEPATH"
echo

echo "# Load your custom modules"

for pkg_name in "${PACKAGE_NAMES[@]}"; do
    version=$(conda list --prefix "$ENV_DIR" | awk -v pkg="$pkg_name" '$1==pkg {print $2}')
    if [ -n "$version" ]; then
        echo "module load $pkg_name/$version"
    fi
done

echo
echo "# Now use the tools"

for pkg_name in "${PACKAGE_NAMES[@]}"; do
    echo "$pkg_name --help"
done

echo -e "====================================================\n"

#!/bin/bash
# install.sh
#
# Installs the latest version of:
# virulencefinder
# serotypefinder


# Initial settings
set -e # Stops the scripts if errors happen


# Functions
# Handle command line arguments
parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            *)
                echo "Unknown option: $1"
                exit 1
                ;;
        esac
        shift
    done
}

# Get the latest Git commit in one-line format
get_latest_git_commit() {
    git log --oneline | head -n 1 >> "$log_file" 2>&1
}


# Main
# Parse command line arguments
parse_args "$@"

# Sourcing the config file from the current working dir
# The config file is a text file with variables and paths
# It is not a yaml file
source ./config 
work_dir=$(pwd)
tools_dir=$work_dir"/tools" 
results=$work_dir"/results"

# Set the log file path
log_file="$results/installation_log.txt"
echo "$(date)" >> "$log_file" 2>&1
echo $work_dir >> "$log_file" 2>&1

# Create the tools directory
mkdir -p "$tools_dir"
echo "Installing tools on: $tools_dir"

# Install KMA
cd "$tools_dir"
echo -e "\nKMA" | tee -a "$log_file" 2>&1 
git clone https://bitbucket.org/genomicepidemiology/kma.git
cd kma && get_latest_git_commit && make

# Install SerotypeFinder
cd "$tools_dir"
echo -e "\nSerotypeFinder" | tee -a "$log_file" 2>&1 
git clone https://bitbucket.org/genomicepidemiology/serotypefinder.git
cd serotypefinder && get_latest_git_commit

# Get SerotypeFinder_DB and index
cd "$tools_dir"
echo -e "\nSerotypeFinder_DB" | tee -a "$log_file" 2>&1 
git clone https://bitbucket.org/genomicepidemiology/serotypefinder_db.git
cd serotypefinder_db && get_latest_git_commit
python INSTALL.py "$tools_dir"/kma/kma_index

# Install VirulenceFinder
cd "$tools_dir"
echo -e "\nVirulenceFinder" | tee -a "$log_file" 2>&1 
git clone https://bitbucket.org/genomicepidemiology/virulencefinder.git
cd virulencefinder && get_latest_git_commit

# Get VirulenceFinder_DB and index
cd "$tools_dir"
echo -e "\nVirulenceFinder_DB" | tee -a "$log_file" 2>&1 
git clone https://bitbucket.org/genomicepidemiology/virulencefinder_db.git
cd virulencefinder_db && get_latest_git_commit
python INSTALL.py "$tools_dir"/kma/kma_index

# Test installation by presence of files
[ ! -d "$tools_dir"/kma ] && echo 'KMA directory does not exist' | tee -a "$log_file" 2>&1 
[ ! -d "$tools_dir"/serotypefinder ] && echo 'SerotypeFinder directory does not exist' | tee -a "$log_file" 2>&1 
[ ! -d "$tools_dir"/serotypefinder_db ] && echo 'SerotypeFinder_DB directory does not exist'| tee -a "$log_file" 2>&1 
[ ! -d "$tools_dir"/virulencefinder ] && echo 'VirulenceFinder directory does not exist' | tee -a "$log_file" 2>&1 
[ ! -d "$tools_dir"/virulencefinder_db ] && echo 'SerotypeFinder_DB directory does not exist'| tee -a "$log_file" 2>&1 

echo "Done"
#!/bin/bash
# install.sh
#
# Installs the latest version of:
# virulencefinder (program not db)
# serotypefinder (program and db)


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

# Set the log file path
log_file="$work_dir/installation_log.txt"
echo "$(date) - Some log message" >> "$log_file" 2>&1
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

# Get FSC_VirulenceFinder_DB and index
cd "$tools_dir"
echo -e "\nFSC_VirulenceFinder_DB"
cp -R "$new_database" "$indexed_database" | tee
cd "$indexed_database"
"$tools_dir"/kma/kma index -i "$indexed_database"/database.fsa -o database


# Find all .fasta OR .fastq.gz files in the genomes folder and save the paths to genomes_list.txt
## Program option
## 0 = both run_virulencefinder and run_serotypefinder on fastas
## 1 = run_virulencefinder on fastas
## 2 = run_serotypefinder on fastas
## 3 = run_virulencefinder on raw reads
if [[ "$program" -eq 3 ]]; then
    ls -1 "$genomes"/*.fastq.gz > "$work_dir/genomes_list.txt" 2>> "$log_file" || true
else
    ls -1 "$genomes"/*.fasta "$genomes"/*.fna "$genomes"/*.fa > "$work_dir/genomes_list.txt" 2>> "$log_file" || true
fi
genomeslist="$work_dir/genomes_list.txt"
echo -e "\nGenomes list saved to: $work_dir/genomes_list.txt" | tee -a "$log_file" 2>&1 
# Use subset option from config
# 0 = all genomes are used
# 1 = subset of genomes used
if [[ "$use_subset" -eq 1 ]]; then
    if [[ "$program" -eq 3 ]]; then
        subset=2 # 2 files (R1&R2)
    else
        subset=1 # 1 file(fasta)
    fi
    head -n "$subset" "$work_dir"/genomes_list.txt > "$work_dir"/subset_genomes_list.txt
    genomeslist="$work_dir/subset_genomes_list.txt"
    echo -e "\nSubset genomes list saved to: $work_dir/subset_genomes_list.txt" | tee -a "$log_file" 2>&1
fi


# Test installation by presence of files
[ ! -d "$tools_dir"/kma ] && echo 'KMA directory does not exist' | tee -a "$log_file" 2>&1 
[ ! -d "$tools_dir"/serotypefinder ] && echo 'SerotypeFinder directory does not exist' | tee -a "$log_file" 2>&1 
[ ! -d "$tools_dir"/serotypefinder_db ] && echo 'SerotypeFinder_DB directory does not exist'| tee -a "$log_file" 2>&1 
[ ! -d "$tools_dir"/virulencefinder ] && echo 'VirulenceFinder directory does not exist' | tee -a "$log_file" 2>&1 
[ ! -f "$work_dir"/genomes_list.txt ] && echo "$work_dir/genomes_list.txt does not exist" | tee -a "$log_file" 2>&1 
[ ! -f "$work_dir"/subset_genomes_list.txt ] && echo "$work_dir/subset_genomes_list.txt does not exist" | tee -a "$log_file" 2>&1 

echo "Done"
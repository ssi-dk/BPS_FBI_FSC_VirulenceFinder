#!/bin/bash
# run_virulencefinder.sh
# This script runs virulencefinder on a folder
# conda activate FBI_virulencefinder
# bash run_virulencefinder.sh --debug


# Settings
set -e # Stops the scripts if errors happen
debug=false # Initialize debug flag


# Handle command line arguments
parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --debug)
                debug=true
                ;;
            *)
                echo "Unknown option: $1"
                exit 1
                ;;
        esac
        shift
    done
}
parse_args "$@"


# Sourcing the config file from the current working dir
# The config file is a text file with variables and paths
# It is not a yaml file
source ./config 
work_dir=$(pwd)
tools_dir=$work_dir"/tools" 
results=$work_dir"/results"
genomeslist=$work_dir"/genomes_list.txt"

# Log file
log_file="$work_dir/installation_log.txt"

# Current working dir
$debug && echo "work_dir: $work_dir"


# Functions
run_virulencefinder() {
	echo "running virulencefinder on assemblies"
    
    # Iterate over file paths from genomes_list.txt
    while IFS= read -r file_path; do
        assembly=$file_path
        $debug && echo "running virulencefinder on $assembly"
        
        # Get the genome name
        genome=$(basename "$file_path" | cut -d "." -f 1)
        mkdir -p "$results/virulencefinder/$genome/blastn"
        echo "running virulencefinder on $genome"

        cmd=("python" "$tools_dir/virulencefinder/virulencefinder.py" 
            "-i" "$assembly"
            "-tmp" "$results/virulencefinder/$genome/blastn"
            "-o" "$results/virulencefinder/$genome" 
            "-p" "$tools_dir/virulencefinder_db"
            "-mp" "$conda_env/bin/blastn" 
            "-l" "$viru_min_cov" 
            "-t" "$viru_min_id" 
            "-x" 
            "-q")
        $debug && echo "${cmd[*]}"
		"${cmd[@]}"
    done < "$genomeslist"
}


run_serotypefinder() {
	echo "running serotypefinder on assemblies"

    # Iterate over file paths from genomes_list.txt
    while IFS= read -r file_path; do
        assembly=$file_path
        $debug && echo "running serotypefinder on $assembly"
        
        # Get the genome name
        genome=$(basename "$file_path" | cut -d "." -f 1)
        mkdir -p "$results/serotypefinder/$genome"
        echo "running serotypefinder on $genome"

        cmd=("python" "$tools_dir/serotypefinder/serotypefinder.py"
            "-i" "$assembly"
            "-o" "$results/serotypefinder/$genome"
            "-p" "$tools_dir/serotypefinder_db"
            "-l" "$sero_min_cov"
            "-t" "$sero_min_id"
            "-x"
            "-q")
		$debug && echo "${cmd[*]}"
        "${cmd[@]}"
    done < "$genomeslist"
}


run_virulencefinder_raw() {
    echo "running virulencefinder on raw reads"

    # Iterate over file paths from genomes_list.txt
    while IFS= read -r file_path; do

        # Check if the file path matches the pattern
        if [[ "$file_path" == *"_R1_"*.fastq.gz ]]; then
            # Construct the corresponding R1 and R2 files
			R1=$file_path
            R2="${file_path/_R1_/_R2_}"
            $debug && echo "running virulencefinder on ""$R1"" and ""$R2"

            # Get the genome name
            genome=$(basename "$R1" "_R1_*.fastq.gz" | cut -d "_" -f 1)
            mkdir -p "$results/virulencefinder_raw/$genome/kma"
            echo "running virulencefinder on "$genome
            
            cmd=("python" "$tools_dir/virulencefinder/virulencefinder.py"
                "-i" "$R1" "$R2"
                "-tmp" "$results/virulencefinder/$genome/kma"
                "-o" "$results/virulencefinder_raw/$genome"
                "-p" "$tools_dir/virulencefinder_db"
                "-mp" "$tools_dir/kma/kma"
                "-l" "$viru_min_cov"
                "-t" "$viru_min_id"
                "-x"
                "-q")
			$debug && echo "${cmd[*]}"
            "${cmd[@]}"
        fi
    done < "$genomeslist"
}


case $program in
    0)
        run_virulencefinder
        run_serotypefinder
        ;;
    1) 
        run_virulencefinder
        ;;
    2)
        run_serotypefinder
        ;;
    3)
        run_virulencefinder_raw
        ;;
esac

echo "Done"
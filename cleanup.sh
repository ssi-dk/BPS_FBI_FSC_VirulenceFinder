#!/bin/bash
# cleanup.sh
# bash cleanup.sh


# Initial settings
set -e # Stops the scripts if errors happen


# Main
# Sourcing the config file from the current working dir
# The config file is a text file with variables and paths
# It is not a yaml file
source ./config

# Removing tools
# Prompt the user for confirmation
read -p "Do you want to remove the folder "$tools_dir"? (y/n): " confirmation
# Check if the user entered 'y' before proceeding
if [ "$confirmation" = "y" ]; then
    # Removing tools within the tools folder
    rm -rf "$tools_dir"
    echo "Tools removed successfully."
else
    echo "Operation canceled."
fi

# Removing files
# Prompt the user for confirmation
read -p "Do you want to remove the genome_lists.txt and subset_genomes_list.txt? (y/n): " confirmation
# Check if the user entered 'y' before proceeding
if [ "$confirmation" = "y" ]; then
    # Removing list of genome names
    rm genomes_list.txt
    rm subset_genomes_list.txt
    echo "Genome lists removed successfully."
else
    echo "Operation canceled."
fi
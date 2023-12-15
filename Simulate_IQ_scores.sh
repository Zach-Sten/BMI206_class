#!/bin/bash

# Define the directory containing supergroups files
directory='supergroups'

# Define the populations
populations=("AFR" "EUR" "EAS" "SAS" "AMR")

# Loop through populations
for pop in "${populations[@]}"; do
    # Construct the filename for the current population
    filename="$directory/supergroup_${pop}_samples.txt"

    # Read the file into an array
    ids=()
    while IFS= read -r line; do
        ids+=("$line")
    done < "$filename"

    # Generate a random score for each ID
    scores=()
    for id in "${ids[@]}"; do
        score=$((RANDOM % (120 - 80 + 1) + 80))
        scores+=("$id $id $score")
    done

    # Save the scores to a new file with the population name
    output_filename="${pop}_qt.phe"
    output_path="$directory/$output_filename"
    printf "%s\n" "${scores[@]}" > "$output_path"

    echo "Processed $filename and saved to $output_filename"
done
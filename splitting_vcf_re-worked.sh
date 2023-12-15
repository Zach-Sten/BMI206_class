#!/bin/bash

# Define the supergroups you are interested in
supergroups=("AFR" "EUR" "EAS" "SAS" "AMR")

# Define the input VCF file template
input_template="genotype_files/ALL.chr\${chromosome}.phase3_shapeit2_mvncall_integrated_v5b.20130502.genotypes.vcf.gz"

# Define the output directory
output_directory="vcf_files"

# Loop through each supergroup
for supergroup in "${supergroups[@]}"; do
    # Create a subdirectory for the supergroup
    supergroup_directory="${output_directory}/${supergroup}"
    mkdir -p "$supergroup_directory"
    
    # Loop through each chromosome and create the corresponding output VCF file
    for chromosome in {1..22}; do
        # Define the input VCF file for the current chromosome
        input_vcf=$(eval "echo $input_template")
        
        # Define the output VCF file for the current chromosome and supergroup
        output_vcf="${supergroup_directory}/output_${supergroup}_chr${chromosome}.vcf.gz"
        
        # Use bcftools to filter VCF based on the supergroup's population
        bcftools view -S supergroups/supergroup_${supergroup}_samples.txt -o "$output_vcf" "$input_vcf"
        echo "Created $output_vcf"
    done
done

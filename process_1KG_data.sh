#!/bin/bash
#SBATCH --export=NONE      # required when using 'module'
#SBATCH --job-name=Process_1KG_data
#SBATCH --nodes=1
#SBATCH --ntasks=20
#SBATCH --mem=8G
#SBATCH --time=1-00:00:00
#SBATCH --output=/krummellab/data1/zachsten/logs/%x-%j.out

module load CBI miniconda3
conda activate scipy_env
echo "scipy_env loaded correctly"

# Change the number of threads to use
num_threads=10
N_THREADS=2
export MKL_NUM_THREADS=$N_THREADS
export NUMEXPR_NUM_THREADS=$N_THREADS
export OMP_NUM_THREADS=$N_THREADS

process_chromosome() {
    pop=$1
    chr=$2
    echo ${pop} ${chr}

    # Assign the proper directories for everything so that we can process all the information.
    vcf_file_dir="/krummellab/data1/zachsten/PRS/individual_analysis/data/vcf_files/"
    bfile_dir="/krummellab/data1/zachsten/PRS/individual_analysis/data/bfiles/"
    association_dir="/krummellab/data1/zachsten/PRS/individual_analysis/data/association/"
    phenotype_dir="/krummellab/data1/zachsten/PRS/individual_analysis/data/supergroups/"
    PRS_dir="/krummellab/data1/zachsten/PRS/individual_analysis/data/PRS/"
    plink_path="/krummellab/data1/software/plink/"
    exlude_path="/krummellab/data1/zachsten/PRS/individual_analysis/"

    # Create the new bfiles using PLINK from the 1000 genomes superpopulations.
    ${plink_path}plink --vcf ${vcf_file_dir}${pop}/output_${pop}_chr${chr}.vcf.gz --make-bed --out ${bfile_dir}${pop}/${pop}_chr${chr}
    # Set file paths
    input_bim_path="/krummellab/data1/zachsten/PRS/individual_analysis/data/bfiles/${pop}/${pop}_chr${chr}.bim"
    target_bim_path="/krummellab/data1/zachsten/PRS/1000_genomes/snpinfo_mult_1kg_hm3"
    output_temp_path="/krummellab/data1/zachsten/PRS/individual_analysis/data/bfiles/${pop}/test_${pop}_chr${chr}.bim"
    # Use awk to get everything in the right position and create a temporary file:
    awk -v OFS='\t' 'NR==FNR {a[$1,$3,$4,$5]=$2; next} {key=$1 SUBSEP $4 SUBSEP $5 SUBSEP $6; if(key in a) $2=a[key]} 1' "$target_bim_path" "$input_bim_path" > "$output_temp_path"
    # Rename the temporary file to the final name:
    mv "$output_temp_path" "$input_bim_path"
    # Create the association files using the made-up IQ scores for each group
    ${plink_path}plink --bfile ${bfile_dir}${pop}/${pop}_chr${chr} --exclude ${exlude_path}exclude_missing_snps.txt --pheno ${phenotype_dir}${pop}_qt.phe --assoc --allow-no-sex --out ${association_dir}${pop}/${pop}_chr${chr}
    # Have it make PRS scores against the CHIC_discovery stats because that'd be hella interesting to see for our real data:
    ${plink_path}plink --bfile ${bfile_dir}${pop}/${pop}_chr${chr} --exclude ${exlude_path}exclude_missing_snps.txt --score ${association_dir}CHIC_chr${chr}.discovery.formatted.assoc.linear 1 3 4 sum --pheno ${phenotype_dir}${pop}_qt.phe --allow-no-sex --out ${PRS_dir}${pop}/${pop}_chr${chr}_CHIC_discovery_score
    echo "Processing $pop chromosome $chr"s

    #moving onto incorporate PRS-CSx into here to merge three different populations EUR,EAS,AFR with target AMR and target SAS
    #PRScsx_path="/krummellab/data1/zachsten/PRS/PRScsx/"
    #ngEUR=$(wc -l < ${sst_dir}EUR_chr${chr}.discovery.formatted.assoc.linear)
    #ngEAS=$(wc -l < ${sst_dir}EAS_chr${chr}.discovery.formatted.assoc.linear)
    #ngAFR=$(wc -l < ${sst_dir}AFR_chr${chr}.discovery.formatted.assoc.linear)
}
export -f process_chromosome
# This is an intermediate file, change the file path to your working dir, keep the file name.
cmd_file="/krummellab/data1/zachsten/PRS/process_commands_creating_bfiles.txt"
> ${cmd_file}
for pop in AFR EUR EAS SAS AMR; do
    for chr in {1..22}; do
        # if [[ "$pop" == "AFR" && "$chr" -eq 22 ]]; then
        #     continue
        # else
        echo "$pop $chr" >> "$cmd_file"
        # fi
    done
done
cat "$cmd_file" | xargs -n 2 -P $num_threads bash -c 'process_chromosome "$@"' _
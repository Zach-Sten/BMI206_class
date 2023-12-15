#!/bin/bash
#SBATCH --export=NONE      # required when using 'module'
#SBATCH --job-name=PRSCSX_multi_pop_pheno3
#SBATCH --exclude=c4-n20
#SBATCH --nodes=1
#SBATCH --ntasks=20
#SBATCH --mem=18G
#SBATCH --time=1-00:00:00
#SBATCH --output=/krummellab/data1/zachsten/logs/%x-%j.out

module load CBI miniconda3
conda activate scipy_env
echo "scipy_env loaded correctly"
# If getting the error "killed" set the mem higher to give enough ram to run each job.
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
    ref_dir="/krummellab/data1/zachsten/PRS/1000_genomes/"
    bfile_dir="/krummellab/data1/zachsten/PRS/individual_analysis/data/bfiles/"
    association_dir="/krummellab/data1/zachsten/PRS/individual_analysis/data/association/"
    phenotype_dir="/krummellab/data1/zachsten/PRS/individual_analysis/data/phenotypes3/"
    output_dir="/krummellab/data1/zachsten/PRS/individual_analysis/data/PRSCSX_out/"
    PRS_dir="/krummellab/data1/zachsten/PRS/individual_analysis/data/PRS/"
    PRScsx_path="/krummellab/data1/zachsten/PRS/PRScsx/"
    plink_path="/krummellab/data1/software/plink/"
    exlude_path="/krummellab/data1/zachsten/PRS/individual_analysis/"
    
    #PRS-CSx:
    ng=$(wc -l < ${association_dir}CHIC_chr${chr}.discovery.formatted.assoc.linear) #CHIC
    ng1=$(wc -l < ${association_dir}AFR/AFR_chr${chr}_pheno3.qassoc) #AFR
    ng2=$(wc -l < ${association_dir}EAS/EAS_chr${chr}_pheno3.qassoc) #EAS
    #You can add more summary statistics for mixed population discovery, you need to specify pop name in order using --pop. You might want to change --out_name if you are using multiple summary stats for mixed populations.
    bim_prefix="${bfile_dir}${pop}/${pop}_chr${chr}"
    #Using AFR + CHIC
    python ${PRScsx_path}PRScsx.py --ref_dir=${ref_dir} --bim_prefix=$bim_prefix --sst_file=${association_dir}CHIC_chr${chr}.discovery.formatted.assoc.linear,${association_dir}AFR/AFR_chr${chr}_pheno3.formatted.qassoc --n_gwas=$((ng - 1)),$((ng1 - 1)) --pop=EUR,AFR --out_dir=${output_dir}CHIC_AFR/ --out_name=${pop}_target_CHIC_chr${chr}_pheno3 --chrom=${chr}
    #Using EAS + CHIC
    python ${PRScsx_path}PRScsx.py --ref_dir=${ref_dir} --bim_prefix=$bim_prefix --sst_file=${association_dir}CHIC_chr${chr}.discovery.formatted.assoc.linear,${association_dir}EAS/EAS_chr${chr}_pheno3.formatted.qassoc --n_gwas=$((ng - 1)),$((ng2 - 1)) --pop=EUR,EAS --out_dir=${output_dir}CHIC_EAS/ --out_name=${pop}_target_CHIC_chr${chr}_pheno3 --chrom=${chr}
    #Using AFR + EAS + CHIC
    python ${PRScsx_path}PRScsx.py --ref_dir=${ref_dir} --bim_prefix=$bim_prefix --sst_file=${association_dir}CHIC_chr${chr}.discovery.formatted.assoc.linear,${association_dir}AFR/AFR_chr${chr}_pheno3.formatted.qassoc,${association_dir}EAS/EAS_chr${chr}_pheno3.formatted.qassoc --n_gwas=$((ng - 1)),$((ng1 - 1)),$((ng2 - 1)) --pop=EUR,AFR,EAS --out_dir=${output_dir}CHIC_AFR_EAS/ --out_name=${pop}_target_CHIC_chr${chr}_pheno3 --chrom=${chr}
    
    #Run PLINK using the new association files for each thing against the populations. Again three different pieces.
    #Using AFR + CHIC
    ${plink_path}plink --bfile ${bfile_dir}${pop}/${pop}_chr${chr} --exclude ${exlude_path}exclude_missing_snps.txt --pheno ${phenotype_dir}${pop}_qt.phe --score ${output_dir}CHIC_AFR/${pop}_target_CHIC_chr${chr}_pheno3_EUR_pst_eff_a1_b0.5_phiauto_chr${chr}.txt 2 5 6 sum --allow-no-sex --out ${PRS_dir}CHIC_AFR/${pop}_chr${chr}_CHIC-EUR_score_pheno3
    ${plink_path}plink --bfile ${bfile_dir}${pop}/${pop}_chr${chr} --exclude ${exlude_path}exclude_missing_snps.txt --pheno ${phenotype_dir}${pop}_qt.phe --score ${output_dir}CHIC_AFR/${pop}_target_CHIC_chr${chr}_pheno3_AFR_pst_eff_a1_b0.5_phiauto_chr${chr}.txt 2 5 6 sum --allow-no-sex --out ${PRS_dir}CHIC_AFR/${pop}_chr${chr}_CHIC-AFR_score_pheno3
    #Using EAS + CHIC
    ${plink_path}plink --bfile ${bfile_dir}${pop}/${pop}_chr${chr} --exclude ${exlude_path}exclude_missing_snps.txt --pheno ${phenotype_dir}${pop}_qt.phe --score ${output_dir}CHIC_EAS/${pop}_target_CHIC_chr${chr}_pheno3_EUR_pst_eff_a1_b0.5_phiauto_chr${chr}.txt 2 5 6 sum --allow-no-sex --out ${PRS_dir}CHIC_EAS/${pop}_chr${chr}_CHIC-EUR_score_pheno3
    ${plink_path}plink --bfile ${bfile_dir}${pop}/${pop}_chr${chr} --exclude ${exlude_path}exclude_missing_snps.txt --pheno ${phenotype_dir}${pop}_qt.phe --score ${output_dir}CHIC_EAS/${pop}_target_CHIC_chr${chr}_pheno3_EAS_pst_eff_a1_b0.5_phiauto_chr${chr}.txt 2 5 6 sum --allow-no-sex --out ${PRS_dir}CHIC_EAS/${pop}_chr${chr}_CHIC-EAS_score_pheno3
    #Using AFR + EAS + CHIC
    ${plink_path}plink --bfile ${bfile_dir}${pop}/${pop}_chr${chr} --exclude ${exlude_path}exclude_missing_snps.txt --pheno ${phenotype_dir}${pop}_qt.phe --score ${output_dir}CHIC_AFR_EAS/${pop}_target_CHIC_chr${chr}_pheno3_EUR_pst_eff_a1_b0.5_phiauto_chr${chr}.txt 2 5 6 sum --allow-no-sex --out ${PRS_dir}CHIC_AFR_EAS/${pop}_chr${chr}_CHIC-EUR_score_pheno3
    ${plink_path}plink --bfile ${bfile_dir}${pop}/${pop}_chr${chr} --exclude ${exlude_path}exclude_missing_snps.txt --pheno ${phenotype_dir}${pop}_qt.phe --score ${output_dir}CHIC_AFR_EAS/${pop}_target_CHIC_chr${chr}_pheno3_AFR_pst_eff_a1_b0.5_phiauto_chr${chr}.txt 2 5 6 sum --allow-no-sex --out ${PRS_dir}CHIC_AFR_EAS/${pop}_chr${chr}_CHIC-AFR_score_pheno3
    ${plink_path}plink --bfile ${bfile_dir}${pop}/${pop}_chr${chr} --exclude ${exlude_path}exclude_missing_snps.txt --pheno ${phenotype_dir}${pop}_qt.phe --score ${output_dir}CHIC_AFR_EAS/${pop}_target_CHIC_chr${chr}_pheno3_EAS_pst_eff_a1_b0.5_phiauto_chr${chr}.txt 2 5 6 sum --allow-no-sex --out ${PRS_dir}CHIC_AFR_EAS/${pop}_chr${chr}_CHIC-EAS_score_pheno3
    echo "Processing $pop chromosome $chr"s
}
export -f process_chromosome
# This is an intermediate file, change the file path to your working dir, keep the file name.
cmd_file="/krummellab/data1/zachsten/PRS/process_commands_creating_bfiles.txt"
> ${cmd_file}
for pop in AMR SAS; do
    for chr in {1..22}; do
        # if [[ "$pop" == "AFR" && "$chr" -eq 22 ]]; then
        #     continue
        # else
        echo "$pop $chr" >> "$cmd_file"
        # fi
    done
done
cat "$cmd_file" | xargs -n 2 -P $num_threads bash -c 'process_chromosome "$@"' _
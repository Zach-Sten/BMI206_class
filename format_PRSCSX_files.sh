#!/bin/bash
#SBATCH --export=NONE      # required when using 'module'
#SBATCH --job-name=format_PRSCSX_files
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
    bfile_dir="/krummellab/data1/zachsten/PRS/individual_analysis/data/bfiles/"
    association_dir="/krummellab/data1/zachsten/PRS/individual_analysis/data/association/"

    #format the association files using awk into the proper format for PRS-CSx
    input_bim_path=$bfile_dir${pop}/${pop}_chr${chr}.bim
    target_bim_path=$association_dir${pop}/${pop}_chr${chr}.qassoc
    output_path=$association_dir${pop}/${pop}_chr${chr}.formatted.qassoc
    # Use awk to get everything in the right position and create a temporary file:
    # This is good but it's missing the headers and is in the wrong order at the end file. The end file currently looks like: rs12255619	-0.1151	1.209	C	A
    awk -v OFS='\t' 'NR==FNR {if ($2 != ".") {a[$2]=$5; b[$2]=$6;} next} FNR==1 {print "SNP", "A1", "A2", "BETA", "P";} FNR>1 && $2 in a {snp=$2; a1=a[snp]; a2=b[snp]; beta=$5; p=$6; print snp, a1, a2, beta, p;}' "$target_bim_path" "$input_bim_path" > "$output_path"
    awk -v OFS='\t' 'BEGIN {print "SNP", "A1", "A2", "BETA", "P"} NR>1 && $4 != "NA" && $5 != "NA" {print $1, $4, $5, $2, $3}' "$output_path" > "${output_path}.temp" && mv "${output_path}.temp" "$output_path"
    awk 'FNR==NR{a[$2]=$9;next} $5!="NA"{OFS="\t"; $5=a[$1]; print}' "$target_bim_path" "$output_path" > "${output_path}.temp" && mv "${output_path}.temp" "$output_path"
    echo "Processing $pop chromosome $chr"
}
export -f process_chromosome
# This is an intermediate file, change the file path to your working dir, keep the file name.
cmd_file="/krummellab/data1/zachsten/PRS/process_commands_creating_bfiles.txt"
> ${cmd_file}
for pop in AFR EUR EAS AMR SAS ; do
    for chr in {1..22}; do
        # if [[ "$pop" == "AFR" && "$chr" -eq 22 ]]; then
        #     continue
        # else
        echo "$pop $chr" >> "$cmd_file"
        # fi
    done
done
cat "$cmd_file" | xargs -n 2 -P $num_threads bash -c 'process_chromosome "$@"' _
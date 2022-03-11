#!/bin/bash
#
#SBATCH --job-name=test_scfsl_pbc
#SBATCH --output=test_scfsl_pbc.txt
#
#SBATCH --ntasks=1
#SBATCH --time=18:00:00
#SBATCH --mem-per-cpu=30000


FILES=(/path/to/bids/sub*)

echo $HOSTNAME
echo ${FILES[$SLURM_ARRAY_TASK_ID]}

inputNo="00${SLURM_ARRAY_TASK_ID}"
subject="sub-FIB"$inputNo
echo $HOSTNAME running $subject
singularity run --bind /path/to/bids:/data ../../../singularity_images/scfsl_gpu.sif /scripts/proc_fsl_connectome_fsonly.sh $subject 


#!/bin/bash
#
#SBATCH --job-name=test_scfsl_pbc
#SBATCH --output=test_scfsl_pbc.txt
#
#SBATCH --ntasks=1
#SBATCH --time=18:00:00
#SBATCH --mem-per-cpu=30000


FILES=(/projects/BICpipeline/Pipeline_Pilot/TestingFork/diffDev/FIBMS_BIDS/HDCout/sub*)

echo $HOSTNAME
echo ${FILES[$SLURM_ARRAY_TASK_ID]}

#This is a test of the scfsl.simg on slurm running from /projects/BICpipeline/Pipeline_Pilot/TestingFork/diffDev

	inputNo="00${SLURM_ARRAY_TASK_ID}"
	subject="sub-FIB"$inputNo
        echo $HOSTNAME running $subject
	singularity run --bind ../SCFSL_Scripts/scripts:/scripts --bind ./FIBMS_BIDS/HDCout:/data ../../../singularity_images/dev/scfsl.simg /scripts/proc_fsl_connectome_dev.sh $subject 


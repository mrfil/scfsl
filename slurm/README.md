Files for running the scfsl pipeline on multiple subjects as an sbatch job.
Generate list of subjects to process with batchlistGen.sh
  This may require alteration based on project directory structure
  Numbers outputted in form of comma-separated sbatch array of task IDs

Modify a new srun_scfsl_batch_{project}.sh script based on project directory structure
Modify a new scripts/proc_fsl_connectome_{project}.sh based on project directory structure

Example sbatch call from within project directory
sbatch –a `cat tasks.txt` ../srun_scfsl_batch_{project}.sh

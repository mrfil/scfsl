# scfsl
FSL-based structural connectivity pipeline (WIP)

Modified version of original pipeline to run with BIDS compatibility achieved with HeuDiConv. Preprocessing and Freesurfer parcellation added from fMRIPrep. MRIQC is run on HeuDiConv BIDS derivatives for quality control.

Further analysis can be performed on data processed in this manner using other BIDS apps.

Subject IDs should be set to three letters and three numbers (e.g. SUB001) when inputting to HeuDiConv for out of the box compatibility with these scripts.

This pipeline should be run after HeuDiConv, fmriprep, and QSIPrep preprocessing + reorient_fslstd recon have been run on the data.

##Docker build##

```
docker build -t scfsl_gpu:0.1.0 .
```

Or pull the image from mrfilbi/scfsl_gpu:0.1.0 (or newest tag)

##Docker run command##

```
docker run --gpus all -v /path/to/bids:/data scfsl_gpu:0.1.0 /scripts/proc_fsl_connectome_fsonly.sh subject session
```
##Deploy##

You may need to set your CUDA toolkit version to 9.1 and set the environmental variable for LD_LIBRARY_PATH to run successfully.

*On Singularity* 


SINGULARITY_ENVLD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/local/cuda-9.1/lib64 \
singularity exec --nv -B /path/to/license.txt:/opt/freesurfer/license.txt,/path/to/project/bids:/data \
/path/to/scfsl_gpu-v0.1.1_cuda9.1-runtime_ubuntu16.04.sif \
/bin/bash /scripts/proc_fsl_connectome_fsonly.sh sub-SUBJECT ses-SESSION


###To-do###

[x] build image
[] add directions for pre-requisite steps
[] resolve error in mask dimensions error
[] successful run testing

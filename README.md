# scfsl
FSL-based structural connectivity pipeline

Modified version of original pipeline to run with BIDS compatibility achieved with HeuDiConv. Preprocessing and Freesurfer parcellation added from fMRIPrep. MRIQC is run on HeuDiConv BIDS derivatives for quality control.

Further analysis can be performed on data processed in this manner using other BIDS apps.

Subject IDs should be set to three letters and three numbers (e.g. SUB001) when inputting to HeuDiConv for out of the box compatibility with these scripts.

This pipeline should be run after HeuDiConv, fmriprep, and QSIPrep preprocessing + reorient_fslstd recon have been run on the data.

##Docker build##

docker build -t scfsl_gpu:0.1.0 .

##Docker run command##

docker run --gpus all -v /path/to/bids:/data scfsl_gpu:0.1.0 /scripts/proc_fsl_connectome_fsonly.sh subject session
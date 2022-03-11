# scfsl
FSL-based structural connectivity pipeline

Modified version of original pipeline to run with BIDS compatibility achieved with HeuDiConv. Preprocessing and Freesurfer parcellation added from fMRIPrep. MRIQC is run on HeuDiConv BIDS derivatives for quality control.

Further analysis can be performed on data processed in this manner using other BIDS apps.

Subject IDs should be set to three letters and three numbers (e.g. SUB001) when inputting to HeuDiConv for out of the box compatibility with these scripts.

This pipeline should be run in the following order after HeuDiConv, fmriprep, and MRIQC have been run on the data: pcamach2/mridti, registration of SUIT cerebellar atlas to T1w space in SPM MATLAB, pcamach2/scfsl.

Freesurfer only version finishes in ~5-6 hours on the cluster through slurm

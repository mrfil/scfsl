# scfsl
FSL-based structural connectivity pipeline (WIP)

Modified version of original pipeline to run as a sub-pipeline of our HPC pipelines with BIDS compatibility achieved with HeuDiConv. 
Preprocessing and Freesurfer parcellation added from fMRIPrep. 
MRIQC is run on HeuDiConv BIDS derivatives for quality control.

## Prerequisites

This portion of the pipeline should be run after HeuDiConv, fmriprep, 
and QSIPrep preprocessing + reorient_fslstd recon have been run on the data.

*The following examples use the CUDA 9.1 toolkit and runtime (loaded via module or native install)
*Support for CUDA 10.2 is in development in this branch

### Docker build

```
docker build -t scfsl_gpu:0.3.0 .
```

Or pull the image from mrfilbi/scfsl_gpu:0.3.0 (or newest tag)

##Docker run command##

```
docker run --gpus all -v /path/to/bids:/data scfsl_gpu:0.3.0 /scripts/proc_fsl_connectome_fsonly.sh subject session
```

### Singularity build

```
singularity build scfsl_gpu-v0.3.0.sif docker://mrfilbi/scfsl_gpu:0.3.0
```

### Docker Example
```
# QSIPrep preprocessing + reorient to fsl
docker run --gpus all -v /path/project/bids:/datain \
-v /path/to/freesurfer/license.txt:/opt/freesurfer/license.txt \
pennbbl/qsiprep:0.15.1 /datain /datain/derivatives/ --recon-input /datain/derivatives/qsiprep/ \
--recon_spec reorient_fslstd \ --output-resolution 1.6 participant \
--participant-label sub-SUB330 --fs-license-file /opt/freesurfer/license.txt

# Running SCFSL GPU tractography
 docker exec --gpus all -e LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/local/cuda-9.1/lib64 \
  -v /path/to/freesurfer/license.txt:/opt/freesurfer/license.txt \
  -v /path/project/bids:/data mrfilbi/scfsl_gpu:0.3.0 /bin/bash /scripts/proc_fsl_connectome_fsonly.sh sub-SUB339 ses-A


```


*You may need to set your CUDA toolkit version to 9.1 and set the environmental variable for LD_LIBRARY_PATH to run successfully*

### Singularity Example
```
# QSIPrep preprocessing + reorient to fsl
singularity run --nv -B /path/project/bids:/datain,/path/to/freesurfer/license.txt:/opt/freesurfer/license.txt \
/path/to/qsiprep-v0.15.1.sif /datain /datain/derivatives/ --recon-input /datain/derivatives/qsiprep/ --recon_spec reorient_fslstd \ --output-resolution 1.6 participant --participant-label sub-SUB330 --fs-license-file /opt/freesurfer/license.txt

# Running SCFSL GPU tractography
SINGULARITY_ENVLD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/local/cuda-9.1/lib64 \
singularity exec --nv -B /path/to/freesurfer/license.txt:/opt/freesurfer/license.txt,/path/project/bids:/data \
/path/to/scfsl_gpu-v0.3.0.sif /bin/bash /scripts/proc_fsl_connectome_fsonly.sh sub-SUB339 ses-A

```

## Outputs

In addition to the fdt_network_matrix produced by probtrackx2 for the masks 
derived from Freesurfer parcellation (generated in sMRIPrep/fMRIPrep),
this sub-pipeline also outputs node-labeled csv files of the NxN streamline-weighted 
and ROI volume-weighted structural connectome.

## Performance

From initial testing (on two datasets):

| OS (host)    | CUDA Version | GPU(s)                 | CPU(s)                                    | RAM    | Run time       |
|--------------|:------------:|:----------------------:|:-----------------------------------------:|:------:|---------------:|
| CentOS       | 9.1          | Nvidia Tesla V100 16GB | Intel Xeon Gold 6138 2.00GHz (80 threads) | 192GB  | 20-35 minutes? |
| CentOS       | 10.2         | Nvidia Tesla V100 16GB | Intel Xeon Gold 6138 2.00GHz (80 threads) | 192GB  | 30-35 minutes  |

Peak GPU memory usage: 14399MiB

### To-do

[x] build image
[x] add directions for pre-requisite steps
[x] resolve error in mask dimensions error
[x] successful run testing
[x] example run times
[x] describe outputs

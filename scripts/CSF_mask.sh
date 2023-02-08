#!/bin/bash

#create CSF mask for tractography from probseg from QSIPrep

fslreorient2std CSF_probseg.nii.gz CSF_probseg_fslstd.nii.gz
fslmaths CSF_probseg.nii.gz -thr 0.5 -uthr 1 CSFmask.nii.gz

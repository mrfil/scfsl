#!/bin/bash
#
#modify auto_reorient to use IMG_brain.nii as default?
#
# example : spmsuit.sh /shared/mrfil-data/pcamach2/spm_reorient/no_spm_reorient/derivatives/dtipipeline/sub-FIB006/ses-01/Analyze/MPRAGE /shared/mrfil-data/pcamach2/spm12 /shared/mrfil-data/pcamach2/spm12/toolbox/OldNorm auto_reorient suit_inc sub-FIB006 ses-01 /shared/mrfil-data/pcamach2/suit /shared/mrfil-data/pcamach2/spm_reorient/no_spm_reorient/derivatives/dtipipeline/

#cd /shared/mrfil-data/pcamach2/spm_reorient/test/
MPRAGEDIR=$1
cd $MPRAGEDIR
gunzip IMG_brain.nii.gz

# /shared/mrfil-data/pcamach2/spm12
SPMDIR=$2
SPMOLD=$3
# /shared/mrfil-data/pcamach2/auto_reorient
AR=$4

# /shared/mrfil-data/pcamach2/suit_inc
SUITSCRIPT=$5

sub=$6
sesh=$7
suitPath=$8
imgPath=$9
#suit_inc('sub-FIB006','ses-01','/shared/mrfil-data/pcamach2/suit','/shared/mrfil-data/pcamach2/spm_reorient/no_spm_reorient/derivatives/dtipipeline/')

matlab -nodisplay -nosplash -nodesktop -r "addpath('/shared/mrfil-data/pcamach2');addpath('$SPMDIR');addpath('$SPMOLD');$AR('IMG_brain.nii');$SUITSCRIPT('$sub','$sesh','$suitPath','$imgPath');exit;" | tail -n +11

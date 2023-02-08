#!/bin/bash

#Created by Paul Sharp and Brad Sutton 10-7-2016

# This batch file runs creates structural connectomes for any parcellation on
# raw DTI data.

# MUST READ BELOW TO MAKE SURE SCRIPT RUNS:
# Need a SCRIPTS_DIR with all approriate scripts
# Make sure FreeSurfer recon-all is run first


# !!!!!!!! NOTE: SUBJECTS_DIR must be the temp SUBJECTS DIR, NOT THE ONE ON THE SERVER!
#  SUBJECTS_DIR must be the /usr/local/freesurfer   !!!!!
# !!!!!!!!   THERE IS A RM -RF SUBJECT_DIR
#
# This one just uses freesurfer parcs
#
# Adapted by Paul B Camacho for use with QSIPrep preprocessing and CUDA acceleration

source /scripts/connectome_variables_fsonly.cfg

sublist=$1
session=$2
mkdir ${DATA_DIR}

export SCRIPTS_DIR
export NETWORK_DRIVE
export parcellation_number
export parcellation_labels_file

chmod ugo+rwx ${SUBJECTS_DIR}

for sub in ${sublist}
do

  export sub
  #ORIGINAL DATA LOCATION
  #location of DTI files
  STUDY_DATDIR=${STUDY_DATA_DIR}/${sub}/${session}/Analyze/${STUDY_DTIPTH}/
  #location of bedpost directory
  STUDY_BEDPOSTDIR=${RESULTS_DIR}/${sub}/${session}/DTI.bedpostX/
  #location of freesurfer subject data
  STUDY_FSDIR=${STUDY_SUBJECTS_DIR}/
  #location of QSIPrep preprocessing + reorient_fslstd
  STUDY_QSIPREPDIR=${QSIPREP_DIR}
  #location of connectome output
  STUDY_CONDIR=${RESULTS_DIR}/${sub}/${session}/${STUDY_CONN_PATH}

#local TEMPORARY data locations for processing                                             
  DATDIR=${DATA_DIR}/${sub}/${session}/DTI/analyses
  RESDIR=${DATA_DIR}/${sub}/${session}/ConnFSL
  FSDIR=${DATA_DIR}
  DATBEDPOSTDIR=${DATA_DIR}/${sub}/${session}/DTI/analyses.bedpostX/

  # MOVE DATA OVER TO TEMP DIRECTORIES
  mkdir -p "${DATDIR}"
  mkdir -p "${DATBEDPOSTDIR}"  # We are running bedpost ourselves

  export STUDY_DATDIR
  export STUDY_FSDIR
  export DATDIR
  export RESDIR

  source ${SCRIPTS_DIR}/grab_data.sh

  #local results directory
  mkdir -p "${RESDIR}"
  cd ${RESDIR}
  mkdir -p "${RESDIR}/DTIMASK"
  #copy files from qsirecon fsl reorient to DATADIR
  cp ${STUDY_QSIPREPDIR}/${sub}/${session}/dwi/${sub}_${session}_run-1_space-T1w_desc-preproc_fslstd_dwi.bval ${DATDIR}/bvals
  cp ${STUDY_QSIPREPDIR}/${sub}/${session}/dwi/${sub}_${session}_run-1_space-T1w_desc-preproc_fslstd_dwi.bvec ${DATDIR}/bvecs
  cp ${STUDY_QSIPREPDIR}/${sub}/${session}/dwi/${sub}_${session}_run-1_space-T1w_desc-preproc_fslstd_dwi.nii.gz ${DATDIR}/data.nii.gz
  cp ${STUDY_QSIPREPDIR}/${sub}/${session}/dwi/${sub}_${session}_run-1_space-T1w_desc-preproc_fslstd_mask.nii.gz ${DATDIR}/nodif_brain_mask.nii.gz
  cp ${STUDY_QSIPREPDIR}/${sub}/${session}/dwi/${sub}_${session}_run-1_space-T1w_desc-preproc_desc-aal116_atlas.nii.gz ${DATDIR}/aal116_atlas.nii.gz
  #reorient run-specific atlas image to FSL standard convention
  fslreorient2std ${DATDIR}/aal116_atlas.nii.gz ${DATDIR}/aal116_atlas_fslstd.nii.gz
  #mask get nodif from qsiprep preproc dwi and brain extract with qsirecon brain mask to make ${DATDIR}/nodif_brain.nii.gz
  fslroi ${DATDIR}/data.nii.gz ${DATDIR}/nodif.nii.gz 0 1
  fslmaths ${DATDIR}/nodif.nii.gz -mas ${DATDIR}/nodif_brain_mask.nii.gz ${DATDIR}/nodif_brain.nii.gz 
  
  
  #Find native space preprocessed T1w and aparcaseg_dseg from fMRIPrep
  cd ${STUDY_SUBJECTS_DIR}/${sub}/${session}/anat
  #get only the first image - this is the non-MNI space image
  preproc=$(ls ${sub}_${session}*_desc-preproc_T1w.nii.gz | head -n 1)
  echo "Using ${preproc} as IMG_brain"
  #Uses reoriented AAL116 from qsiprep outputs as parcellation
  parc="${DATDIR}/aal116_atlas_fslstd.nii.gz"
  echo "Using ${parc} as AAL116 atlas parcellation image"
  #copy preproc T1w to tmp processing dir
  cp ${preproc} ${DATDIR}/IMG_brain.nii.gz

echo ${DATA_DIR}                                                                                                           
echo ${SCRIPTS_DIR}
echo ${parcellation_number}
echo ${parcellation_labels_file}                                                                                    
echo ${SUBJECTS_DIR}
echo ${STUDY_DATA_DIR}
echo ${STUDY_DATDIR}
echo ${RESULTS_DIR}
echo ${STUDY_BEDPOSTDIR}
echo ${STUDY_SUBJECTS_DIR}
echo ${STUDY_FSDIR}
echo ${RESULTS_DIR}
echo ${STUDY_CONDIR}
echo ${DATDIR}
echo ${RESDIR}
echo ${DATBEDPOSTDIR} 

cd ${RESDIR}
echo $RESDIR
echo $FREESURFER_HOME
echo $RESDIR >> resdir.txt

parcs=${STUDY_SUBJECTS_DIR}/${sub}/${session}/anat/${parc}
export parcellation_image=${parc}
echo ${parcellation_image}

#flirt -cost mutualinfo -dof 6 -in ${DATDIR}/nodif_brain.nii.gz -ref ${DATDIR}/IMG_brain.nii.gz -omat diff2rage.mat -out diff_in_rage.nii.gz
#convert_xfm -omat rage2diff.mat -inverse diff2rage.mat
#flirt -interp nearestneighbour -in ${parcs} -ref ${DATDIR}/nodif_brain.nii.gz -applyxfm -init rage2diff.mat -out FS_to_DTI.nii.gz

cd ${RESDIR}  # should still be in there, but just to make sure                                                      

# echo "Running Bedpost with -n 3"
bedpostx_gpu "$DATDIR" -n 3

# create CSF mask
source ${SCRIPTS_DIR}/CSF_mask.sh
# dev note: do we need to make CSF_mask? we might have usable output from FS or QSIPrep

#Generate ROIs for tractography AND get volumes of each ROI for later weighting in a CSV file
# change to get ROIs from AAL116 label file
python ${SCRIPTS_DIR}/AAl116_ROIs_fsonly.py

cd ${RESDIR}

cp ${SCRIPTS_DIR}/maskCat ${RESDIR}/DTIMASK/
cd ${DATBEDPOSTDIR}


#Run probtrackx
echo "Running Probtrackx2"
probtrackx2_gpu --network -x "$RESDIR"/masks.txt -l -c 0.2 -S 2000 --steplength=0.5 -P 5000 --fibthresh=0.01 --distthresh=0.0 --avoid="$RESDIR"/CSFmask.nii.gz --sampvox=0.0 --forcedir --opd -s "$DATBEDPOSTDIR"merged -m "$DATBEDPOSTDIR"nodif_brain_mask --dir="$RESDIR"                                                                                                                                                                                                                               

cd ${RESDIR}

#convert naming of raw connectome file
  python ${SCRIPTS_DIR}/FSL_convert_fdtmatrix_csv_fsonly.py
#compute transformation on Connectivity matrix
  python ${SCRIPTS_DIR}/volume_weight_connectome_fsonly.py
#add column headers for connectome file which is required for visualization
  python ${SCRIPTS_DIR}/add_column_headers_fsonly.py
  source ${SCRIPTS_DIR}/push_results.sh
done


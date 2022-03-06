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
  QSIPREPDIR=${DATA_DIR}/${sub}/${session}/qsiprep_out/
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
  #copy files from qsiprep fsl reorient to DATADIR
  cp ${STUDY_QSIPREPDIR}/${sub}/${session}/dwi/${sub}_${session}_run-1_space-T1w_desc-preproc_dwi.bval ${DATDIR}/${sub}/${session}/bvals
  cp ${STUDY_QSIPREPDIR}/${sub}/${session}/dwi/${sub}_${session}_run-1_space-T1w_desc-preproc_dwi.bvec ${DATDIR}/${sub}/${session}/bvecs
  cp ${STUDY_QSIPREPDIR}/${sub}/${session}/dwi/${sub}_${session}_run-1_space-T1w_desc-preproc_dwi.nii.gz ${DATDIR}/${sub}/${session}/data.nii.gz
  cp ${STUDY_QSIPREPDIR}/${sub}/${session}/dwi/${sub}_${session}_run-1_space-T1w_desc-brain_mask.nii.gz ${DATDIR}/${sub}/${session}/nodif_brain_mask.nii.gz
  cp ${STUDY_QSIPREPDIR}/${sub}/${session}/dwi/${sub}_${session}_run-1_space-T1w_desc-dwiref.nii.gz ${DATDIR}/${sub}/${session}/dwiref.nii.gz
  #mask dwiref with brain mask to make ${DATDIR}/${sub}/${session}/nodif_brain.nii.gz
  fslmaths ${DATDIR}/${sub}/${session}/dwiref.nii.gz -mas ${DATDIR}/${sub}/${session}/nodif_brain_mask.nii.gz ${DATDIR}/${sub}/${session}/nodif_brain.nii.gz 
  #copy Freesurfer preproc T1w to tmp processing dir
  cp ${STUDY_FSDIR}${sub}/${session}/anat/${sub}_${session}_acq-m2prageunidenoised_desc-preproc_T1w.nii.gz ${DATDIR}/${sub}/${session}/IMG_brain.nii.gz

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



tester=${STUDY_FSDIR}${sub}/anat/${sub}_${session}_acq-m2prageunidenoised_desc-aparcaseg_dseg.nii.gz
echo ${tester}
export parcellation_image=${sub}_desc-aparcaseg_dseg.nii.gz
echo ${parcellation_image}

flirt -cost mutualinfo -dof 6 -in ${DATDIR}/nodif_brain.nii.gz -ref ${DATDIR}/${sub}/${session}/IMG_brain.nii.gz -omat diff2rage.mat -out diff_in_rage.nii.gz
convert_xfm -omat rage2diff.mat -inverse diff2rage.mat
flirt -interp nearestneighbour -in ${tester} -ref ${DATDIR}/nodif_brain.nii.gz -applyxfm -init rage2diff.mat -out FS_to_DTI.nii.gz

cd ${RESDIR}  # should still be in there, but just to make sure                                                      

# echo "Running Bedpost"
bedpostx_gpu "$DATDIR" -n 3

# create CSF mask
source ${SCRIPTS_DIR}/CSF_mask.sh
# dev note: do we need to make CSF_mask? we might have usable output from FS or QSIPrep

#Generate ROIs for tractography AND get volumes of each ROI for later weighting in a CSV file
python ${SCRIPTS_DIR}/Freesurfer_ROIs_fsonly.py

cd ${RESDIR}

fslmaths Left-Cerebellar-Cortex.nii.gz -mas ${SCRIPTS_DIR}/not_cereb.nii.gz Left-Cerebellar-Cortex.nii.gz
fslmaths Right-Cerebellar-Cortex.nii.gz -mas ${SCRIPTS_DIR}/not_cereb.nii.gz Right-Cerebellar-Cortex.nii.gz
fslstats Left-Cerebellar-Cortex.nii.gz -V > tmproivolumeL.txt
fslstats Right-Cerebellar-Cortex.nii.gz -V > tmproivolumeR.txt

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


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

source /scripts/connectome_variables_TEST_PRE.cfg

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
  #location of connectome output
  STUDY_CONDIR=${RESULTS_DIR}/${sub}/${session}/${STUDY_CONN_PATH}

#local TEMPORARY data locations for processing                                             
  DATDIR=${DATA_DIR}/${sub}/${session}/DTI/analyses/
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
   # PROCESS DTI - make sure nodif brain mask is right size, etc.
   cd ${DATDIR}                                                                                                            
   fslroi "$DTI_raw" nodif 0 1
   bet nodif nodif_brain -f 0.1 -m
   eddy_correct "$DTI_raw" data_corr.nii.gz 0
   mv data_corr.nii.gz data.nii.gz
   bash fdt_rotate_bvecs bvecs bvecs_new data_corr.ecclog
   mv bvecs bvecs_old
   cp bvecs_new bvecs


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



tester=${STUDY_FSDIR}${sub}/anat/${sub}_desc-aparcaseg_dseg.nii.gz
echo ${tester}
export parcellation_image=${sub}_desc-aparcaseg_dseg.nii.gz
echo ${parcellation_image}

flirt -cost mutualinfo -dof 6 -in ${DATDIR}nodif_brain.nii.gz -ref ${STUDY_DATA_DIR}/${sub}/${session}/Analyze/MPRAGE/IMG_brain.nii -omat FSdiff2rage.mat -out FSdiff_in_rage.nii.gz
convert_xfm -omat FSrage2diff.mat -inverse FSdiff2rage.mat
flirt -interp nearestneighbour -in ${tester} -ref ${DATDIR}nodif_brain.nii.gz -applyxfm -init FSrage2diff.mat -out FS_to_DTI.nii.gz

   cd ${RESDIR}  # should still be in there, but just to make sure                                                      

#    echo "Running Bedpost"
    bedpostx "$DATDIR" -n 2


   # create CSF mask
   source ${SCRIPTS_DIR}/CSF_mask.sh

   #Generate ROIs for tractography AND get volumes of each ROI for later weighting in a CSV file
   python ${SCRIPTS_DIR}/Freesurfer_ROIs.py

cd ${RESDIR}

cp ${SCRIPTS_DIR}/maskCat ${RESDIR}/DTIMASK/

SUITS_parc_file=${STUDY_DATA_DIR}/${sub}/${session}/Analyze/MPRAGE/iw_Lobules-SUIT_u_a_IMG_brain_seg1.nii
echo ${SUITS_parc_file}
SUITS_names=${SCRIPTS_DIR}/SUIT_ROI_names.txt
SUITS_offset=3000
DTIwholebrainMASK=${DATDIR}nodif_brain_mask.nii.gz
echo ${DTIwholebrainMASK}
FScat=${RESDIR}/FS_to_DTI.nii.gz
echo ${FScat}
DTIFScatDIR=${RESDIR}/DTIMASK
mkdir ${DTIFScatDIR}/rois
cp ${RESDIR}/*.nii.gz ${DTIFScatDIR}/rois
cd ${DTIFScatDIR}/rois
rm CSFmask.nii.gz
rm fdt_paths.nii.gz
rm FS_to_DTI.nii.gz
rm FSdiff_in_rage.nii.gz
rm rage_in_free.nii.gz
rm roi_offset.nii.gz
rm diff_in_rage.nii.gz
cd ${DTIFScatDIR}
./maskCat ./

cd ${RESDIR}

flirt -cost mutualinfo -dof 6 -in ${DATDIR}nodif_brain.nii.gz -ref ${STUDY_DATA_DIR}/${sub}/${session}/Analyze/MPRAGE/IMG_brain.nii -omat diff2rage.mat -out diff_in_rage.nii.gz  
convert_xfm -omat rage2diff.mat -inverse diff2rage.mat
flirt -interp nearestneighbour -in ${SUITS_parc_file} -ref ${DATDIR}nodif_brain.nii.gz -applyxfm -init rage2diff.mat -out cereb_atlas_DTI.nii.gz

fslmaths ${DTIFScatDIR}/mask.nii.gz -thr 0.5 -bin binFScatDTI
fslmaths binFScatDTI -sub 1 -abs antiGMmaskDTI
fslmaths cereb_atlas_DTI.nii.gz -mas antiGMmaskDTI maskedSuitsDTI.nii.gz

fslmaths ${DTIwholebrainMASK} -thr 0.5 -bin binNODIFMASK
fslmaths binNODIFMASK -sub 1 -abs antiNODIFMASK
fslmaths maskedSuitsDTI.nii.gz -mas antiNODIFMASK outofbounds_SuitsDTI.nii.gz

fslmaths outofbounds_SuitsDTI.nii.gz -thr 0.5 -bin binOutOfBounds
fslmaths binOutOfBounds -sub 1 -abs antiOutOfBounds
fslmaths maskedSuitsDTI.nii.gz -mas antiOutOfBounds extraMasked_SuitsDTI.nii.gz

cd ${RESDIR}

roi_num=1
while read roi_name_tmp; do
    roi_lowthresh=$( echo "scale=2; $roi_num - 0.5" | bc )
    roi_highthresh=$( echo "scale=2; $roi_num + 0.5" | bc )
    echo "$roi_lowthresh"
    echo "$roi_name_tmp"
    fslmaths maskedSuitsDTI.nii.gz -thr $roi_lowthresh -uthr $roi_highthresh roitmp
    fslmaths roitmp -div $roi_num -mul $SUITS_offset roi_offset

    fslstats roitmp.nii.gz -V > roivolume.txt
    roi_volume_tmp=$( awk '{printf int($1); }' roivolume.txt )
    echo $roi_volume_tmp
    # read in volumes from suit
    echo "${roi_name_tmp},${roi_volume_tmp}" >> ROI_Volumes.csv
    ((roi_num+=1))

    fslmaths roitmp -add roi_offset roitmp
    mv roitmp.nii.gz ${roi_name_tmp}.nii.gz

    echo "${RESDIR}/${roi_name_tmp}.nii.gz" >> masks.txt

done <$SUITS_names

  cd ${DATBEDPOSTDIR}
  export parcellation_number=116
  export parcellation_labels_file=aparc_cort_subcort_labels_add.txt

  echo $parcellation_number                                                                                                                                                                                                    
  echo $parcellation_labels_file
 #Run probtrackx
  echo "Running Probtrackx2"
  probtrackx2 --network -x "$RESDIR"/masks.txt -l -c 0.2 -S 2000 --steplength=0.5 -P 5000 --fibthresh=0.01 --distthresh=0.0 --avoid="$RESDIR"/CSFmask.nii.gz --sampvox=0.0 --forcedir --opd -s "$DATBEDPOSTDIR"merged -m "$DATBEDPOSTDIR"nodif_brain_mask --dir="$RESDIR"                                                                                                                                                                                                                               

cd ${RESDIR}

  source /scripts/connectome_variables_withSUITS_PRE.cfg

#convert naming of raw connectome file
  python ${SCRIPTS_DIR}/FSL_convert_fdtmatrix_csv.py
#compute transformation on Connectivity matrix
  python ${SCRIPTS_DIR}/volume_weight_connectome.py
#add column headers for connectome file which is required for visualization
  python ${SCRIPTS_DIR}/add_column_headers.py

  source ${SCRIPTS_DIR}/push_results.sh
done

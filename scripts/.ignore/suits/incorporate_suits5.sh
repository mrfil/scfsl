#!/bin/bash
SUB=FIBMS_006
RESDIR=/Users/pcamach2/Downloads/BollaertData/FIBMS/${SUB}/ConnFSL
SUITS_parc_file=/Users/pcamach2/Downloads/BollaertData/FIBMS/${SUB}/Analyze/MPRAGE/iw_Lobules-SUIT_u_a_IMG_brain2_seg1.nii
SUITS_names=/Users/pcamach2/Downloads/TDP/Scripts/StructConFSL_withSUITS/SUIT_ROI_names.txt
SUITS_offset=3000;
DTIwholebrainMASK=/Users/pcamach2/Downloads/BollaertData/FIBMS/${SUB}/Analyze/DTI/nodif_brain_mask.nii.gz
FScat=/Users/pcamach2/Downloads/BollaertData/FIBMS/${SUB}/freeMask/mask.nii.gz #this is an output from rsfc scripts, could run the python script that version of Freesurfer_ROIs.py to generate
mkdir ${RESDIR}/DTIMASK
DTIFScatDIR=${RESDIR}/DTIMASK
cp ./maskCat ${DTIFScatDIR}
mkdir ${DTIFScatDIR}/rois
cp ${RESDIR}/*.nii.gz ${DTIFScatDIR}/rois
cd ${DTIFScatDIR}/rois
#clean out niftis that are not masks from FS parcels
rm CSFmask.nii.gz
rm fdt_paths.nii.gz
rm FS_to_DTI.nii.gz
rm rage_in_free.nii.gz
rm roi_offset.nii.gz
rm maskedSuits.nii.gz
rm maskedSuitsDTI.nii.gz
rm maskedSuitsRAGE.nii.gz
rm diff_in_rage.nii.gz
rm antiGMmask.nii.gz
rm antiGMmaskDTI.nii.gz
rm binFScatDTI.nii.gz
rm binFScatRAGE.nii.gz
rm cereb_atlas_DTI.nii.gz
rm FScatRAGE.nii.gz
rm Left_I_IV.nii.gz
rm Right_I_IV.nii.gz
rm Left_V.nii.gz
rm Right_V.nii.gz
rm Left_VI.nii.gz
rm Vermis_VI.nii.gz
rm Right_VI.nii.gz
rm Left_CrusI.nii.gz
rm Vermis_CrusI.nii.gz
rm Right_CrusI.nii.gz
rm Left_CrusII.nii.gz
rm Vermis_CrusII.nii.gz
rm Right_CrusII.nii.gz
rm Left_VIIb.nii.gz
rm Vermis_VIIb.nii.gz
rm Right_VIIb.nii.gz
rm Left_VIIIa.nii.gz
rm Vermis_VIIIa.nii.gz
rm Right_VIIIa.nii.gz
rm Left_VIIIb.nii.gz
rm Vermis_VIIIb.nii.gz
rm Right_VIIIb.nii.gz
rm Left_IX.nii.gz
rm Vermis_IX.nii.gz
rm Right_IX.nii.gz
rm Left_X.nii.gz
rm Vermis_X.nii.gz
rm Right_X.nii.gz
rm Left_Dentate.nii.gz
rm Right_Dentate.nii.gz
rm Left_Interposed.nii.gz
rm Right_Interposed.nii.gz
rm Left_Fastigial.nii.gz
rm Right_Fastigial.nii.gz
cd ${DTIFScatDIR}
./maskCat ./

cd ${RESDIR}

#mri_convert --in_type mgz --out_type nii --out_orientation RAS /Users/pcamach2/Downloads/BollaertData/FIBMS/Freesurfersubs/${SUB}/mri/brain.mgz /Users/pcamach2/Downloads/BollaertData/FIBMS/Freesurfersubs/${SUB}/mri/brain.nii.gz
#flirt -cost mutualinfo -in /Users/pcamach2/Downloads/BollaertData/FIBMS/${SUB}/Analyze/MPRAGE/IMG_brain.nii.gz -ref /Users/pcamach2/Downloads/BollaertData/FIBMS/Freesurfersubs/${SUB}/mri/brain.nii.gz -omat rage2free.mat -out rage_in_free.nii.gz 
#convert_xfm -omat free2rage.mat -inverse rage2free.mat
#flirt -interp nearestneighbour -in ${FScat} -ref /Users/pcamach2/Downloads/BollaertData/FIBMS/${SUB}/Analyze/MPRAGE/IMG_brain.nii.gz -applyxfm -init free2rage.mat -out FScatRAGE.nii.gz


cd ${RESDIR}

#fslmaths FScatRAGE.nii.gz -thr 0.5 -bin binFScatRAGE
#fslmaths binFScatRAGE -sub 1 -abs antiGMmask
#fslmaths ${SUITS_parc_file} -mas antiGMmask maskedSuitsRAGE

flirt -cost mutualinfo -dof 6 -in ../Analyze/DTI/nodif_brain.nii.gz -ref ../Analyze/MPRAGE/IMG_brain2.nii -omat diff2rage.mat -out diff_in_rage.nii.gz 
convert_xfm -omat rage2diff.mat -inverse diff2rage.mat
flirt -interp nearestneighbour -in ${SUITS_parc_file} -ref ../Analyze/DTI/nodif_brain.nii.gz -applyxfm -init rage2diff.mat -out cereb_atlas_DTI.nii.gz

fslmaths ${DTIFScatDIR}/mask.nii.gz -thr 0.5 -bin binFScatDTI
fslmaths binFScatDTI -sub 1 -abs antiGMmaskDTI
fslmaths cereb_atlas_DTI.nii.gz -mas antiGMmaskDTI maskedSuitsDTI.nii.gz

fslmaths ${DTIwholebrainMASK} -thr 0.5 -bin binNODIFMASK
fslmaths binNODIFMASK -sub 1 -abs antiNODIFMASK
fslmaths maskedSuitsDTI.nii.gz -mas antiNODIFMASK outofbounds_SuitsDTI.nii.gz

fslmaths outofbounds_SuitsDTI.nii.gz -thr 0.5 -bin binOutOfBounds
fslmaths binOutOfBounds -sub 1 -abs antiOutOfBounds
fslmaths maskedSuitsDTI.nii.gz -mas antiOutOfBounds extraMasked_SuitsDTI.nii.gz

#rm masks_tmp.txt
#rm ROI_Volumes_tmp.csv
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
    # read in volumes form suites
    echo "${roi_name_tmp},${roi_volume_tmp}" >> ROI_Volumes.csv
    ((roi_num+=1))      
    
    fslmaths roitmp -add roi_offset roitmp
    mv roitmp.nii.gz ${roi_name_tmp}.nii.gz 
    
    echo "${RESDIR}/${roi_name_tmp}.nii.gz" >> masks.txt
    
    

done <$SUITS_names    

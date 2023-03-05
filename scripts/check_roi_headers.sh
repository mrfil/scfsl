#!/bin/bash
ROI=$1
target=$2 # raw image/ standard image/T1 image, depend on where roi came from.
result_path=$3
# this script is for probtrackx2_gpu, for every roi feed into probtrack2 should have the same qform/sform as raw image or standard image.
mkdir -p $result_path
ROI_name0=`basename $ROI`
ROI_name=${ROI_name0%.nii.gz}
target_name0=`basename $target`
target_name=${target_name0%.nii.gz}
ROI_checked=$result_path/${ROI_name}_hdchecked.nii.gz
cp $ROI $ROI_checked
fslhd_ROI=$result_path/${ROI_name}.fslhd.txt
fslhd_target=$result_path/${target_name}.fslhd.txt
if [ -f $fslhd_target ]; then
        echo $target_name fslhd file exist!
else
        fslhd $target>$fslhd_target
        echo $target_name fslhd file generated.
fi
if [ -f $fslhd_ROI ]; then
        echo $ROI_name fslhd file exist!
else
        fslhd $ROI>$fslhd_ROI
        echo $ROI_name fslhd file generated.
fi
diff $fslhd_target $fslhd_ROI > $result_path/${ROI_name}_${target_name}.diff.txt
ROI_target_diff=`grep -Fxvf $fslhd_target $fslhd_ROI`
if [[ $ROI_target_diff == *"qform"* ]] || [[ $ROI_target_diff == *"sform"* ]] ; then
        echo $ROI and $target are different in qform or sform!
        fslcpgeom $target $ROI_checked -d
        echo copy geom information qform/sform from $target .
fi
echo please use $ROI_checked in probtrackx2.

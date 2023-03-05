#Creates ROI masks fom schaefer100x7 parcellation (which has previous been transformed to DTI Space)

import os
import nipype.interfaces.fsl as fsl
import csv

parcellation_num = int(100)
parcellation_labels_file = os.environ['parcellation_labels_file']

schaefer100x7_Regions_dict = {}
schaefer100x7_Regions_list=[]

with open('{}/{}'.format(os.environ['SCRIPTS_DIR'],parcellation_labels_file), 'r') as f:
	for line in range(parcellation_num):
		current_line = f.readline()
		if line == parcellation_num-1:
			current_line = current_line.split()
		else:
			current_line = current_line[:-1]
			current_line = current_line.split()
		schaefer100x7_Regions_dict[current_line[1]]=int(current_line[0])
		schaefer100x7_Regions_list.append(current_line[1])

#create text file with all ROI masks
with open('masks.txt', 'w') as f:
	for roi in schaefer100x7_Regions_list:
		f.write('{}/{}.nii.gz\n'.format(os.environ['RESDIR'], roi))

#create text file with all ROI masks for header checking
with open('masks_checked.txt', 'w') as f:
        for roi in schaefer100x7_Regions_list:
                f.write('{}/checked_headers/{}_hdchecked.nii.gz\n'.format(os.environ['RESDIR'], roi))

ROI_volumes_csv=[]

#create each ROI niftii file
for index in range(parcellation_num):           # index goes 1:70
	# print 'Region Number {}'.format(index+1)
	x = schaefer100x7_Regions_dict[schaefer100x7_Regions_list[index]]
	get_ROI = fsl.maths.Threshold()
	get_ROI.inputs.in_file = 'schaefer100x7_atlas_fslstd.nii.gz'
	get_ROI.inputs.thresh = x-0.5
	get_ROI.inputs.args = '-uthr {}'.format(x+0.5)
	get_ROI.inputs.out_file = '{}.nii.gz'.format(schaefer100x7_Regions_list[index])
	get_ROI.run()

	#get volume
	current_ROI_file='{}.nii.gz'.format(schaefer100x7_Regions_list[index])

	get_volume_ROI = fsl.ImageStats(in_file=current_ROI_file, op_string='-V > ROI_volumes.txt')
	get_volume_ROI.run()

	roi_volumes_line=[schaefer100x7_Regions_list[index]]
	with open('ROI_volumes.txt', 'r') as f:
		lines=f.readlines()
		line=lines[0].split()
	roi_volumes_line.append(line[0])
	ROI_volumes_csv.append(roi_volumes_line)

with open('ROI_Volumes.csv', 'w') as f:
	writer = csv.writer(f)
	writer.writerows(ROI_volumes_csv)

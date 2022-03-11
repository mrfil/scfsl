%   Paul Camacho worked on this script
%   Before running;
%       Unzip MPRAGE.nii.gz to MPRAGE.nii
%       Iinitialize SPM12 with "spm fmri"
%       Display MPRAGE.nii and find Anterior Commisure, set Origin to location, and reorient to minimize error of Lobules map inversion in the final step of this script

function suit_inc(sub,sesh,suitPath,imagePath)

% sub = 'sub-FIB006'
% sesh = 'ses-01'
% suitPath = '/shared/mrfil-data/pcamach2/suit/' %%%path to SUIT directory
% imagePath = '/shared/mrfil-data/pcamach2/spm_reorient/no_spm_reorient/derivatives/dtipipeline/' %%% path to directory for subject images
MPRAGE = 'IMG_brain' %%%name of MPRAGE without .nii suffix

spm fmri

%%%Segmentation and isolation of cerebellum
suit_isolate_seg({(strcat(imagePath,sub,'/',sesh,'/Analyze/MPRAGE/',MPRAGE,'.nii'))})

%%%Normalization by Dartel Method
job.subjND.gray = {[(strcat(imagePath,sub,'/',sesh,'/Analyze/MPRAGE/',MPRAGE,'_seg1.nii'))]};
job.subjND.white = {[(strcat(imagePath,sub,'/',sesh,'/Analyze/MPRAGE/',MPRAGE,'_seg2.nii'))]};
job.subjND.isolation = {[(strcat(imagePath,sub,'/',sesh,'/Analyze/MPRAGE/','c_',MPRAGE,'_pcereb.nii'))]};
suit_normalize_dartel(job)

%%%Reslice to SUIT space
job.subj.affineTr = {[(strcat(imagePath,sub,'/',sesh,'/Analyze/MPRAGE/','Affine_',MPRAGE,'_seg1'))]};
job.subj.flowfield = {[(strcat(imagePath,sub,'/',sesh,'/Analyze/MPRAGE/','u_a_',MPRAGE,'_seg1.nii'))]};
job.subj.mask = {[(strcat(imagePath,sub,'/',sesh,'/Analyze/MPRAGE/','c_',MPRAGE,'_pcereb.nii'))]};
job.subj.resample = {[(strcat(imagePath, sub,'/',sesh,'/Analyze/MPRAGE/',MPRAGE,'.nii'))]};
suit_reslice_dartel(job)

% %%%Invert Cerebellum SUIT atlas to subject space using Dartel method
job.Affine = {[(strcat(imagePath,sub,'/',sesh,'/Analyze/MPRAGE/','Affine_',MPRAGE,'_seg1'))]};
job.flowfield = {[(strcat(imagePath,sub,'/',sesh,'/Analyze/MPRAGE/','u_a_',MPRAGE,'_seg1.nii'))]};
job.resample = {[(strcat(suitPath,'\atlasesSUIT\','Lobules-SUIT.nii'))]};
job.ref = {[(strcat(imagePath,sub,'/',sesh,'/Analyze/MPRAGE/', MPRAGE,'.nii'))]};


suit_reslice_dartel_inv(job)




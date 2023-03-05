
%%% Select the folder containing the .csv results of all your participants
%%%     -usually ResStructConn
%%%
%%% a paul camacho joint

mainfolder = uigetdir;
subfolders = dir(strcat(mainfolder,"/*/*/Conn*"));
subfolders = subfolders([subfolders.isdir] & ~startsWith({subfolders.name},'.'));

%%% Set this before running
numROIs = 100;

for i = 1:length(subfolders)
    files = dir(fullfile(mainfolder,"/*/*",subfolders(i).name,'*VolumeWeighted.csv'));
    
    NBSallsubs = zeros(length(files),4);
    NBSroiAllSubs = zeros(numROIs, 3, length(files));
   
    for k = 1:length(files)
        fid = fopen(fullfile(files(k).folder,files(k).name)); 
              
              delimiterIn = ",";
              net_mat = importdata(fullfile(files(k).folder,files(k).name),delimiterIn);
              
              %%%Normalization by maximum number of streamlines arg from
              %%%probtrackx run
              max_num_streamlines = 5000;
              net_mat_norm = net_mat/max_num_streamlines;
              
              %%%Ensures there are no extra lines
              if length(net_mat_norm) > numROIs
                sprintf('Limiting N to numROIs, please check your csv for errors \n')
                net_mat_norm = net_mat_norm(1:numROIs,1:numROIs);
              end
              
              %%%Computes Network-Based Statistics using the BCT 
              %%% 
              %%% Add the downloaded folder to path first
              
              %%%Whole Brain Measures              
              GlobalEfficiency = efficiency_wei(net_mat_norm, 0);
              MeanClusteringCoeff = mean(clustering_coef_wu(net_mat_norm));
              MeanStrength = mean(strengths_und(net_mat_norm));
              
              NBSmat = zeros(1,3);
              NBSmat(1,1) = GlobalEfficiency;
              NBSmat(1,2) = MeanClusteringCoeff;
              NBSmat(1,3) = MeanStrength;
              
              NBSmatS = zeros(1,4);
              iD = k;
              NBSmatS(1,1) = iD; 
              NBSmatS(1,2:end) = NBSmat;
              NBSallsubs(k,:) = NBSmatS;
              
              %%%ROI-Wise Measures
              
              LocalEfficiency = efficiency_wei(net_mat_norm,2);
              ClusteringCoeff = clustering_coef_wu(net_mat_norm);
              Strength = strengths_und(net_mat_norm);
              Strength = Strength.';
              
              NBSmatROI = zeros(length(Strength),3);
              NBSmatROI(:,1) = LocalEfficiency;
              NBSmatROI(:,2) = ClusteringCoeff;
              NBSmatROI(:,3) = Strength;
              
              %Adds labels to save out per subject tables
              roilabels = ["Left_Thalamus_Proper",'Left_Caudate','Left_Putamen','Left_Pallidum','Left_Hippocampus','Left_Amygdala','Left_Accumbens_area','Right_Thalamus_Proper','Right_Caudate','Right_Putamen','Right_Pallidum','Right_Hippocampus','Right_Amygdala','Right_Accumbens_area','ctx_lh_bankssts','ctx_lh_caudalanteriorcingulate','ctx_lh_caudalmiddlefrontal','ctx_lh_cuneus','ctx_lh_entorhinal','ctx_lh_fusiform','ctx_lh_inferiorparietal','ctx_lh_inferiortemporal','ctx_lh_isthmuscingulate','ctx_lh_lateraloccipital','ctx_lh_lateralorbitofrontal','ctx_lh_lingual','ctx_lh_medialorbitofrontal','ctx_lh_middletemporal','ctx_lh_parahippocampal','ctx_lh_paracentral','ctx_lh_parsopercularis','ctx_lh_parsorbitalis','ctx_lh_parstriangularis','ctx_lh_pericalcarine','ctx_lh_postcentral','ctx_lh_posteriorcingulate','ctx_lh_precentral','ctx_lh_precuneus','ctx_lh_rostralanteriorcingulate','ctx_lh_rostralmiddlefrontal','ctx_lh_superiorfrontal','ctx_lh_superiorparietal','ctx_lh_superiortemporal','ctx_lh_supramarginal','ctx_lh_frontalpole','ctx_lh_temporalpole','ctx_lh_transversetemporal','ctx_lh_insula','ctx_rh_bankssts','ctx_rh_caudalanteriorcingulate','ctx_rh_caudalmiddlefrontal','ctx_rh_cuneus','ctx_rh_entorhinal','ctx_rh_fusiform','ctx_rh_inferiorparietal','ctx_rh_inferiortemporal','ctx_rh_isthmuscingulate','ctx_rh_lateraloccipital','ctx_rh_lateralorbitofrontal','ctx_rh_lingual','ctx_rh_medialorbitofrontal','ctx_rh_middletemporal','ctx_rh_parahippocampal','ctx_rh_paracentral','ctx_rh_parsopercularis','ctx_rh_parsorbitalis','ctx_rh_parstriangularis','ctx_rh_pericalcarine','ctx_rh_postcentral','ctx_rh_posteriorcingulate','ctx_rh_precentral','ctx_rh_precuneus','ctx_rh_rostralanteriorcingulate','ctx_rh_rostralmiddlefrontal','ctx_rh_superiorfrontal','ctx_rh_superiorparietal','ctx_rh_superiortemporal','ctx_rh_supramarginal','ctx_rh_frontalpole','ctx_rh_temporalpole','ctx_rh_transversetemporal','ctx_rh_insula'];
              ROI = roilabels.';
              header1 = {'LocalEfficiency','ClusteringCoeff','Strength',};
                         
              NBSmatROIslabeled = NBSmatROI;
              NBSmatROIslabeled = array2table(NBSmatROIslabeled,'VariableNames',header1);
              NBSmatROIslabeled = addvars(NBSmatROIslabeled,ROI,'Before','LocalEfficiency');
              tableName = strcat("participant",string(k),"scfsl_nbs_rois.txt");
              writetable(NBSmatROIslabeled,tableName);
              
              %Adds subject to matrix
              NBSroiAllSubs(:,:,k) = NBSmatROI;
              
              fclose(fid);
    end
    
end

%%%Outputs whole-brain table for all subjects
header = {'ParticipantID','GlobalEfficiency','MeanClusteringCoeff','MeanStrength',};
NBSalltable = array2table(NBSallsubs,'VariableNames',header);
nbsalltablename=strcat("scfsl_nbs_group.txt");
writetable(NBSalltable,nbsalltablename);
%%%

%%%Labeled tables of each participant's network-based statistics for each
%%%roi

for r = 1:numROIs
    roilabels = ["Left_Thalamus_Proper",'Left_Caudate','Left_Putamen','Left_Pallidum','Left_Hippocampus','Left_Amygdala','Left_Accumbens_area','Right_Thalamus_Proper','Right_Caudate','Right_Putamen','Right_Pallidum','Right_Hippocampus','Right_Amygdala','Right_Accumbens_area','ctx_lh_bankssts','ctx_lh_caudalanteriorcingulate','ctx_lh_caudalmiddlefrontal','ctx_lh_cuneus','ctx_lh_entorhinal','ctx_lh_fusiform','ctx_lh_inferiorparietal','ctx_lh_inferiortemporal','ctx_lh_isthmuscingulate','ctx_lh_lateraloccipital','ctx_lh_lateralorbitofrontal','ctx_lh_lingual','ctx_lh_medialorbitofrontal','ctx_lh_middletemporal','ctx_lh_parahippocampal','ctx_lh_paracentral','ctx_lh_parsopercularis','ctx_lh_parsorbitalis','ctx_lh_parstriangularis','ctx_lh_pericalcarine','ctx_lh_postcentral','ctx_lh_posteriorcingulate','ctx_lh_precentral','ctx_lh_precuneus','ctx_lh_rostralanteriorcingulate','ctx_lh_rostralmiddlefrontal','ctx_lh_superiorfrontal','ctx_lh_superiorparietal','ctx_lh_superiortemporal','ctx_lh_supramarginal','ctx_lh_frontalpole','ctx_lh_temporalpole','ctx_lh_transversetemporal','ctx_lh_insula','ctx_rh_bankssts','ctx_rh_caudalanteriorcingulate','ctx_rh_caudalmiddlefrontal','ctx_rh_cuneus','ctx_rh_entorhinal','ctx_rh_fusiform','ctx_rh_inferiorparietal','ctx_rh_inferiortemporal','ctx_rh_isthmuscingulate','ctx_rh_lateraloccipital','ctx_rh_lateralorbitofrontal','ctx_rh_lingual','ctx_rh_medialorbitofrontal','ctx_rh_middletemporal','ctx_rh_parahippocampal','ctx_rh_paracentral','ctx_rh_parsopercularis','ctx_rh_parsorbitalis','ctx_rh_parstriangularis','ctx_rh_pericalcarine','ctx_rh_postcentral','ctx_rh_posteriorcingulate','ctx_rh_precentral','ctx_rh_precuneus','ctx_rh_rostralanteriorcingulate','ctx_rh_rostralmiddlefrontal','ctx_rh_superiorfrontal','ctx_rh_superiorparietal','ctx_rh_superiortemporal','ctx_rh_supramarginal','ctx_rh_frontalpole','ctx_rh_temporalpole','ctx_rh_transversetemporal','ctx_rh_insula'];
%     roilabels = split(roilabels);
    roiMat = zeros(k,4);
    roiMat(:,1) = 1:k;
    for iii = 1:k
        roiMat(iii,2:4) = NBSroiAllSubs(r,:,iii);
    end
    header = {'ParticipantNum','LocalEfficiency','ClusteringCoeff','Strength',};
    roiTable = array2table(roiMat,'VariableNames',header);
    roitablename=strcat("scfsl_nbs_",roilabels(r),".txt");
    writetable(roiTable,roitablename);
end




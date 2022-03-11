%%% Select the folder containing the .csv results of all your participants 

mainfolder = uigetdir;
subfolders = dir(strcat(mainfolder,"/*/*/Conn*"));
subfolders = subfolders([subfolders.isdir] & ~startsWith({subfolders.name},'.'));

for i = 1:length(subfolders)
    files = dir(fullfile(mainfolder,"/*/*",subfolders(i).name,'*VolumeWeighted.csv'));
    NBSallsubs = zeros(length(files),4);
    for k = 1:length(files)
        fid = fopen(fullfile(files(k).folder,files(k).name)); 
              
              delimiterIn = ","
              net_mat = importdata(fullfile(files(k).folder,files(k).name),delimiterIn);
              %%%Computes Network-Based Statistics using the BCT 
              %%% 
              %%% Add the downloaded folder to path first
              GlobalEfficiency = efficiency_wei(net_mat, 0);
              MeanClusteringCoeff = mean(clustering_coef_wu(net_mat));
              MeanStrength = mean(strengths_und(net_mat));
              
              NBSmat = zeros(1,3);
              NBSmat(1,1) = GlobalEfficiency;
              NBSmat(1,2) = MeanClusteringCoeff;
              NBSmat(1,3) = MeanStrength;
              
              NBSmatS = zeros(1,4);
              iD = k;
              NBSmatS(1,1) = iD; 
              NBSmatS(1,2:end) = NBSmat;
              NBSallsubs(k,:) = NBSmatS;
              
              fclose(fid);
    end
    
end
header = {'ParticipantID','GlobalEfficiency','MeanClusteringCoeff','MeanStrength',};
NBSalltable = array2table(NBSallsubs,'VariableNames',header);
nbsalltablename=strcat("nbs_group.txt");
writetable(NBSalltable,nbsalltablename);
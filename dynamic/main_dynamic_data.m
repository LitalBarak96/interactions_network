%%

%creat interaction matrix ,per frame features avarge 
%for spcific number of mvoies
jaabaFileName = 'registered_trx.mat';
param = struct();
param.interactionsNumberOfFrames = 60;
param.interactionsDistance = 8;
param.interactionsAnglesub = 0;
param.oneInteractionThreshold = 120;
param.startFrame = 0;
param.endFrame = 26998;
%i can change here to false and get undirected network parametrs
param.directed = false;
%param.interactionLength = true;
%do angelsub mean calculate angelsub as parametrs of interaction
%false mean only use distnace for interatcion
param.doAngelsub = true;
interactions = [];
noInteractions = [];

handles.allFolders = uipickfiles('Prompt', 'Select movies to run inteactions');
for i = 1:length(handles.allFolders)
    folderPath = handles.allFolders{i};
    if(not(isfile(fullfile(folderPath, 'AllinteractionWithAngelsub.mat'))))
    fileName = fullfile(folderPath, jaabaFileName);
    [COMPUTERPERFRAMESTATSSOCIAL_SUCCEEDED,savenames] = compute_perframe_stats_social_f('matname', fileName);
    [newInteractions, newNoInteractions] = computeAllMovieInteractionsAllinteraction(savenames, param);
    else 
        folderPath
    end
    if(not(isfile(fullfile(folderPath, 'per_framefeatures_sum_allflies.csv'))))
         fileName = fullfile(folderPath, "perframe");
    all=[];
    current_dir_cell_features=struct2cell(dir(fullfile(fileName)));
for feature =3:length(current_dir_cell_features)
        featureName=current_dir_cell_features{1,feature}
        load(fullfile(fileName,featureName))
        perFrameAvgAllFlies=zeros(1,param.endFrame);
%calculating avarge
for j=1:param.endFrame
    sum_per_frame=sum(cellfun(@(v)v(j),data));
    perFrameAvgAllFlies(j)=sum_per_frame;
end
%flipping 
    horizen_perFrameAvgAllFlies=perFrameAvgAllFlies';
    table_of_current_perframe = array2table(horizen_perFrameAvgAllFlies, 'VariableNames',{featureName});
    all=horzcat(all,table_of_current_perframe);
end

    fullPath2Csv=fullfile(folderPath,"per_framefeatures_sum_allflies.csv");
    writetable(all,fullPath2Csv)
    else
    end
end
%%


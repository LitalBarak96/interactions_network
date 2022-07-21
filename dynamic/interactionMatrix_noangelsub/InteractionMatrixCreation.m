
%this script creat the txt file of interaction matrix of per two fly in the
%whole movie
%for spcific number of mvoies
jaabaFileName = 'registered_trx.mat';
%jaabaFileName = 'ctrax_results - Copy.mat';


param = struct();
param.interactionsNumberOfFrames = 60;
param.interactionsDistance = 8;
param.interactionsAnglesub = 0;
param.oneInteractionThreshold = 120;
param.startFrame = 0;
param.endFrame = 54000;
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
    fileName = fullfile(folderPath, jaabaFileName);
    [COMPUTERPERFRAMESTATSSOCIAL_SUCCEEDED,savenames] = compute_perframe_stats_social_f('matname', fileName);
    %this part creat the interaction matrix
    [newInteractions, newNoInteractions, txtFileNameLength, txtFileNameNumber, maxInteractionNumber] = computeAllMovieInteractions(savenames, param);
end
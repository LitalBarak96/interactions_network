
%pick the movies
handles.allFolders = uipickfiles('Prompt', 'Select movies to run inteactions');

currentFolder = pwd;
for numofmovie=1:length(handles.allFolders)
    %the folder path
folderPath = handles.allFolders{numofmovie};
cd(folderPath)
%get the trx files for distances per 2 flys
struct_of_perfly=dir("*registered_trx_perframepairs_*.mat");
%assuming there is 10 flys
for i=1:10
 name_of_trx=struct_of_perfly(i).name;
 %find if the index exist
index = strfind(name_of_trx, string(i));
foundIt = ~isempty(index);
if(foundIt)
load(name_of_trx)
for j=i+1:10
perfly_dist=pairtrx(j).distnose2ell;
rouneddistance_per_fly{i,j} = round(perfly_dist,1);
end
else
    warning("we didn't found the index")
end
end
%return to the script path

%break down the cell for the histogram
values_for_hist=cell2mat(cellfun(@(x)x(:),rouneddistance_per_fly(:),'un',0));
subplot(2,round((length(handles.allFolders))/2),numofmovie)
h1=histogram(values_for_hist,"FaceAlpha",0.2);
h1.BinWidth = 0.1;
hold on
end
cd(currentFolder)


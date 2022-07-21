function [] = extractFibreDataAllFrames(rawDatasetsDir,allOrientation,allLocalOP, allCoherence, orientWindow, OPWindow, cohWindow)
% This function runs over all frame datasets and runs the subfunction to
% extract fibre data for every cell in the frame.

cd(rawDatasetsDir);
datasets = dir('*Cell*');
sortedDatasets = natsortfiles({datasets.name});

for i = 1:length(sortedDatasets)
    display(['Writing fibre data for ',sortedDatasets{i}])
    cd(rawDatasetsDir);
    thisCellData = importdata(sortedDatasets{i});

    for j = 1:size(thisCellData,2)
        thisFrame = thisCellData(j).frame;
        [meanOrient, meanOP, meanCoh] = extractFibreData(thisCellData(j),allOrientation(thisFrame),allLocalOP(thisFrame), allCoherence(thisFrame), orientWindow, OPWindow, cohWindow);
        thisCellData(j).fibreOrientation = meanOrient;
        thisCellData(j).localOP = meanOP;
        thisCellData(j).fibreCoherence = meanCoh;
        
    end
    
   save(sortedDatasets{i},'thisCellData');

end


    %% 1. Initialization:
clear all; close all;
addpath(genpath('\\phhydra\data-new\phkinnerets\home\lab\CODE\Hydra\'));
addpath(genpath('\\phhydra\phhydraB\Analysis\users\Yonit\MatlabCodes\GroupCodes'));

mainDir='\\phhydra\phhydraB\Analysis\users\Yonit\Movie_Analysis\Labeled_cells\2021_05_06_pos6\'; % Main directory for movie you are analysing.
cellDir = [mainDir,'\Cells\']; % Cell directory for movie (this is our normal folder structure and should stay consistent).
segDir = [cellDir,'Segmentation_Yonit']; % Segmentation folder.
maskDir =  [mainDir,'\Display\Masks']; 

expName = '2021_05_06_pos6';
calibrationXY = 0.52; % um per pixel in XY plane
calibrationZ = 3; % um per pixel in Z direction
umCurvWindow = (32/1.28); % Window for averaging curvature around single cell (in um). Default - 32 pixels in 1.28 um/pixel.
cellHMnum = 1; % Set to 0 or 1 according to whether the cell layer is labeled 0 or 1 in layer separation.

% Window for orientation, local OP and coherence
orientWindow = 20/calibrationXY; % Average cell radius in um, divided by calibrationXY
cohWindow = 40/calibrationXY;
OPWindow = 20/calibrationXY;

useDefects = 1; % Set to 1 if you are using manually marked defects, and 0 if not.

%% 2. Extract defect data
if useDefects ==1
    % Prepare and load raw data on defect location.
    dirDataDefect=[mainDir,'\Dynamic_Analysis\Defects'];
    mkdir([mainDir,'\Dynamic_Analysis\']);
    mkdir(dirDataDefect);
    
    dirLocalOP = [mainDir,'\Orientation_Analysis\LocalOP']; % masked local order parameter field
    cd([mainDir,'\Orientation_Analysis']); load('resultsGroundTruth');
    
    cd(segDir); fileNames=dir ('*.tif*');
    frames=[1:length(fileNames)];
    sortedFileNames = natsortfiles({fileNames.name});
    % Extract defect data from GTL format (manual marking)
    for k=frames,  % loop on all frames
        thisFile=sortedFileNames{k}; % find this frame's file name
        endName=strfind(thisFile,'.');
        thisFileImNameBase = thisFile (1:endName-1); %without the .filetype
        extractAllDefects(k, dirLocalOP, thisFileImNameBase,gTruth,dirDataDefect);
        thisDefect = load([dirDataDefect,'\',thisFileImNameBase,'.mat']);
        allDefects(k)= thisDefect;
    end
end

%% 3. Extract all cell data from segmentation images and vertex images saved from Tissue Analyzer. 

[fullCellData,fullVertexData] = extractCellData(segDir,maskDir);

%% 4. Apply geometric correction to cell outlines in "fullCellData", and calculate area, orientation, and aspect ratio. Save back into struct.

fullCellDataMod = cells3DCorrection(mainDir,fullCellData,calibrationXY, calibrationZ,umCurvWindow,cellHMnum);
% If already performed and saved the corrections, load previously saved
% data:
% cd(cellDir); load('fullCellDataMod');
% cd(cellDir); load('fullVertexData');

%% 5. Calculate info in relation to defects

if useDefects==1
    for i = 1:size(fullCellDataMod,2)
        thisFrame = str2double(fullCellDataMod(i).frame)+1;
        frameDefects = allDefects(thisFrame).defect;
        defectDist = [];
        defectType = [];
        for j=1:size(frameDefects,2)
            defectDist(1,j) = sqrt(sum((frameDefects(j).position - [fullCellDataMod(i).centre_y,fullCellDataMod(i).centre_x]).^2));
            defectType(1,j) = frameDefects(j).type;
        end
        fullCellDataMod(i).defectDist = defectDist;
        fullCellDataMod(i).defectType = defectType;
        
    end
    
    for i = 1:size(fullVertexData,2)
        thisFrame = fullVertexData(i).frame+1;
        frameDefects = allDefects(thisFrame).defect;
        defectDistV = [];
        defectTypeV = [];
        for j=1:size(frameDefects,2)
            defectDistV(1,j) = sqrt(sum((frameDefects(j).position - [fullVertexData(i).y_pos,fullVertexData(i).x_pos]).^2));
            defectTypeV(1,j) = frameDefects(j).type;
        end
        fullVertexData(i).defectDist = defectDistV;
        fullVertexData(i).defectType = defectTypeV;
        
    end
    
end

cd(cellDir); save('fullVertexData','fullVertexData');
cd(cellDir); save('fullCellDataMod','fullCellDataMod');


%% 6. Load order parameter, orientation and coherence

dirOrientation=[mainDir,'\Orientation_Analysis\Orientation']; % masked orientation field
dirCoherence = [mainDir,'\Orientation_Analysis\Coherence']; % masked coherence field
dirLocalOP = [mainDir,'\Orientation_Analysis\LocalOP']; % masked local order parameter field

cd(segDir); fileNames=dir ('*.tif*');
frames=[1:length(fileNames)];
sortedFileNames = natsortfiles({fileNames.name});

    % Loop over frame and load data from orientation analysis
    for k=frames,  % loop on all frames
        thisFile=sortedFileNames{k}; % find this frame's file name
        endName=strfind(thisFile,'.');
        thisFileImNameBase = thisFile (1:endName-1); %without the .filetype
        thisOrientation = load([dirOrientation,'\',thisFileImNameBase,'.mat']);
        allOrientation(k)= thisOrientation;
        thisCoherence = load([dirCoherence,'\',thisFileImNameBase,'.mat']);
        allCoherence(k)= thisCoherence;
        thisLocalOP = load([dirLocalOP,'\',thisFileImNameBase,'.mat']);
        allLocalOP(k)= thisLocalOP;
        
    end

%% 7. Extract local fibre orientaion, local OP and coherence for every cell 
% Add another function here to extract fibre data into vertex structure as
% well.
for i = 1:size(fullCellDataMod,2)
    
    thisFrame = str2double(fullCellDataMod(i).frame)+1;
    [meanOrient, meanOP, meanCoh] = extractFibreData(fullCellDataMod(i),allOrientation(thisFrame),allLocalOP(thisFrame), allCoherence(thisFrame), orientWindow, OPWindow, cohWindow); 
    fullCellDataMod(i).fibreOrientation = meanOrient;
    fullCellDataMod(i).localOP = meanOP;
    fullCellDataMod(i).fibreCoherence = meanCoh;

end

cd(cellDir); save('fullCellDataMod','fullCellDataMod');

%% 8. Calcualte number of neighbours per cell, and number of cells per vertex. Write vertex data to vertex csv file.
neighInd={};
for i = 1:size(fullCellDataMod,2)
    if isempty(fullCellDataMod(i).outline)
        continue
    end
    neighInd{i}=[];
    theseVertices = fullCellDataMod(i).vertices;
    for j = 1:size(fullCellDataMod,2)

        vertInd = ismember(fullCellDataMod(j).vertices, theseVertices);
        if sum(vertInd)>=2
            neighInd{i} = [neighInd{i},j];
        end
    end
fullCellDataMod(i).neighbourList = neighInd{i};
fullCellDataMod(i).neighbourList = fullCellDataMod(i).neighbourList(fullCellDataMod(i).neighbourList~=i);
end
cd(cellDir); save('fullCellDataMod','fullCellDataMod');
cellsPerVertex =  cell2mat(arrayfun(@(x) size(x.cells,2),fullVertexData,'UniformOutput',false));


%% 9. Calculate thickness of each cell according to heightmaps of cell and fibre layers.
% for i = 1:size(fullCellDataMod,2)
%     thisCentre_x = round(fullCellDataMod(i).centre_x);
%     thisCentre_y = round(fullCellDataMod(i).centre_y);
%     if or(thisCentre_x<=0,thisCentre_y<=0)
%          fullCellDataMod(i).umThickness = [];
%         continue
%     end
%     thisFrame = str2double(fullCellDataMod(i).frame)+1;
%     outline = fullCellDataMod(i).outline;
%     fullCellDataMod(i).umThickness = calculateCellThickness(mainDir,calibrationXY, calibrationZ,umCurvWindow,thisFrame,outline,cellHMnum);
% 
% end
%  
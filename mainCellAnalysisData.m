 %% 0. Initialization:
clear all; close all;
addpath(genpath('\\phhydra\phhydraB\Analysis\users\Yonit\MatlabCodes\GroupCodes\July2021'));

%% 0.1 Define mainDirList

% Locations of original data - needed only for timestamps
topMainDir = '\\phhydra\phhydraB\SD2\Users\Yonit\2021_05\2021_05_06'; % main folder of original files

topAnalysisDir='\\PHHYDRA\phhydraB\Analysis\users\Yonit\Movie_Analysis\Labeled_cells\'; % main folder for movie analysis
mainAnalysisDirList= { ... % enter in the following line all sub-directories for movie analysis.

'2021_05_06_pos6\', ...

};
for i=1:length(mainAnalysisDirList),mainDirList{i}=[topAnalysisDir,mainAnalysisDirList{i}];end


%% 0.2 Define parameters per movie

% Comment out the following irrelevant choice for framelist:
% frameList = cell(1,length(mainAnalysisDirList));
 frameList = {[1:89,90:5:230,235:275,280:5:305]}; % Enter specific frame ranges in this format if you
% want to run on particular frames (in this example, 1:6 is for the first
% movie, 1:9 is for the second). If left empty, runs on all frames.

calibrationXY_list = [0.52]; % um per pixel in XY plane (can be a single value or vector of length of movie list if different for each movie).
calibrationZ_list = [3]; % um per pixel in Z direction(can be a single value or vector of length of movie list if different for each movie).
   
useDefects_list = 0; % Set to 1 if you are using manually marked defects, and 0 if not. (can be a single value or vector of length of movie list if different for each movie).
disp('Please make sure you have run the orientation analysis on these movies/datasets')
%% 0.3 Define general parameters for analysis

umCurvWindow = (32/1.28); % Window for averaging curvature around single cell (in um). Default - 32 pixels in 1.28 um/pixel.
cellHMnum = 1; % Set to 0 or 1 according to whether the cell layer is labeled 0 or 1 in layer separation.
%% Run over list of movies
for n=1:length(mainDirList)
   %% 1. Initialize parameters for each movie
    disp(['Analyzing movie/dataset ',num2str(n)])
    mainDir = mainDirList{n};
    cellDir = [mainDir,'\Cells\']; % Cell directory for movie (this is our normal folder structure and should stay consistent).
    segDir = [cellDir,'AllSegmentedJune2022']; % Segmentation folder.
    maskDir =  [mainDir,'\Display\Masks'];
    
    
    if length(calibrationXY_list)==1, calibrationXY = calibrationXY_list; else calibrationXY = calibrationXY_list(n); end % um per pixel in XY plane
    if length(calibrationZ_list)==1, calibrationZ = calibrationZ_list; else calibrationZ = calibrationZ_list(n); end % um per pixel in Z direction
    if length(useDefects_list)==1, useDefects = useDefects_list; else useDefects = useDefects_list(n); end % Whether to analyze relation to defects
    
    % Window for orientation, local OP and coherence
    orientWindow = 20/calibrationXY; % Average cell radius in um, divided by calibrationXY
    cohWindow = 40/calibrationXY;
    OPWindow = 20/calibrationXY;
    %% 2. Extract all cell data from segmentation images and vertex images saved from Tissue Analyzer.
    disp('Extracting raw cell data')
    [fullCellDataRaw,fullVertexData,fullBondDataRaw,fullDBondData] = extractCellDataTMformat(segDir,maskDir,frameList{n});
    
    %% 3. Apply geometric correction to cell outlines in "fullCellData", and calculate area, orientation, and aspect ratio. Save back into struct.
    disp('Applying geometric correction')
    [fullCellData,fullBondData] = cells3DCorrectionTMformat(mainDir,fullCellDataRaw,fullVertexData,fullBondDataRaw,fullDBondData,calibrationXY, calibrationZ,umCurvWindow,cellHMnum,frameList{n});
    
    
    %% 4. Load order parameter, orientation and coherence
    disp('Preparing fibre data')
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
    
    %% 5. Extract local fibre orientaion, local OP and coherence for every cell
    % Add another function here to extract fibre data into vertex structure as
    % well.
    disp('Analyzing relation to fibres')
    for i = 1:size(fullCellData,2)
        thisFrame = fullCellData(i).frame;
        [meanOrient, meanOP, meanCoh] = extractFibreData(fullCellData(i),allOrientation(thisFrame),allLocalOP(thisFrame), allCoherence(thisFrame), orientWindow, OPWindow, cohWindow);
        fullCellData(i).fibreOrientation = meanOrient;
        fullCellData(i).localOP = meanOP;
        fullCellData(i).fibreCoherence = meanCoh;
        
    end
    
    %% 6. Produce tables from structures to be saved accorting to Tissue Miner format.

    % Save only data required for TM format to tables:

    %Directed bonds table
    dbond_id = {fullDBondData.dbond_id}';
    frame = {fullDBondData.frame}';   
    cell_id = {fullDBondData.cell}'; 
    conj_dbond_id = {fullDBondData.conjugate_dbond}';
    bond_id = {fullDBondData.bond}';
    allVertexPairs = cat(1,fullDBondData.ordered_vertices);
    vertex_id = allVertexPairs(:,1); 
    vertex2_id = allVertexPairs(:,2);
    left_dbond_id = {fullDBondData.next_dBond}';
    directed_bonds = table(dbond_id,frame,cell_id,conj_dbond_id,bond_id,vertex_id,vertex2_id,left_dbond_id);
    clear('dbond_id','frame','cell_id','conj_dbond_id','bond_id','vertex_id','vertex2_id','left_dbond_id');
    
    
    % Bonds table
    bond_id = {fullBondData.bond_id}';
    frame = {fullBondData.frame}';   
    bond_length = {fullBondData.length}';    
    
    bonds = table(bond_id,frame,bond_length);
    clear('bond_id','frame','bond_length');
    
    % Vertices table
    vertex_id = {fullVertexData.vertex_id}';
    frame = {fullVertexData.frame}';   
    x_pos = {fullVertexData.x_pos}';    
    y_pos = {fullVertexData.y_pos}';    

    vertices = table(vertex_id,frame, x_pos, y_pos);
    clear('vertex_id','frame', 'x_pos', 'y_pos');
    
    % Cells table
    cell_id = {fullCellData.cell_id}';
    frame = {fullCellData.frame}';   
    center_x = {fullCellData.centre_x}';    
    center_y = {fullCellData.centre_y}';    
    area =  {fullCellData.area}';
    aspect_ratio = {fullCellData.aspect_ratio}';
    perimeter = {fullCellData.perimeter}';
    is_edge = {fullCellData.isEdge}';
    is_convex = {fullCellData.isConvex}';
    allCellOrientation = cat(1,fullCellData.orientation);
    elong_xx = allCellOrientation(:,1);
    elong_yy = allCellOrientation(:,2);
    elong_zz = allCellOrientation(:,3);
    fibre_orientation = {fullCellData.fibreOrientation}';
    fibre_localOP = {fullCellData.localOP}';
    fibre_coherence = {fullCellData.fibreCoherence}';
    score = {fullCellData.score}';

    cells = table(cell_id,frame, center_x, center_y, area, aspect_ratio, perimeter, is_edge, is_convex, elong_xx, elong_yy, elong_zz ,fibre_orientation,fibre_localOP,fibre_coherence, score);
    clear('cell_id','frame', 'center_x', 'center_y', 'area','aspect_ratio', 'perimeter', 'is_edge', 'is_convex', 'elong_xx', 'elong_yy', 'elong_zz', 'fibre_orientation','fibre_localOP','fibre_coherence','score');
    
    % Frames table
    
    frame = (frameList{n})';
    sortedFolderNames = listFoldersInDir(segDir);
    frame_name = ([sortedFolderNames(frameList{n})])';
    timeStampDir = [topMainDir,'\TimeStamps'];
    movieName = mainAnalysisDirList{n}(1:end-1);
    time_sec = getTimeStamps(timeStampDir,movieName,frame);
    
    frames = table(frame,frame_name, time_sec);
    clear('frame','frame_name','time_sec');
    
    % Bond pixel table
    
    [allBondPixels,allBond3DPixels,allBondIDs,allBondFrames] = getBondPixelLists(fullBondData);
    orig_x_coord = allBondPixels(:,1);
    orig_y_coord =  allBondPixels(:,2);
    smooth_x_coord = allBond3DPixels(:,1);
    smooth_y_coord =  allBond3DPixels(:,2);
    smooth_z_coord =  allBond3DPixels(:,3);
    pixel_bondID = allBondIDs;
    pixel_frame = allBondFrames;
    
    bond_pixels = table(orig_x_coord,orig_y_coord,smooth_x_coord,smooth_y_coord,smooth_z_coord,pixel_bondID,pixel_frame);
    clear('orig_x_coord','orig_y_coord','smooth_x_coord','smooth_y_coord','smooth_z_coord','pixel_bondID','pixel_frame');
    
    % CHECK DEFECT TABLE FORMAT AND SEE IF SUITABLE
    
    % Save all tables to folder:
    
     cd(cellDir); save('cells','cells'); save('vertices','vertices'); save('bonds','bonds');save('directed_bonds','directed_bonds');save('frames','frames');save('bond_pixels','bond_pixels');
    
    %% 4. Extract defect data
    if useDefects ==1
        disp('Preparing defect data')
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
        cd([mainDir,'\Dynamic_Analysis\']);
        save('allDefects','allDefects');
    
    end
    

    %% 5. Calculate info in relation to defects
    
    if useDefects==1
        for i = 1:size(fullCellData,2)
            thisFrame = str2double(fullCellData(i).frame)+1;
            frameDefects = allDefects(thisFrame).defect;
            defectDist = [];
            defectType = [];
            for j=1:size(frameDefects,2)
                defectDist(1,j) = sqrt(sum((frameDefects(j).position - [fullCellData(i).centre_y,fullCellData(i).centre_x]).^2));
                defectType(1,j) = frameDefects(j).type;
            end
            fullCellData(i).defectDist = defectDist;
            fullCellData(i).defectType = defectType;
            
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
%     
%     cd(cellDir); save('fullVertexData','fullVertexData');
%     cd(cellDir); save('fullCellDataMod','fullCellDataMod');
    
    

    
%     cd(cellDir); save('fullCellDataMod','fullCellDataMod');
    
    %% 8. Calcualte number of neighbours per cell, and number of cells per vertex. Write vertex data to vertex csv file.
    neighInd={};
    disp('Analyzing cell neighbour relations')
    for i = 1:size(fullCellData,2)
        if isempty(fullCellData(i).outline)
            continue
        end
        neighInd{i}=[];
        theseVertices = fullCellData(i).vertices;
        for j = 1:size(fullCellData,2)
            
            vertInd = ismember(fullCellData(j).vertices, theseVertices);
            if sum(vertInd)>=2
                neighInd{i} = [neighInd{i},j];
            end
        end
        fullCellData(i).neighbourList = neighInd{i};
        fullCellData(i).neighbourList = fullCellData(i).neighbourList(fullCellData(i).neighbourList~=i);
    end
%     cd(cellDir); save('fullCellDataMod','fullCellDataMod');
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
    %% 10. Save all data, and merge with existing cell and vertex data for movie/dataset if exists.
    
    % Check whether analysis has already been performed for this
    % movie/dataset, and if so load the fullCellDataMod file, and add new
    % frames and cells to it. If frames already exist in file, they
    % will be overwritten to allow for corrections.
    
    cd(cellDir);
    if exist([cellDir,'fullCellData.mat'], 'file') == 2
        disp('Comparing and merging with existing cell analysis data')
        fullCellDataOld = load('fullCellData'); fullCellDataOld = fullCellDataOld.fullCellDataMod ;
        fullVertexDataOld = load('fullVertexData'); fullVertexDataOld = fullVertexDataOld.fullVertexData;

        newFrames = unique(str2double(extractfield(fullCellData,'frame')));
        cCount = 0;
        vCount = 0;
        % Check whether a frame that already exists gets re-analysed, and
        % if so delete all cells and vertices from this frame from
        % old data.
        for m = 1:size(fullCellDataOld,2)
            thisFrame = str2double(fullCellDataOld(m).frame);
            if ~ismember (thisFrame,newFrames)
                cCount = cCount+1; 
                fullCellDataTemp(cCount)= fullCellDataOld(m);
            end
        end
        
        for m = 1:size(fullVertexDataOld,2)
            thisFrame = fullVertexDataOld(m).frame;
            if ~ismember (thisFrame,newFrames)
                vCount = vCount+1; 
                fullVertexDataTemp(vCount)= fullVertexDataOld(m);
            end
        end
        
        % Once objects belonging to repeated frames are deleted,concatenate
        % old and new cell and vertex data structures.
        if exist('fullCellDataTemp','var')
        fullCellData = [fullCellDataTemp,fullCellData];
        fullVertexData = [fullVertexDataTemp,fullVertexData];
        end
    end
    disp(['Saving data for movie/dataset ',num2str(n)]);    
    cd(cellDir); save('fullVertexData','fullVertexData');
    cd(cellDir); save('fullCellData','fullCellData');
    
    %% 11. Check whether VMSI has been performed, and add stress information to cell database
    if exist([cellDir,'\VMSI.mat'])
        disp(['found stress inference for movie/dataset ',num2str(n)])
        % If database exists, perform the following steps:
        % 1. Ask the user to confirm that frame numbers match between databases.
        
        disp('Warning: Please make sure that the total frame number and order for VMSI match those for geometrical analysis.');
        
        % 2. For every cell in fullCellData.m, find the correct frame in the
        % VMSI struct, and find Struct(frame).labelMat(centre_y,centre_x)
        % (centroids from geometrical analysis. According to this, recognise the
        % corresponding cell in the VMSI struct.
        cd(cellDir); load ('VMSI');
        for i = 1:size(fullCellData,2)
                
        thisFrame =  str2double(fullCellData(i).frame)+1;
        frameSize = size(Struct(thisFrame).labelMat);
        cellRegion = poly2mask(fullCellData(i).outline(:,1),fullCellData(i).outline(:,2),frameSize(1),frameSize(2));
        SE = strel("disk",1);
        cellRegion = imerode(cellRegion,SE);
        [inX,inY]=find(cellRegion==1);
%         thisCentre_x = round(fullCellData(i).centre_x);
%         thisCentre_y = round(fullCellData(i).centre_y);
         
        thisCell = Struct(thisFrame).labelMat(inY(round(length(inY/2))),inX(round(length(inX/2))));
        
        % 3. Save unique cell ID from geometrical analysis as a field in
        % Struct(frame).cdat(cellNum).
        Struct(thisFrame).Cdat(thisCell).uniqueID = fullCellData(i).uniqueID;
        
        % 4. Copy all cell mechanics data from Struct(frame).cdat(cellNum) to
        % fullCellDataMod.mat.
        
        fullCellData(i).pressure = Struct(thisFrame).Cdat(thisCell).pressure;
        fullCellData(i).stress = Struct(thisFrame).Cdat(thisCell).stress;
         
        end
        
        cd(cellDir);
        outfn = [ cellDir,'\VMSI'] ;
        save(outfn, 'Struct', 'ERes', 'PN','-v7.3');
        save('fullCellData','fullCellData');
    
    else
        disp ('cannot find stress inference')        
        
    end

end 
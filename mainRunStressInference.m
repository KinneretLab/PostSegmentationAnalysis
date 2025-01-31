%% 1. Initialization:
clear all; close all;
addpath(genpath('\\phhydra\phhydraB\Analysis\users\Yonit\MatlabCodes\GroupCodes\July2021'));

mainDir='\\phhydra\phhydraB\Analysis\users\Yonit\Movie_Analysis\Labeled_cells\2021_06_21_pos2\';
cellDir = [mainDir,'\Cells']; % Directory for cell analysis
cellImDir = [mainDir,'\Cells\AllSegmented']; % Directory for cell images
segDir = [mainDir,'\Cells\AllSegmented']; % Directory for segmentation images
cellPlotDir = [mainDir,'\Cells']; % Directory for saving output data, should be kept consistent.
calibrationXY = 0.52; % um per pixel in XY plane
calibrationZ = 3; % um per pixel in Z direction

%% Parameters
very_far = 150 ; % Parameter from original stress inference code. Shouldn't need changing for our use cases.
%% 2. Prepare data for stress inference:
% Create label matrix
L = createLabelMatrices(segDir);
% Load raw images
raw =[];
rawSeg =[];
cd(cellImDir); fileNames=dir ('*.tif*');
frames=[1:length(fileNames)];
sortedFileNames = natsortfiles({fileNames.name});
for i=1:length(sortedFileNames)
    cd(cellImDir);
    raw(:,:,i)= imread(sortedFileNames{i});
    frameDir = [segDir,'\',sortedFileNames{i}(1:(find(sortedFileNames{i}=='.')-1))];
    cd(frameDir);
    rawSeg(:,:,i) = rgb2gray(imread('handCorrection.tif'));
end

%% Created data structure from label matrix
% Set bond=0 and clear_border = 1
[L, Struct] = seg.generate_structs(L, 0, 1, 0, very_far);
disp('done with initial segmentation')
% Bad cells are bubble cells, which is a segmentation that forked and
% reconnected.
L = seg.removeBadCells(Struct, L);
disp('done removing bad cells')
% Now change label matrix after removing bad cells
L = seg.relabelL(L);
% Now also synchronize Struct after removing bad cells
[L,Struct] = seg.generate_structs(L, 0, 0, 0, very_far);
disp('done with segmentation')

%% Prepare data structure for inverse.
% put a parameter in the cdat of Struct, a boolean of whether every vertex
% is 3-fold.
Struct = seg.threefold_cell(Struct);
% generate the Bdat structure in Struct
Struct = seg.recordBonds(Struct, L);
disp('generated the bond structure')
% Segment the curvature of each bond
Struct = seg.curvature(Struct, size(L));
disp('segmented the curvature of each bond')
% Remove all fourfold vertices, recursively if there are z>4
%YONIT:
% commented out after conversation with Nick, causes bug with some of our
% images.
% Struct = seg.removeFourFold(Struct);
% disp('removed fourfold vertices')
% The inverse is ill-posed if we have convex cells, so hack those to be
% convex
Struct = seg.makeConvexArray(Struct);
disp('done with data preparation')

%%
% This does a soft version of compatibility constraint using Monte Carlo
% sampling to make edges lie along a line. May not be necessary.
% Struct = isogonal.imposeComptCond(Struct, .5);
% Struct = seg.makeConvexArray(Struct);

%%
for t = 1:size(L, 3)
    Struct(t).labelMat = L(:, :, t);
end
% clear L
disp('done with putting L data into Struct')

%% Invert mechanics.
% 'atn': Tension network inference
% 'ptn': Pressure(+Tension) network inference
atn_ptn = 'ptn';
extCell = 1; % The label for the external cell (surrounding void).
% This should honestly not be a parameter.
[PN, ERes, r0] = fitDual.returnDual(Struct, all(atn_ptn=='ptn') + 1, extCell);

disp('done with inverse')

outfn = [ mainDir, '\Cells\VMSI'] ;
save(outfn, 'Struct', 'ERes', 'PN', '-v7.3'); % This saving method is required if data is larger than 2GB.
%% Store mechanics in data structure
% t = 1:size(PN) % This didn't run over all timepoints, because size is
% 1x(number of timepoints)
for t = 1:length(PN)
    % uploadMechanics is a method in the pressure.net class
    % It stores a pressure for each cdat and tension for each bdat
    if ~isempty(PN{t})
        [Struct(t), found_bonds] = PN{t}.uploadMechanics(Struct(t));
        Struct(t).ERes = ERes(t);
        Struct(t).PN = PN(t);
    end
    % YONIT: Added the following to read L
    L(:,:,t);
end
disp('Done storing mechanics')


%% Save to disk

outfn = [ mainDir, '\Cells\VMSI'] ;
save(outfn, 'Struct', 'ERes', 'PN', '-v7.3')
%% Compute stress Tensor from PN
% YONIT: Added the following loop to read L into the correct format of
% XxYxlength(PN) array
for t = 1:length(PN)
    L(:,:,t) = Struct(t).labelMat;
end
% L = Struct.labelMat ;
mode = 0 ;
[ Struct ] = measure.stressTensor( Struct, L, mode ) ;
save(outfn, 'Struct', 'ERes', 'PN','-v7.3');
%% YONIT: Match with cell geometry analysis database and add corresponding information to Struct:

% Check if cell geometry analysis has been performed by looking for saved
% data "fullCellData.m":

if exist([cellDir,'\fullCellData.mat'])
    disp('found cell geometrical analysis')
    % If database exists, perform the following steps:
    % 1. Ask the user to confirm that frame numbers match between databases.
    
    check = input('Please confirm that the frame number and order for VMSI match those for geometrical analysis by pressing 1 and Enter: ');
    if check ~= 1, disp('Stopped - frames do not match.'); return, end
    % 2. For every cell in fullCellData.m, find the correct frame in the
    % VMSI struct, and find Struct(frame).labelMat(centre_y,centre_x)
    % (centroids from geometrical analysis. According to this, recognise the
    % corresponding cell in the VMSI struct.
    cd(cellDir); load ('fullCellData.mat');
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
    save(outfn, 'Struct', 'ERes', 'PN','-v7.3');
    save('fullCellData','fullCellData');
else
    disp ('cannot find cell geometrical analysis')
end

%% Plot the segmentation
for t = 1:length(PN)
    L(:,:,t) = Struct(t).labelMat;
end
alpha = 1. ;

rgb = plot.segmentation( rawSeg, L, alpha ) ;
if length(rgb(1,1,1,:)) > 1
    implay(rgb)
else
    imshow(rgb)
end

%% Plot the tension

% YONIT - COMMENTS : 1) added case of Inf radius of curvature to
% plot.curvedTension, use code from noraml plot.tension to just plot
% straight lines. 2) changed background of images to gray, and added colorbar.

% Find min and max tensions over all frames for colorbar, using 0.5 and 95th percentiles: 
allT={};    
for t = 1:length(PN)
    if ~isempty(PN{t})
        for b=1:length(Struct(t).Bdat)
        allT{t,b} = Struct(t).Bdat(b).tension;
        end
    end
end
for idx = 1:numel(allT)
    if(isempty(allT{idx}))
    allT{idx}= NaN;
    end
end
allTmat = cell2mat(allT);
globTmax = prctile(allTmat(:),95);
globTmin = prctile(allTmat(:),0.5);

meanT=[];
for t = 1:length(PN)
    rgbL = cat(3,0.5*double(L(:,:,t)~=0), 0.5*double(L(:,:,t)~=0),0.5*double(L(:,:,t)~=0));
    imshow(rgbL)
    hold on;
    % below, mode : (0 or 1) If zero, plots Struct.Bdat.tension, but if nonzero plots Struct.Bdat.actual_tension
    if ~isempty(PN{t})
        if all(atn_ptn == 'atn')
            plot.tension(Struct(t), 0)
        else
            plot.curvedTension(Struct(t), 0)
        end
    end
    thisFig = gcf;
    caxis([globTmin globTmax])
    title(' {\bf\fontsize{16} Relative bond tensions}')
    tensionOutDir = [cellPlotDir,'\tensionMapsNew'];
    mkdir(tensionOutDir);
    cd(tensionOutDir); saveas(thisFig,[sortedFileNames{t}(1:(find(sortedFileNames{t}=='.')-1)),'.png'])
    close all
end
%% Plot the stress tensor
smoothSize = 10 ;
for t = 1:length(PN)
    
    rgbL = cat(3,0.5*double(L(:,:,t)~=0), 0.5*double(L(:,:,t)~=0),0.5*double(L(:,:,t)~=0));
    imshow(rgbL)
    hold on;
    if ~isempty(PN{t})
        % below, mode : (0 or 1) If zero, plots Struct.Bdat.tension, but if nonzero plots Struct.Bdat.actual_tension
        if all(atn_ptn == 'atn')
            plot.tension(Struct(t), 0)
        else
            plot.curvedTension(Struct(t), 0)
        end
        plot.stressTensor( Struct(t), Struct(t).labelMat, smoothSize )
    end
    thisFig = gcf;
    caxis([globTmin globTmax])
    title(' {\bf\fontsize{16} Bond tensions and cell stress tensor}')
    tensionOutDir = [cellPlotDir,'\tension_stress_Maps'];
    mkdir(tensionOutDir);
    cd(tensionOutDir); saveas(thisFig,[sortedFileNames{t}(1:(find(sortedFileNames{t}=='.')-1)),'.png'])
    close all
end

%% Plot the pressure map
% YONIT - COMMENT: Change background to grey, think of whether to normalize numbers somehow,
% because oomparison between images is irrelevant.
meanP=[];

for t = 1:length(PN)
    pressureMap = zeros(size(Struct(t).labelMat));
    if ~isempty(PN{t})
        for k=1:length(Struct(t).Cdat)
            if ~isempty(Struct(t).Cdat(k).pressure)
                pressureMap(Struct(t).labelMat==k)= Struct(t).Cdat(k).pressure;
            else
                pressureMap(Struct(t).labelMat==k)=0;
            end
        end
    end
    pressureMap(Struct(t).labelMat==1)=NaN;
    
    % Save image of cells color-coded by area:
    fig1 = figure();
    imshow(pressureMap,[]);
    colormap hot;
    colorbar
    caxis([0 3])
    hold on
    % Plot whole movie with constant scale - should the scale be based on
    % min and max of full movie, or just one frame?
    % The following is for a single frame:
    normPressureMap = ((pressureMap-prctile(pressureMap(:),1))/(prctile(pressureMap(:),98)-prctile(pressureMap(:),1)))*255;
    rgbImage = ind2rgb(round(normPressureMap), hot(256));
    rImage = rgbImage(:,:,1); rImage(Struct(t).labelMat==1)=0.5;
    gImage = rgbImage(:,:,2); gImage(Struct(t).labelMat==1)=0.5;
    bImage = rgbImage(:,:,3); bImage(Struct(t).labelMat==1)=0.5;
    imshow(cat(3,rImage,gImage,bImage),[]);
    title(' {\bf\fontsize{16} Relative cell pressure }')
    thisFig = gcf;
    PressureMapOutDir = [cellPlotDir,'\pressureMaps'];
    
    mkdir(PressureMapOutDir);
    cd(PressureMapOutDir); saveas(gcf,[sortedFileNames{t}(1:(find(sortedFileNames{t}=='.')-1)),'.png'])
    close all
end

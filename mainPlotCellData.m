clear all; close all;
addpath(genpath('\\phhydra\data-new\phkinnerets\home\lab\CODE\Hydra\'));
addpath(genpath('\\phhydra\phhydraB\Analysis\users\Yonit\MatlabCodes\OrientationAnalysis'));
addpath(genpath('\\phhydra\phhydraB\Analysis\users\Yonit\MatlabCodes\CellAnalysis'));
addpath(genpath('\\phhydra\phhydraB\Analysis\users\Yonit\MatlabCodes'));

mainDir='\\phhydra\phhydraB\Analysis\users\Yonit\Movie_Analysis\Labeled_cells\2021_05_06_pos6\';
cellPlotDir = [mainDir,'\Cells'];
cellDir = [mainDir,'\Cells'];
cellIMDir = [mainDir,'\Cells\Segmentation_Yonit'];

cd(cellIMDir); fileNames=dir ('*.tif*');
frames=[1:length(fileNames)];
sortedFileNames = natsortfiles({fileNames.name});

datasetPlots = [cellPlotDir,'\datasetPlots'];
mkdir(datasetPlots);

expName = '2021_05_6_pos6';
calibrationXY = 0.52; % um per pixel in XY plane
calibrationZ = 3; % um per pixel in Z direction
umCurvWindow = (32/1.28); % Window for averaging curvature around single cell (in um). Default - 32 pixels in 1.28 um/pixel.

% Window for orientation, local OP and coherence
orientWindow = 20/calibrationXY; % Average cell radius in um, divided by calibrationXY
cohWindow = 40/calibrationXY;
OPWindow = 20/calibrationXY;
%% Load data from cell analysis:
cd(cellDir); load('fullCellDataMod');
cd(cellDir); load('fullVertexData');

%% Plot area, aspect ration as a function of distance to closest defect:

for i = 1:size(fullCellDataMod,2)
    i
    if isempty (fullCellDataMod(i).defectDist)
        minDist(i)=NaN;
    else
        minDist(i) = min(fullCellDataMod(i).defectDist);
    end
    if isempty (fullCellDataMod(i).area)
        areaVec(i) = NaN;
    else
        areaVec(i)= fullCellDataMod(i).area;
    end
    
    if isempty (fullCellDataMod(i).aspect_ratio)
        aspectRatioVec(i) = NaN;
    else
        aspectRatioVec(i)= fullCellDataMod(i).aspect_ratio;
    end
    
    if isempty (fullCellDataMod(i).perimeter)
        perimeterVec(i) = NaN;
    else
        perimeterVec(i)= fullCellDataMod(i).perimeter;
    end
    
    if isempty (fullCellDataMod(i).localOP)
        localOPVec(i) = NaN;
    else
        localOPVec(i)= fullCellDataMod(i).localOP;
    end
    
    if isempty (fullCellDataMod(i).fibreCoherence)
        cohVec(i) = NaN;
    else
        cohVec(i)= fullCellDataMod(i).fibreCoherence;
    end
    
    if isempty (fullCellDataMod(i).fibreOrientation)
        ForientVec(i) = NaN;
    else
        ForientVec(i)= fullCellDataMod(i).fibreOrientation;
    end
    
    if isempty(fullCellDataMod(i).orientation)
        orientVec2D(i,1)= NaN;
        orientVec2D(i,2)= NaN;
    else
        thisOrient3D = fullCellDataMod(i).orientation';
        aspectRatio = fullCellDataMod(i).aspect_ratio;
        thisOrient2D = thisOrient3D;
        thisOrient2D(3)=0;
        thisOrient2D = (thisOrient2D/norm(thisOrient2D))*aspectRatio;
        orientVec2D(i,:)=thisOrient2D(1:2,:);
        orientAngleVec(i) = mod(atan(orientVec2D(i,1)/orientVec2D(i,2))+pi,pi);
        
    end
    if ~isempty(fullCellDataMod(i).isEdge)
        edgeFlag(i)=1;
    else
        edgeFlag(i)=0;
    end
    if isempty(fullCellDataMod(i).neighbourList)
        neighbourVec(i)=NaN;
    else
        neighbourVec(i)=length(fullCellDataMod(i).neighbourList);
    end
    
    %     if isempty(fullCellDataMod(i).umThickness)
    %         thicknessVec(i)=NaN;
    %     else
    %         thicknessVec(i)=fullCellDataMod(i).umThickness;
    %     end
end

% Convert into physical dimensions using calibration:

minDist = minDist*calibrationXY;
areaVec = areaVec*(calibrationXY^2);
perimeterVec = perimeterVec*calibrationXY;
PAVec = perimeterVec./sqrt(areaVec);

% Sort according to distance for plotting:

[sortedDist,ind]=sort(minDist);
sortedArea = areaVec(ind);
sortedAspectRatio = aspectRatioVec(ind);
sortedPerimeter = perimeterVec(ind);
sortedPA = sortedPerimeter./sqrt(sortedArea);
sortedFOrient = ForientVec(ind);
sortedCOrient = orientAngleVec(ind);
sortedCoh = cohVec(ind);


distVal= 0:((max(sortedDist)*calibrationXY)/(length(fullCellDataMod)-1)):(max(sortedDist)*calibrationXY); % distance in pixels for calcaulting the mean trace
sigma = 10;
[stdArea ,  meanArea] = stdGaussianXval (sortedDist, sortedArea, distVal, sigma, 0); % calculate the mean and std using a Gaussian filter for each data on the same time points
[stdAspectRatio ,  meanAspectRatio] = stdGaussianXval (sortedDist, sortedAspectRatio, distVal, sigma, 0); % calculate the mean and std using a Gaussian filter for each data on the same time points
[stdPerimeter ,  meanPerimeter] = stdGaussianXval (sortedDist, sortedPerimeter, distVal, sigma, 0); % calculate the mean and std using a Gaussian filter for each data on the same time points
[stdPA , meanPA] = stdGaussianXval (sortedDist, sortedPA, distVal, sigma, 0); % calculate the mean and std using a Gaussian filter for each data on the same time points


%% Area plots
fig1 = figure();
MeanPlusStdArea = meanArea+stdArea;
MeanMinusStdArea = meanArea-stdArea;
% Distribution as function of distance from defect
plot(sortedDist,sortedArea,'.')
hold on
plot(distVal,meanArea,'c','LineWidth',2)
hold on
inBetween = [MeanPlusStdArea, fliplr(MeanMinusStdArea)]; % shaded region with std
dist2 = [distVal,fliplr(distVal)];
inBetweenNan = inBetween(~isnan(inBetween));
dist2Nan = dist2(~isnan(inBetween));

h=fill(dist2Nan, inBetweenNan, [0 1 1]);
set(h,'facecolor',[0 1 1],'facealpha',.1,'linestyle','none');
title ('{\bf\fontsize{16} Cell area vs. distance to nearest defect}')
legend('cell area','mean +/- std')
xlabel('{\bf\fontsize{16} Distance from nearest defect (um)}')
ylabel('{\bf\fontsize{16} Cell area (um^2)}')
set(gca,'fontsize',14)

cd(datasetPlots); saveas(fig1,['AreaDist','.png'])

% Historgram of area distribution
figure();
[counts,edges]=histcounts(areaVec,'Normalization','probability');
fig1B = histogram('BinEdges',edges,'BinCounts',counts*100)
title('{\bf\fontsize{16}Cell area distribution}');
xlabel('{\bf\fontsize{16}Cell area (um^2)}')
ylabel('{\bf\fontsize{16}% of cells}')
set(gca,'fontsize',12)
cd(datasetPlots); saveas(fig1B,['AreaHist','.png'])

close all;
%% Aspect ratio plots
fig2 = figure();
MeanPlusStdAspectRatio = meanAspectRatio+stdAspectRatio;
MeanMinusStdAspectRatio = meanAspectRatio-stdAspectRatio;

plot(sortedDist,sortedAspectRatio,'.','Color',[0.6350 0.0780 0.1840])
hold on
plot(distVal,meanAspectRatio,'m','LineWidth',2)
hold on

inBetween = [MeanPlusStdAspectRatio, fliplr(MeanMinusStdAspectRatio)]; % shaded region with std
dist2 = [distVal,fliplr(distVal)];
inBetweenNan = inBetween(~isnan(inBetween));
dist2Nan = dist2(~isnan(inBetween));

h=fill(dist2Nan, inBetweenNan, [1 0 1]);
set(h,'facealpha',.1,'linestyle','none');

title ('Cell aspect ratio vs. distance to nearest defect')
legend('aspect ratio','mean +/- std')
xlabel('Distance from nearest defect (um)')
ylabel('Aspect ratio')

cd(datasetPlots); saveas(fig2,['AspectRatioDist','.png'])

% Historgram of aspect ratio distribution
figure();
[counts,edges]=histcounts(aspectRatioVec,'Normalization','probability');
fig2B = histogram('BinEdges',edges,'BinCounts',counts*100)
title('{\bf\fontsize{16}Cell aspect ratio distribution}');
xlabel('{\bf\fontsize{16}Cell aspect ratio}')
ylabel('{\bf\fontsize{16}% of cells}')
set(gca,'fontsize',12)
xlim([0.5 5])
cd(datasetPlots); saveas(fig2B,['AspectRatioHist','.png'])

close all;
%% Perimeter plots
fig3 = figure();
MeanPlusStdPerimeter = meanPerimeter+stdPerimeter;
MeanMinusStdPerimeter = meanPerimeter-stdPerimeter;

plot(sortedDist,sortedPerimeter,'.','Color',[0.4660 0.6740 0.1880])
hold on
plot(distVal,meanPerimeter,'g','LineWidth',2)
hold on

inBetween = [MeanPlusStdPerimeter, fliplr(MeanMinusStdPerimeter)]; % shaded region with std
dist2 = [distVal,fliplr(distVal)];

inBetweenNan = inBetween(~isnan(inBetween));
dist2Nan = dist2(~isnan(inBetween));
h=fill(dist2Nan, inBetweenNan, [0 1 0]);
set(h,'facealpha',.1,'linestyle','none');


title ('Cell perimeter vs. distance to nearest defect')
legend('perimeter','mean +/- std')
xlabel('Distance from nearest defect (um)')
ylabel('Perimeter (um)')

cd(datasetPlots); saveas(fig3,['PerimeterDist','.png'])

% Historgram of perimeter distribution
figure();
[counts,edges]=histcounts(perimeterVec,'Normalization','probability');
fig3B = histogram('BinEdges',edges,'BinCounts',counts*100)
title('Cell perimeter distribution');
xlabel('Cell perimeter (um)')
ylabel('% of cells')
cd(datasetPlots); saveas(fig3B,['PerimeterHist','.png'])

close all;
%% P/sqrt(A) plots
fig4 = figure();

MeanPlusStdPA = meanPA+stdPA;
MeanMinusStdPA = meanPA-stdPA;

plot(sortedDist,sortedPA,'.','Color',[0.8500 0.3250 0.0980])
hold on
plot(distVal,meanPA,'Color',[0.9290 0.6940 0.1250],'LineWidth',2)
hold on
ylim([0 10])

inBetween = [MeanPlusStdPA, fliplr(MeanMinusStdPA)]; % shaded region with std
dist2 = [distVal,fliplr(distVal)];

inBetweenNan = inBetween(~isnan(inBetween));
dist2Nan = dist2(~isnan(inBetween));
h=fill(dist2Nan, inBetweenNan, [0.8500 0.3250 0.0980]);
set(h,'facealpha',.1,'linestyle','none');


title ('Cell shape anisotropy vs. distance to nearest defect')
legend('P/sqrt(A)','mean +/- std')
xlabel('Distance from nearest defect (um)')
ylabel('Shape anisotropy (P/sqrt(A)')


cd(datasetPlots); saveas(fig4,['ShapeAnisotropy','.png'])

% Historgram of cell shape anisotropy distribution
figure();
[counts,edges]=histcounts(PAVec,'Normalization','probability');
fig4B = histogram('BinEdges',edges,'BinCounts',counts*100)
title('{\bf\fontsize{16} Cell shape index distribution}');
xlabel('{\bf\fontsize{16}Cell shape index (P/sqrt(A))}')
ylabel('{\bf\fontsize{16}% of cells}')
set(gca,'fontsize',12)
xlim([3 6])

cd(datasetPlots); saveas(fig4B,['ShapeAnisotroyHist','.png'])

close all;

%%
% Historgram of cell neighbour number
figure();
[counts,edges]=histcounts(neighbourVec,'Normalization','probability');
fig6B = histogram('BinEdges',edges,'BinCounts',counts*100)
title('{\bf\fontsize{16} Number of neighbours per cell}');
xlabel('{\bf\fontsize{16}Neighbour number}')
ylabel('{\bf\fontsize{16}% of cells}')
set(gca,'fontsize',12)
xlim([3 6])

cd(datasetPlots); saveas(fig6B,['NeighbourNumHist','.png'])

close all;
%%
% Historgram of cell thickness
% figure();
% [counts,edges]=histcounts(thicknessVec,'Normalization','probability');
% fig6B = histogram('BinEdges',edges,'BinCounts',counts*100)
% title('{\bf\fontsize{16} Cell thickness distribution}');
% xlabel('{\bf\fontsize{16} Cell thickness (um)}')
% ylabel('{\bf\fontsize{16}% of cells}')
% set(gca,'fontsize',12)
%
% cd(datasetPlots); saveas(fig6B,['CellThicknessHist','.png'])
%
% close all;


%% Cell vs. fibre orientation

sortedFOrient = ForientVec(ind);
sortedCOrient = orientAngleVec(ind);
% Difference in orientation between cells and fibres:
origDifOrient  = min(abs(ForientVec-orientAngleVec),pi-abs(ForientVec-orientAngleVec));
difOrient = min(abs(sortedFOrient-sortedCOrient),pi-abs(sortedFOrient-sortedCOrient));
[stdDifOrient , meanDifOrient] = stdGaussianXval (sortedDist, difOrient, distVal, sigma, 0); % calculate the mean and std using a Gaussian filter for each data on the same time points
MeanPlusStdDifOrient = meanDifOrient+stdDifOrient;
MeanMinusStdDifOrient = meanDifOrient-stdDifOrient;
figure();
plot(sortedDist,difOrient,'.','Color',(1/255)*[0, 255, 157])
hold on
plot(distVal,meanDifOrient,'Color',(1/255)*[40, 173, 122],'LineWidth',2)
hold on
ylim([0 1.6])

inBetween = [MeanPlusStdDifOrient, fliplr(MeanMinusStdDifOrient)]; % shaded region with std
dist2 = [distVal,fliplr(distVal)];

inBetweenNan = inBetween(~isnan(inBetween));
dist2Nan = dist2(~isnan(inBetween));
h=fill(dist2Nan, inBetweenNan, (1/255)*[0, 255, 157]);
set(h,'facealpha',.1,'linestyle','none');

% Include only polar cells
polarInd = find(sortedAspectRatio>=1.25);


if length(find(~isnan(sortedDist)))~=0
    [stdDifOrientP , meanDifOrientP] = stdGaussianXval (sortedDist(polarInd), difOrient(polarInd), distVal(polarInd), sigma, 0); % calculate the mean and std using a Gaussian filter for each data on the same time points
    MeanPlusStdDifOrientP = meanDifOrientP+stdDifOrientP;
    MeanMinusStdDifOrientP = meanDifOrientP-stdDifOrientP;
    
    figure();
    plot(sortedDist(polarInd),difOrient(polarInd),'.','Color',(1/255)*[0, 229, 255])
    hold on
    plot(distVal(polarInd),meanDifOrientP,'Color',(1/255)*[0, 98, 255],'LineWidth',2)
    hold on
    ylim([0 1.6])
    
    inBetween = [MeanPlusStdDifOrientP, fliplr(MeanMinusStdDifOrientP)]; % shaded region with std
    dist2 = [distVal(polarInd),fliplr(distVal(polarInd))];
    
    inBetweenNan = inBetween(~isnan(inBetween));
    dist2Nan = dist2(~isnan(inBetween));
    h=fill(dist2Nan, inBetweenNan, (1/255)*[0, 229, 255]);
    set(h,'facealpha',.1,'linestyle','none');
    
    % Include only cells with high fibre coherency
    cohInd = find(sortedCoh>=0.95);
    
    [stdDifOrientC , meanDifOrientC] = stdGaussianXval (sortedDist(cohInd), difOrient(cohInd), distVal(cohInd), sigma, 0); % calculate the mean and std using a Gaussian filter for each data on the same time points
    MeanPlusStdDifOrientC = meanDifOrientC+stdDifOrientC;
    MeanMinusStdDifOrientC = meanDifOrientC-stdDifOrientC;
    
    figure();
    plot(sortedDist(cohInd),difOrient(cohInd),'.','Color',(1/255)*[235, 162, 245])
    hold on
    plot(distVal(cohInd),meanDifOrientC,'Color',(1/255)*[102, 49, 110],'LineWidth',2)
    hold on
    ylim([0 1.6])
    
    inBetween = [MeanPlusStdDifOrientC, fliplr(MeanMinusStdDifOrientC)]; % shaded region with std
    dist2 = [distVal(cohInd),fliplr(distVal(cohInd))];
    
    inBetweenNan = inBetween(~isnan(inBetween));
    dist2Nan = dist2(~isnan(inBetween));
    h=fill(dist2Nan, inBetweenNan, (1/255)*[235, 162, 245]);
    set(h,'facealpha',.1,'linestyle','none');
    
    % Filter by coherence and polarity
    PCInd = find(and(sortedCoh>=0.92,sortedAspectRatio>=1.25));
    
    [stdDifOrientCP , meanDifOrientCP] = stdGaussianXval (sortedDist(PCInd), difOrient(PCInd), distVal(PCInd), sigma, 0); % calculate the mean and std using a Gaussian filter for each data on the same time points
    MeanPlusStdDifOrientCP = meanDifOrientCP+stdDifOrientCP;
    MeanMinusStdDifOrientCP = meanDifOrientCP-stdDifOrientCP;
    
    fig5 = figure();
    plot(sortedDist(PCInd),difOrient(PCInd),'.','Color',(1/255)*[250, 176, 65])
    hold on
    plot(distVal(PCInd),meanDifOrientCP,'Color',(1/255)*[217, 130, 0],'LineWidth',2)
    hold on
    ylim([0 1.6])
    
    inBetween = [MeanPlusStdDifOrientCP, fliplr(MeanMinusStdDifOrientCP)]; % shaded region with std
    dist2 = [distVal(PCInd),fliplr(distVal(PCInd))];
    
    inBetweenNan = inBetween(~isnan(inBetween));
    dist2Nan = dist2(~isnan(inBetween));
    h=fill(dist2Nan, inBetweenNan, (1/255)*[250, 176, 65]);
    set(h,'facealpha',.1,'linestyle','none');
    
    
    title({'{\bf\fontsize{12} Cell vs. Local Fibre Orientation }'; '{\bf\fontsize{10}Coherence threshold 0.92, Polarity threshold 1.25} '},'FontWeight','Normal')
    
    legend('Angle difference','mean +/- std')
    xlabel('Distance from nearest defect (um)')
    ylabel('Angle difference (rad)')
    
    cd(datasetPlots); saveas(fig5,['CellFibreOrient','.png'])
end

% Historgram of cell vs. fibre orientation
figure();
origPCInd = find(and(cohVec>=0.92,aspectRatioVec>=1.25));
[counts,edges]=histcounts(origDifOrient(origPCInd),'Normalization','probability');
fig5B = histogram('BinEdges',edges,'BinCounts',counts*100)
title({'{\bf\fontsize{14} Cell vs. Local Fibre Orientation }'; '{\bf\fontsize{12}Coherence threshold 0.92, Polarity threshold 1.25} '},'FontWeight','Normal')
xlabel('{\bf\fontsize{14}Relative angle}')
ylabel('{\bf\fontsize{14}% of cells}')
set(gca,'fontsize',12)
cd(datasetPlots); saveas(fig5B,['relativeOrientHist','.png'])

%% Plots for cell orientation

for m = 0:length(fileNames)-1
    
    thisFrame=m;
    fIndex = find(strcmp({fullCellDataMod.frame}, num2str(thisFrame))==1);
    orient2D = [];
    xVal = [];
    yVal = [];
    Dx = [];
    Dy = [];
    allTheta = [];
    
    % Read cell and local fibre orientation for every cell in this frame:
    for k=1:length(fIndex)
        if ~isempty(fullCellDataMod(fIndex(k)).orientation)
            thisOrient3D = fullCellDataMod(fIndex(k)).orientation';
            aspectRatio = fullCellDataMod(fIndex(k)).aspect_ratio;
            thisOrient2D = thisOrient3D;
            thisOrient2D(3)=0;
            thisOrient2D = (thisOrient2D/norm(thisOrient2D))*aspectRatio;
            orient2D(k,:)=thisOrient2D(1:2,:);
            theta=fullCellDataMod(fIndex(k)).fibreOrientation; % this is the angle on the grid points
            allTheta(k) = fullCellDataMod(fIndex(k)).fibreOrientation; % this is the angle on the grid points;
            Dx(k)=cos(theta);  % define the angle of the orientation
            Dy(k)=sin(theta); %
            
            xVal(k) = fullCellDataMod(fIndex(k)).centre_x;
            yVal(k) = fullCellDataMod(fIndex(k)).centre_y;
            
        else
            continue
        end
    end
    
    % Save image of cell orientation overlayed on cell image
    thisFileImName = sortedFileNames{thisFrame+1};
    cd (cellIMDir); thisIm=importdata(thisFileImName);
    sizeY = size(thisIm,2);
    fig1 = figure();
    imshow(thisIm,[]); hold on
    signY = sign(orient2D(:,1));
    signX = sign(orient2D(:,2));
    scaleF=8;
    q=quiver(xVal'-scaleF*(orient2D(:,2)/2), yVal'-scaleF*(orient2D(:,1)/2), scaleF*orient2D(:,2),scaleF*orient2D(:,1)); % plot the quiver with an additional factor 2 downsampling for better visualization
    q.LineWidth=1; % width of quiver lines
    q.ShowArrowHead = 'off'; % line with no arrowhead
    q.Color = [1 0 0]; % black quiver lines
    q.AutoScale = 'off';
    
    plotOutDirC = [cellPlotDir,'\CellOrientationC'];
    mkdir(plotOutDirC);
    cd(plotOutDirC); saveas(fig1,[thisFileImName,'.png'])
    
    % Save image of cell orientation overlayed on fibre image
    dirFibres = [mainDir,'\Orientation_Analysis\AdjustedImages']; % masked local order parameter field
    endName=strfind(thisFileImName,'.');
    thisFileImNameBase = thisFileImName (1:endName-1); %without the .filetype
    cd (dirFibres); thisIm=importdata([thisFileImNameBase,'.png']);
    fig2 = figure();
    imshow(thisIm,[]); hold on
    signY = sign(orient2D(:,1));
    signX = sign(orient2D(:,2));
    scaleF=8;
    q=quiver(xVal'-scaleF*(orient2D(:,2)/2), yVal'-scaleF*(orient2D(:,1)/2), scaleF*orient2D(:,2),scaleF*orient2D(:,1)); % plot the quiver with an additional factor 2 downsampling for better visualization
    q.LineWidth=1; % width of quiver lines
    q.ShowArrowHead = 'off'; % line with no arrowhead
    q.Color = [1 0 0]; % black quiver lines
    q.AutoScale = 'off';
    
    plotOutDirF = [cellPlotDir,'\CellOrientationF'];
    mkdir(plotOutDirF);
    cd(plotOutDirF); saveas(fig2,[thisFileImName,'.png'])
    close all
    
    % Plot graphs of fibre vs. cell relative angle for each frame
    
    fig3 = figure();
    thisOrient = origDifOrient(fIndex);
    thisCoh = cohVec(fIndex);
    thisPol = aspectRatioVec(fIndex);
    thisDist = minDist(fIndex);
    thisInd = find(and(thisCoh>=0.92,thisPol>=1.2));
    
    plot(thisDist(thisInd),thisOrient(thisInd),'.','Color',[0, 0, 1])
    plotOutDirAngleDist = [cellPlotDir,'\CellvsFibreOrient'];
    title('Cell vs. Local Fibre Orientation (frame)');
    xlabel('Distance from nearest defect (um)')
    ylabel('Angle difference (rad)')
    mkdir(plotOutDirAngleDist);
    cd(plotOutDirAngleDist); saveas(fig3,[thisFileImName,'.png'])
    
    fig4 = figure();
    edges = [0:pi/16:pi/2];
    histogram(thisOrient(thisInd),edges)
    plotOutDirAngleHist = [cellPlotDir,'\CellvsFibreHist'];
    title('Relative cell vs. fibre orientation (frame)');
    xlabel('Angle difference (rad)')
    ylabel('Counts')
    ylim([0 50]);
    mkdir(plotOutDirAngleHist);
    cd(plotOutDirAngleHist); saveas(fig4,[thisFileImName,'.png'])
    close all
    
end
%% Prepare list of neighbours of every rank for spatial correlations
neighbourArray = struct();
for i = 1:size(fullCellDataMod,2)
    i
    if ~isempty (fullCellDataMod(i).neighbourList)
        neighbourArray(i).neighbour1List = fullCellDataMod(i).neighbourList;
        contCount=1;
        k = 1; % Neighbour rank
        allNeighbours = neighbourArray(i).neighbour1List;
        while contCount==1
            thisField = ['neighbour',num2str(k),'List'];
            nb = neighbourArray(i).(thisField);
            nextNeighbours = [];
            for j=1:length(nb)
                nextNeighbours = [nextNeighbours,fullCellDataMod(nb(j)).neighbourList];
                nextNeighbours = nextNeighbours(nextNeighbours~=i);
                nextNeighbours = setdiff(nextNeighbours,allNeighbours);
            end
            allNeighbours = [allNeighbours, nextNeighbours];
            nextField = ['neighbour',num2str(k+1),'List'];
            neighbourArray(i).(nextField)=nextNeighbours;
            k = k+1; % Increase neighbour rank for next iteration
            contCount = ~isempty(nextNeighbours);
        end
    end
end
% Prepare lists of neighbour pairs of all ranks
pairList = cell(length(fieldnames(neighbourArray)),1);
for i = 1:size(neighbourArray,2)
    i
    if ~isempty (neighbourArray(i).neighbour1List)
        for k=1:length(fieldnames(neighbourArray))
            thisField = ['neighbour',num2str(k),'List'];
            nb = neighbourArray(i).(thisField);
            newPairs = [];
            for j=1:length(nb)
                newPairs = [newPairs;[i,nb(j)]];
            end
            pairList{k}=[pairList{k};newPairs];
        end
    end
end
%% Plot cell areas and number of neihgbours on cell image
corr=[];
corrV2=[];

for m = 0:length(fileNames)-1
    
    thisFrame=m;
    fIndex = find(strcmp({fullCellDataMod.frame}, num2str(thisFrame))==1);
    neighbours = [];
    outline = {};
    in = {};
    thisFileImName = sortedFileNames{thisFrame+1};
    cd (cellIMDir); thisIm=importdata(thisFileImName);
    sizeX = size(thisIm,2);
    sizeY = size(thisIm,2);
    areaMap = zeros(size(thisIm));
    PAMap = zeros(size(thisIm));
    neighbourMap = zeros(size(thisIm));
    %     thicknessMap = zeros(size(thisIm));
    
    [xq,yq] = meshgrid(1:sizeY,1:sizeX); % Making a grid
    % Read pixels in each cell, number of neighbours, and cell area for each
    % cell in this image:
    for k=1:length(fIndex)
        if ~isempty(fullCellDataMod(fIndex(k)).orientation)
            outline{k}=fullCellDataMod(fIndex(k)).outline;
            neighbours(k) = length(fullCellDataMod(fIndex(k)).neighbourList);
            in{k} = inpolygon(xq,yq,outline{k}(:,1),outline{k}(:,2));
            areaMap(in{k})=fullCellDataMod(fIndex(k)).area;
            PAMap(in{k})=fullCellDataMod(fIndex(k)).perimeter./sqrt(fullCellDataMod(fIndex(k)).area);
            neighbourMap(in{k})= neighbours(k);
            %             thicknessMap(in{k})= fullCellDataMod(fIndex(k)).umThickness;
        else
            continue
        end
    end
    %   Calibration for area map
    areaMap = areaMap*(calibrationXY^2);
    %   Rotate and flip maps to match visualisation of read images
    rotAreaMap = rot90(areaMap,3);
    flipAreaMap = flip(rotAreaMap,2);
    rotPAMap = rot90(PAMap,3);
    flipPAMap = flip(rotPAMap,2);
    rotNeighbourMap = rot90(neighbourMap,3);
    flipNeighbourMap = flip(rotNeighbourMap,2);
    %     rotThicknessMap = rot90(thicknessMap,3);
    %     flipThicknessMap = flip(rotThicknessMap,2);
    
    % Save image of cells color-coded by area:
    fig1 = figure();
    imshow(flipAreaMap,[]);
    colormap jet;
    colorbar;
    caxis([	prctile(areaVec,1) prctile(areaVec,99)])
    title('{\bf\fontsize{16} Cell Area (um^2)}')
    areaMapOutDir = [cellPlotDir,'\cellAreaMaps'];
    mkdir(areaMapOutDir);
    cd(areaMapOutDir); saveas(fig1,[thisFileImName,'.png'])
    close all
    %     % Save images of cells color-coded by number of neighbours:
    fig2 = figure();
    imshow(flipNeighbourMap,[]);
    colormap jet;
    colorbar;
    caxis([	min(neighbourVec) max(neighbourVec)])
    title('{\bf\fontsize{16}No. of Neighbours per cell}')
    neighbourMapOutDir = [cellPlotDir,'\neighbourMaps'];
    mkdir(neighbourMapOutDir);
    cd(neighbourMapOutDir); saveas(fig2,[thisFileImName,'.png'])
    close all
    %      % Save images of cells color-coded by cell shape anisotropy (P/sqrt(A)):
    fig3 = figure();
    imshow(flipPAMap,[]);
    colormap jet;
    colorbar;
    caxis([	3 5])
    title(' {\bf\fontsize{16} Cell Shape Anisotropy (P/sqrt(A))}')
    PAMapOutDir = [cellPlotDir,'\PAMaps'];
    mkdir(PAMapOutDir);
    cd(PAMapOutDir); saveas(fig3,[thisFileImName,'.png'])
    close all
    %     fig4 = figure();
    %     imshow(flipThicknessMap,[]);
    %     colormap jet;
    %     colorbar;
    %     caxis([	prctile(thicknessVec,1) prctile(thicknessVec,99)])
    %     title(' {\bf\fontsize{16} Cell Thickness (um))}')
    %     ThicknessMapOutDir = [cellPlotDir,'\ThicknessMaps'];
    %     mkdir(ThicknessMapOutDir);
    %     cd(ThicknessMapOutDir); saveas(fig4,[thisFileImName,'.png'])
    %     close all
    
    % Histograms and statistics of measures per frame (area, p/sqrt(A),
    % aspect ratio:
    
    % Spatial correlations per frame
    for i=1:length(pairList)
        % If using flag:
        %         thisVar = thicknessVec;
        thisVar = origDifOrient;
        % thisFlag1 = origPCInd;
        thisFlag2 = fIndex;
        flag = zeros(size(thisVar));
        flag(thisFlag2)=1;
        % flag(edgeFlag==1)=0;
        % flag(intersect(thisFlag1,thisFlag2))=1;
        subFactor1 = [];
        subFactor2 = [];
        for j=1:length(pairList{i})
            subFactor1(j) = thisVar(pairList{i}(j,1))*flag(pairList{i}(j,1));
            subFactor2(j) = thisVar(pairList{i}(j,2))*flag(pairList{i}(j,2));
        end
        normSet1 = subFactor1(intersect(find(subFactor1),find(subFactor2)))-nanmean(subFactor1(intersect(find(subFactor1),find(subFactor2))));
        normSet2 = subFactor2(intersect(find(subFactor1),find(subFactor2)))-nanmean(subFactor2(intersect(find(subFactor1),find(subFactor2))));
        normSet1V2 = subFactor1(intersect(find(subFactor1),find(subFactor2)))-nanmean(thisVar(thisFlag2));
        normSet2V2 = subFactor2(intersect(find(subFactor1),find(subFactor2)))-nanmean(thisVar(thisFlag2));
        num = nansum(normSet1.*normSet2);
        denom = sqrt(nansum(normSet1.^2)*nansum(normSet2.^2));
        corr(m+1,i) = num/denom;
        numV2 = nansum(normSet1V2.*normSet2V2);
        denomV2 = sqrt(nansum(normSet1V2.^2)*nansum(normSet2V2.^2));
        corrV2(m+1,i) = numV2/denomV2;
        pairCount(m+1,i) = length(subFactor1(intersect(find(subFactor1),find(subFactor2))));
    end
    %     fig4 = figure();
    %     plot(corr(m+1,:))
    %     title('Spatial correlation of cell area');
    %     %title('Spatial correlation of fibre vs. cell orientation');
    %     xlabel('Neighbour rank')
    %     ylabel('Correlation function')
    %     % plotOutDirPACorr = [cellPlotDir,'\Correlations_PA'];
    %     plotOutDirPACorr = [cellPlotDir,'\Correlations_Area'];
    %     mkdir(plotOutDirPACorr);
    %     cd(plotOutDirPACorr); saveas(fig4,[thisFileImName,'.png'])
    %     fig4B = figure();
    %     plot(corrV2(m+1,:))
    %     title('Spatial correlation of cell area');
    %     %title('Spatial correlation of fibre vs. cell orientation');
    %     xlabel('Neighbour rank')
    %     ylabel('Correlation function')
    %     % plotOutDirPACorr = [cellPlotDir,'\Correlations_PA'];
    %     plotOutDirPACorr = [cellPlotDir,'\Correlations_Area_V2mean'];
    %     mkdir(plotOutDirPACorr);
    %     cd(plotOutDirPACorr); saveas(fig4B,[thisFileImName,'.png'])
    
    fig4C = figure();
    plot(1:size(corr,2),corr(m+1,:),1:size(corrV2,2),corrV2(m+1,:))
    % title('Spatial correlation of cell thickness');
    title('Spatial correlation of fibre vs. cell orientation');
    xlabel('Neighbour rank')
    ylabel('Correlation function')
    legend('Normalization by neighbour list mean','Normalization by all cells mean')
    plotOutDirPACorr = [cellPlotDir,'\Correlations_PA'];
    % plotOutDirPACorr = [cellPlotDir,'\Correlations_thickness_compare'];
    mkdir(plotOutDirPACorr);
    cd(plotOutDirPACorr); saveas(fig4C,[thisFileImName,'.png'])
    close all
end

allCorr = nanmean(corr,1);
allCorrWeighed = corr.*pairCount;
meanCorrWeighted = nansum(allCorrWeighed)./nansum(pairCount);
% fig7 = figure();
% plot(meanCorrWeighted)
% title(' {\bf\fontsize{16}Spatial correlation of shape index}');
% xlabel(' {\bf\fontsize{16}Neighbour rank}')
% ylabel(' {\bf\fontsize{16}Correlation function}')
% set(gca,'fontsize',12)
% cd(datasetPlots); saveas(fig7,['SpatialCorrelationPAFrameAvg','.png'])

allCorrV2 = nanmean(corrV2,1);
allCorrWeighedV2 = corrV2.*pairCount;
meanCorrWeightedV2 = nansum(allCorrWeighedV2)./nansum(pairCount);
fig7V2 = figure();
plot(1:size(corr,2),meanCorrWeighted,1:size(corrV2,2),meanCorrWeightedV2)
title(' {\bf\fontsize{16}Spatial correlation of fibre vs. cell orientation}');
xlabel(' {\bf\fontsize{16}Neighbour rank}')
ylabel(' {\bf\fontsize{16}Correlation function}')
legend('Normalization by neighbour list mean','Normalization by all cells mean')
set(gca,'fontsize',12)
cd(datasetPlots); saveas(fig7V2,['SpatialCorrelationCellVsFibreOrientFrameAvgBoth','.png'])

% fig7C = figure();
% plot(1:size(corr,2),allCorr,1:size(corrV2,2),allCorrV2)
% title(' {\bf\fontsize{16}Spatial correlation of cell thickness}');
% xlabel(' {\bf\fontsize{16}Neighbour rank}')
% ylabel(' {\bf\fontsize{16}Correlation function}')
% legend('Normalization by neighbour list mean','Normalization by all cells mean')
% set(gca,'fontsize',12)
% cd(datasetPlots); saveas(fig7C,['SpatialCorrelationThicknessFrameAvgNoWeights','.png'])
%% Spatial correlations
% By neighbour rank
neighbourArray = struct();
for i = 1:size(fullCellDataMod,2)
    i
    if ~isempty (fullCellDataMod(i).neighbourList)
        neighbourArray(i).neighbour1List = fullCellDataMod(i).neighbourList;
        contCount=1;
        k = 1; % Neighbour rank
        allNeighbours = neighbourArray(i).neighbour1List;
        while contCount==1
            thisField = ['neighbour',num2str(k),'List'];
            nb = neighbourArray(i).(thisField);
            nextNeighbours = [];
            for j=1:length(nb)
                nextNeighbours = [nextNeighbours,fullCellDataMod(nb(j)).neighbourList];
                nextNeighbours = nextNeighbours(nextNeighbours~=i);
                nextNeighbours = setdiff(nextNeighbours,allNeighbours);
            end
            allNeighbours = [allNeighbours, nextNeighbours];
            nextField = ['neighbour',num2str(k+1),'List'];
            neighbourArray(i).(nextField)=nextNeighbours;
            k = k+1; % Increase neighbour rank for next iteration
            contCount = ~isempty(nextNeighbours);
        end
    end
end
% Prepare lists of neighbour pairs of all ranks
pairList = cell(length(fieldnames(neighbourArray)),1);
for i = 1:size(neighbourArray,2)
    i
    if ~isempty (neighbourArray(i).neighbour1List)
        for k=1:length(fieldnames(neighbourArray))
            thisField = ['neighbour',num2str(k),'List'];
            nb = neighbourArray(i).(thisField);
            newPairs = [];
            for j=1:length(nb)
                newPairs = [newPairs;[i,nb(j)]];
            end
            pairList{k}=[pairList{k};newPairs];
        end
    end
end

% Calculate contribution of each pair to correlation function:
% FOR DATA SAVED IN CELL DATA STRUCTURE

corr=[];
for i=1:length(pairList)-1
    thisField = 'fibreOrientation';
    %     corrFactor = [];
    subFactor1 = [];
    subFactor2 = [];
    for j=1:length(pairList{i})
        %         corrFactor(j) = fullCellDataMod(pairList{i}(j,1)).(thisField)*fullCellDataMod(pairList{i}(j,2)).(thisField);
        subFactor1(j) = fullCellDataMod(pairList{i}(j,1)).(thisField);
        subFactor2(j) = fullCellDataMod(pairList{i}(j,2)).(thisField);
    end
    normSet1 = subFactor1-nanmean(subFactor1);
    normSet2 = subFactor2-nanmean(subFactor2);
    num = nansum(normSet1.*normSet2);
    denom = sqrt(nansum(normSet1.^2)*nansum(normSet2.^2));
    corr(i) = num/denom;
end
fig1 = figure();
plot(corr)
title('Spatial correlation of cell aspect ratio');
xlabel('Neighbour rank')
ylabel('Correlation function')
cd(datasetPlots); saveas(fig1,['SpatialCorrelationAspectRatio','.png'])

% FOR DATA CALCULATED LOCALLY FROM CELL DATA
corr=[];
for i=1:length(pairList)-1
    % If using flag:
    thisVar = areaVec;
    %      thisFlag = origPCInd;
    %      flag = zeros(size(thisVar));
    %      flag(thisFlag)=1;
    % If no flag needed,use:
    %    thisVar = origDifOrient;
    flag=ones(size(thisVar));
    flag(edgeFlag==1)=0;
    subFactor1 = [];
    subFactor2 = [];
    for j=1:length(pairList{i})
        subFactor1(j) = thisVar(pairList{i}(j,1))*flag(pairList{i}(j,1));
        subFactor2(j) = thisVar(pairList{i}(j,2))*flag(pairList{i}(j,2));
    end
    normSet1 = subFactor1(intersect(find(subFactor1),find(subFactor2)))-nanmean(subFactor1(intersect(find(subFactor1),find(subFactor2))));
    normSet2 = subFactor2(intersect(find(subFactor1),find(subFactor2)))-nanmean(subFactor2(intersect(find(subFactor1),find(subFactor2))));
    %     normSet1 = subFactor1(intersect(find(subFactor1),find(subFactor2)))-nanmean(thisVar);
    %     normSet2 = subFactor2(intersect(find(subFactor1),find(subFactor2)))-nanmean(thisVar);
    %
    num = nansum(normSet1.*normSet2);
    denom = sqrt(nansum(normSet1.^2)*nansum(normSet2.^2));
    corr(i) = num/denom;
    
end
fig2 = figure();
plot(corr)
title(' {\bf\fontsize{16}Spatial correlation of cell areas}');
xlabel(' {\bf\fontsize{16}Neighbour rank}')
ylabel(' {\bf\fontsize{16}Correlation function}')
set(gca,'fontsize',12)
cd(datasetPlots); saveas(fig2,['SpatialCorrelationAreasNoEdgeV2','.png'])


%
% fig8 = figure();
% plot(numPairs/2)
% title(' {\bf\fontsize{16} Number of pairs by neighbour rank}');
% xlabel(' {\bf\fontsize{16}Neighbour rank}')
% ylabel(' {\bf\fontsize{16}Number of pairs}')
% set(gca,'fontsize',12)
% cd(datasetPlots); saveas(fig8,['NumPairs','.png'])


%% Histograms and statistics of measures per frame (area, p/sqrt(A),aspect ratio:
areaMean = [];
areaStd = [];
for m = 0:length(fileNames)-1
    
    thisFrame=m;
    fIndex = find(strcmp({fullCellDataMod.frame}, num2str(thisFrame))==1);
    thisFileImName = sortedFileNames{thisFrame+1};
    % Area distributions
    areaMean(m+1) = nanmean(areaVec(fIndex));
    areaStd(m+1) = std(areaVec(fIndex),'omitnan');
    [counts,edges]=histcounts(areaVec(fIndex),'Normalization','probability');
    fig1 = histogram('BinEdges',edges,'BinCounts',counts*100)
    title({'{\bf\fontsize{12} Cell area distribution }'; ['Mean: ',num2str(round(areaMean(m+1))),', Std: ',num2str(round(areaStd(m+1)))]},'FontWeight','Normal')
    xlabel('{\bf\fontsize{16}Cell area (um^2)}')
    ylabel('{\bf\fontsize{16}% of cells}')
    xlim([	0 prctile(areaVec,99)]);
    set(gca,'fontsize',12)
    areaDistDir = [cellPlotDir,'\CellAreaDist'];
    mkdir(areaDistDir);
    cd(areaDistDir); saveas(fig1,[thisFileImName,'.png'])
    close all
    
    % Aspect ratio distributions
    aspectRatioMean(m+1) = nanmean(aspectRatioVec(fIndex));
    aspectRatioStd(m+1) = std(aspectRatioVec(fIndex),'omitnan');
    [counts,edges]=histcounts(aspectRatioVec(fIndex),'Normalization','probability');
    fig1 = histogram('BinEdges',edges,'BinCounts',counts*100)
    title({'{\bf\fontsize{12} Cell aspect ratio distribution }'; ['Mean: ',num2str(round(aspectRatioMean(m+1),2)),', Std: ',num2str(round(aspectRatioStd(m+1),2))]},'FontWeight','Normal')
    xlabel('{\bf\fontsize{16}Cell aspect ratio}')
    ylabel('{\bf\fontsize{16}% of cells}')
    xlim([	0  max(aspectRatioVec)]);
    set(gca,'fontsize',12)
    aspectRatioDistDir = [cellPlotDir,'\CellAspectRatioDist'];
    mkdir(aspectRatioDistDir);
    cd(aspectRatioDistDir); saveas(fig1,[thisFileImName,'.png'])
    close all
    
    
    % Cell shape index distributions
    PAMean(m+1) = nanmean(PAVec(fIndex));
    PAStd(m+1) = std(PAVec(fIndex),'omitnan');
    [counts,edges]=histcounts(PAVec(fIndex),'Normalization','probability');
    fig1 = histogram('BinEdges',edges,'BinCounts',counts*100)
    title({'{\bf\fontsize{12} Cell shape index (P/sqrt(A)) distribution }'; ['Mean: ',num2str(round(PAMean(m+1),2)),', Std: ',num2str(round(PAStd(m+1),2))]},'FontWeight','Normal')
    xlabel('{\bf\fontsize{16}Cell shape index}')
    ylabel('{\bf\fontsize{16}% of cells}')
    xlim([	3  5.5]);
    set(gca,'fontsize',12)
    PADistDir = [cellPlotDir,'\CellShapeIndexDist'];
    mkdir(PADistDir);
    cd(PADistDir); saveas(fig1,[thisFileImName,'.png'])
    close all
end

figure();
errorbar(areaMean,areaStd)

figure();
errorbar(aspectRatioMean,aspectRatioStd)

figure();
errorbar(PAMean,PAStd)
%% Vertex data - calculate distances between vertices, and identify >3-fold vertices using minimum distance between vertices

maxDist = 2; % Maximum distance between vertices to count them as a single vertex.

% Run over all vertices and calculate distance to all other vertices in the
% frame
for m = 0:length(fileNames)-1
    thisFrame=m;
    fIndex = find([fullVertexData.frame]==m);
    for i=1:length(fIndex)
        xPos = fullVertexData(fIndex(i)).x_pos;
        yPos = fullVertexData(fIndex(i)).y_pos;
        fullVertexData(fIndex(i)).vDist =[];
        for j=1:length(fIndex)
            xPos2 =  fullVertexData(fIndex(j)).x_pos;
            yPos2 = fullVertexData(fIndex(j)).y_pos;
            fullVertexData(fIndex(i)).vDist(j) = sqrt((xPos-xPos2)^2+(yPos-yPos2)^2);
        end
    end
end
% For a certain maxDist, run over all vertices and list all vertices that are
% closer than this distance from the first vertex.
for m = 0:length(fileNames)-1
    thisFrame=m;
    fIndex = find([fullVertexData.frame]==m);
    for i=1:length(fIndex)
        fullVertexData(fIndex(i)).closeV =fIndex(find(fullVertexData(fIndex(i)).vDist<=maxDist));
        fullVertexData(fIndex(i)).vDeg = length(unique([fullVertexData(fullVertexData(fIndex(i)).closeV).cells]));
    end
end

% Plot histogram of vertex degree:

cats = 3:max([fullVertexData.vDeg]);
catsStr = num2cell(num2str(cats'));
C = categorical([fullVertexData.vDeg],cats,catsStr);

histogram(C,'BarWidth',0.75);

vDefectDist=[];
for i=1:length(fullVertexData)
    if ~isempty(min(fullVertexData(i).defectDist))
        vDefectDist(i) = min(fullVertexData(i).defectDist);
    else
    end
end

% Histogram of vertex distances for each degree of vertex

if ~isempty(vDefectDist)
    for i=1:length(cats)
        degFlag = [fullVertexData.vDeg]==cats(i);
        degDists{i} = vDefectDist(degFlag);
    end
    
end
% Plot 4-fold vertices as function of OP or distance from defect - need to
% read data from defects and OP into vertex list as well as cell list.
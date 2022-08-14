addpath(genpath('\\phhydra\phhydraB\Analysis\users\Yonit\MatlabCodes\GroupCodes\July2021'));

dir1 = 'Z:\Analysis\users\Yonit\Movie_Analysis\DefectLibrary\2020_09_01_18hr_set1\Cells';
dir2 = 'Z:\Analysis\users\Yonit\Movie_Analysis\DefectLibrary\2020_09_08_18hr_set1\Cells';

dir3 = 'Z:\Analysis\users\Yonit\Movie_Analysis\Labeled_cells\2021_05_06_pos6\Cells';

cellIMDir = 'Z:\Analysis\users\Yonit\Movie_Analysis\Labeled_cells\2021_05_06_pos6\Cells\AllSegmented';

db_arr = [Experiment(dir1),Experiment(dir2)];
[cell_arr,db_arr] = db_arr.cells;
[bond_arr,db_arr] = db_arr.bonds;
[frame_arr,db_arr] = db_arr.frames;


%% Time plots

this_arr = cell_arr;
this_field = 'area';
calibration = 0.52^2;

f3 = timePlot(this_arr,this_field,calibration)
figure(f3)

title('{\bf\fontsize{16} Mean cell area as function of time}')
xlabel('{\bf\fontsize{16} Time (minutes)}')
ylabel('{\bf\fontsize{16} Cell area (um^2)}')
set(gca,'fontsize',12)

[f1,f2] = distPlot(cell_arr,'area',calibration)

[f1,f2] = cdfPlot(cell_arr,'area',calibration)


[f1,f2] = distPlot(this_arr,this_field,calibration)
figure(f1)
title('{\bf\fontsize{16} Cell area distribution}');
xlabel('{\bf\fontsize{16} Cell area (um^2)}')
ylabel('{\bf\fontsize{16} % of cells}')
set(gca,'fontsize',12)
figure(f2)
title('{\bf\fontsize{16} Cell area distribution (Log-Log)}');
xlabel('{\bf\fontsize{16} Cell area (um^2)}')
ylabel('{\bf\fontsize{16} % of cells}')
set(gca,'fontsize',12)


[f3,f4,~,~] = cdfPlot(this_arr,this_field,calibration)
figure(f3)
title('{\bf\fontsize{16} CDF of cell areas}');
xlabel('{\bf\fontsize{16} Cell area (um^2)}')
ylabel('{\bf\fontsize{16} Probability}')
set(gca,'fontsize',12)
figure(f4)
title('{\bf\fontsize{16} CDF of cell areas (Log-Log)}');
xlabel('{\bf\fontsize{16} Cell area (um^2)}')
ylabel('{\bf\fontsize{16} Probability}')
set(gca,'fontsize',12)


% FUNCTION FOR PLOTTING DATA MAPS PER FRAME

function timeFig = timePlot(this_arr,this_field,calibration)

this_var = [this_arr.(this_field)];
this_var = this_var.*calibration;
these_frames = [this_arr.frames];
[~,ia,ic] = unique([these_frames.frame]);

for i=1:length(ia)
    mean_var(i) = mean(this_var(ic==i),'omitnan');
    std_var(i) = std(this_var(ic==i),'omitnan');
end

time_min = [these_frames(ia).time_sec]/60;

timeFig = figure();
plot(time_min,mean_var)


end


function [f1,f2] = distPlot (this_arr,this_field,calibration)

this_var = [this_arr.(this_field)];
this_var = this_var.*calibration;

f1 = figure();
[counts,edges]=histcounts(this_var,'Normalization','probability');
histogram('BinEdges',edges,'BinCounts',counts*100)

f2 = figure();
[counts,edges] = histcounts(log10(this_var),'Normalization','probability');
histogram('BinEdges',10.^edges,'BinCounts',counts*100)
set(gca, 'xscale','log','yscale','log')

end


function [fig1,fig2,stats1,stats2] = cdfPlot(this_arr,this_field,calibration)

this_var = [this_arr.(this_field)];
this_var = this_var.*calibration;

fig1 = figure()
[h1,stats1] = cdfplot(this_var);

fig2 = figure()
[h2,stats2] =cdfplot(this_var)
set(gca, 'xscale','log','yscale','log')


end
%%

function plotMeasureOnCells(frame_arr,cellIMDir,this_field,calibration)
% Make the function have the option to 
frameCells = frame_arr.cells;
% Add function to get all cell outline
for m = 1:length(frame_arr)
    outline = {};
    in = {};
    thisFileImName = frame_arr(m).frame_name{1};
    cd (cellIMDir);
    try
        thisIm=importdata([thisFileImName,'.tif']);
    catch
        thisIm=importdata([thisFileImName,'.tiff']);
    end
    
    sizeX = size(thisIm,2);
    sizeY = size(thisIm,1);
    thisMap = zeros(size(thisIm));
    [yq,yq] = meshgrid(1:sizeY,1:sizeX); % Making a grid
    % Read pixels in each cell, number of neighbours, and cell area for each
    % cell in this image:
    for k=1:length(frameCells(m,:))
        if ~isempty(frameCells(m,k).cell_id)
            outline{k}=fullCellData(fIndex(k)).outline;
            [in{k},on{k}] = inpolygon(xq,yq,outline{k}(:,1),outline{k}(:,2));
            thisMap(in{k})=frameCells(m,k).(this_field);
        else
            continue
        end
    end
    %   Calibration for area map
    thisMap = thisMap*(calibration);
    %   Rotate and flip maps to match visualisation of read images
    rotThisMap = rot90(thisMap,3);
    flipThisMap = flip(rotThisMap,2);
    % Save image of cells color-coded by area:
    fig1 = figure();
    imshow(flipThisMap,[]);
    colormap jet;
    colorbar;
    caxis([	prctile(areaVec,1) prctile(areaVec,99)])
    title('{\bf\fontsize{16} Cell Area (um^2)}')
    areaMapOutDir = [cellPlotDir,'\cellAreaMaps'];
    mkdir(areaMapOutDir);
    cd(areaMapOutDir); saveas(fig1,[thisFileImName,'.png'])
    close all
    
end
end
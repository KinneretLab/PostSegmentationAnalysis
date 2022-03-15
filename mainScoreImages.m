clear all; close all;
addpath(genpath('\\phhydra\data-new\phkinnerets\home\lab\CODE\Hydra\'));
addpath(genpath('\\phhydra\phhydraB\Analysis\users\Projects\Noam'));

mainDir='Z:\Analysis\users\Projects\Noam\Workshop\\timepoints'; % Main directory for movie you are analysing.
cellDir = [mainDir,'\Cells\']; % Cell directory for movie (this is our normal folder structure and should stay consistent).
segDir = [cellDir,'Inference\2022_01_11_CEE3_CEE5_CEE1E_CEE1E_CEE6']; % Segmentation folder.

% various visual configurations for the result images
isBinary = true; % whether binary score images should be saved or a more continuous variant with a variable color.
darken = false; % whether the cell coloring should be darked overall so the raw image can be more visible
erodeCells = true; % whether there should be a buffer space between the indicators of each cell
showBorders = false; % whether the automatic segmentatio borders should be shown (in yellow)

cd(cellDir);
load('fullCellData');

subDirs = dir(segDir);
subDirs = subDirs([subDirs.isdir] & ~strcmp({subDirs.name},'.') & ~strcmp({subDirs.name},'..'));
subDirNames = natsortfiles({subDirs.name});

% load all frames into memory
loadedFrames = cell(length(subDirs), 2);
disp('loading frames...');
for i = 1:length(subDirNames)
    dirName = subDirNames{i};
    % get all the images
    wireframe = imread(fullfile(segDir, dirName, 'handCorrection.tif'));
    loadedFrames{i, 1} = wireframe(:, :, 1);
    loadedFrames{i, 2} = imread(fullfile(cellDir, 'Raw Cortices', dirName + ".tiff"));
end

imgSize = size(loadedFrames{1, 1});
if showBorders
    summaryImages = loadedFrames(:, 1);
else
    summaryImages = cell(length(subDirs), 1);
    for i = 1:length(subDirs)
        summaryImages{i} = uint8(zeros(imgSize));
    end
end

disp('Creating composite images...');
for cellIdx = 1:length(fullCellData)
    cellData = fullCellData(cellIdx);
    images = loadedFrames(str2double(cellData.frame) + 1, :);

    [fakeImg, cellImg] = fillScore(cellData, images{1});
    summaryImages{str2double(cellData.frame) + 1} = summaryImages{str2double(cellData.frame) + 1} + ...
       getWeight(isBinary, cellData.confidence, darken) * 255 * cat(3, tryErode(fakeImg, erodeCells), ...
       tryErode(cellImg, erodeCells), zeros(imgSize));

    if rem(cellIdx, 1000) == 0
        disp(num2str(cellIdx))
    end
end

histogram([fullCellData.confidence], 'BinWidth', 0.01);

disp('Saving images...');
for imgIdx = 1:length(subDirs)
    sumImg = cat(3, summaryImages{imgIdx}(:,:,1), summaryImages{imgIdx}(:,:,2), im2uint8(loadedFrames{imgIdx, 2}(:,:,1)));
    saveToFolder(cellDir, sumImg, subDirNames(imgIdx));
end

function [fakeImg, cellImg] = fillScore(cellData, segImg)
    rawMask = 255 * uint8(imfill(imbinarize(segImg(:,:,1)), double(cellData.outline(1,:))) - imbinarize(segImg(:,:,1)));
    if cellData.confidence >= 0.5
        cellImg = rawMask;
        fakeImg = uint8(zeros(size(segImg)));
    else
        fakeImg = rawMask;
        cellImg = uint8(zeros(size(segImg)));
    end
end

function saveToFolder(location, images, imgID)
    subFolder = "Confidence/";
    if ~exist(location + subFolder, 'dir')
        mkdir(location + subFolder);
    end
    imwrite(images, location + subFolder + imgID + ".tif");
end

function weight = getWeight(binary, score, doDark)
    if binary
        weight = 1;
    else
        weight = 1.8 * abs(score - 0.5) + 0.2;
    end
    if doDark
        weight = weight * 0.2;
    end
end

function img = tryErode(img, erode)
    if erode
        sourceImg = imerode(img, strel('disk', 3));
        % select the middle index (arbitrary) for rendering a circle
        [y_cord, x_cord] = find(sourceImg);
        ind = floor(size(y_cord, 1) / 2);
        if ind > 0
            [rows, cols] = meshgrid(1:size(img, 1), 1:size(img, 2));
            img = (rows - x_cord(ind)) .^ 2 + (cols - y_cord(ind)) .^ 2 <= 4;
        end
    end
end
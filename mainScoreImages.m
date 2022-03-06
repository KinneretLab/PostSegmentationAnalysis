clear all; close all;
addpath(genpath('\\phhydra\data-new\phkinnerets\home\lab\CODE\Hydra\'));
addpath(genpath('\\phhydra\phhydraB\Analysis\users\Projects\Noam'));

mainDir='Z:\Analysis\users\Projects\Noam\Workshop\\timepoints'; % Main directory for movie you are analysing.
cellDir = [mainDir,'\Cells\']; % Cell directory for movie (this is our normal folder structure and should stay consistent).
segDir = [cellDir,'Inference\2022_01_11_CEE3_CEE5_CEE1E_CEE1E_CEE6']; % Segmentation folder.
isBinary = false; % whether binary score images should be saved or a more continuous variant with a variable color.

cd(cellDir);
load('fullCellDataMod');

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
    loadedFrames{i, 2} = loadedFrames{i, 1};
    loadedFrames{i, 3} = imread(fullfile(cellDir, 'Raw Cortices', dirName + ".tiff"));
end

lenImages = size(loadedFrames, 2);

summaryImages = loadedFrames(:, 1);

disp('Creating composite images...');
for cellIdx = 1:length(fullCellDataMod)
    cellData = fullCellDataMod(cellIdx);
    images = loadedFrames(str2double(cellData.frame) + 1, :);

    [fakeImg, cellImg] = fillScore(cellData, images{1:2});
    summaryImages{str2double(cellData.frame) + 1} = summaryImages{str2double(cellData.frame) + 1} + ...
       getWeight(isBinary, cellData.confidence) * (255 * cat(3, fakeImg, cellImg, zeros(size(fakeImg))));

    if rem(cellIdx, 1000) == 0
        disp(num2str(cellIdx))
    end
end

histogram([fullCellDataMod.confidence], 'BinWidth', 0.01);

disp('Saving images...');
for imgIdx = 1:length(subDirs)
    sumImg = cat(3, summaryImages{imgIdx}(:,:,1), summaryImages{imgIdx}(:,:,2), im2uint8(loadedFrames{imgIdx, 3}(:,:,1)));
    saveToFolder(cellDir, sumImg, num2str(imgIdx - 1));
end

function [fakeImg, cellImg] = fillScore(cellData, fakeImg, cellImg)
    if cellData.confidence >= 0.5
        cellImg = 255 * uint8(imfill(imbinarize(cellImg(:,:,1)), double(cellData.outline(1,:))) - imbinarize(cellImg(:,:,1)));
    else
        fakeImg = 255 * uint8(imfill(imbinarize(fakeImg(:,:,1)), double(cellData.outline(1,:))) - imbinarize(fakeImg(:,:,1)));
    end
end

function saveToFolder(location, images, imgID)
    subFolder = "Confidence/";
    if ~exist(location + subFolder, 'dir')
        mkdir(location + subFolder);
    end
    imwrite(images, location + subFolder + imgID + ".tif");
end

function weight = getWeight(binary, score)
    if binary == 1
        weight = 1;
    else
        weight = 1.8 * abs(score - 0.5) + 0.2;
    end
end
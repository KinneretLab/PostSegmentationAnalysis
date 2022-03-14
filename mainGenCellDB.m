clear all; close all;
addpath(genpath('\\phhydra\data-new\phkinnerets\home\lab\CODE\Hydra\'));
addpath(genpath('\\phhydra\phhydraB\Analysis\users\Projects\Noam'));

mainDir='Z:\Analysis\users\Projects\Noam\Workshop\\timepoints'; % Main directory for movie you are analysing.
cellDir = [mainDir,'\Cells\']; % Cell directory for movie (this is our normal folder structure and should stay consistent).
segDir = [cellDir,'Inference\2021_10_12_CEE3_CEE5_CEE1E_CEE1E_CEE6']; % Segmentation folder.

training = false;

cd(cellDir);
load('fullCellData');
load('fullVertexData');

subDirs = dir(segDir);
subDirs = subDirs([subDirs.isdir] & ~strcmp({subDirs.name},'.') & ~strcmp({subDirs.name},'..'));
subDirNames = natsortfiles({subDirs.name});

% load all frames into memory
loadedFrames = cell(length(subDirs), 3 + training);
disp('loading frames...');
for i = 1:length(subDirNames)
    dirName = subDirNames{i};
    % get all the images
    loadedFrames{i, 1} = imread(fullfile(segDir, dirName, 'handCorrection.tif'));
    loadedFrames{i, 2} = imread(fullfile(segDir, dirName + ".tif"));
    loadedFrames{i, 3} = imread(fullfile(cellDir, 'Raw Cortices', dirName + ".tiff"));
    if training
        loadedFrames{i, 4} = imread(fullfile(segDir, dirName, 'groundTruth.tif'));
    end
end

lenImages = size(loadedFrames, 2);
cropped = cell(1, lenImages);

statIdx = ones(3, 1);
stat = cell(3, 1);
summaryImages = loadedFrames(:,1);
disp('Creating composites & categorizing...');
for cellIdx = 1:length(fullCellData)
    cellData = fullCellData(cellIdx);
    % iterate over each cell in the data to get its dimensions by min/max x/y coords or vertices
    images = loadedFrames(str2num(cellData.frame) + 1, :);

    if training
        [status, pixelDiff, maskedRaw] = compareImages(cellData, images{1}, images{4});
    end

    crop = getCrop(cellData.outline, 2);
    for i = 1:lenImages
        cropped{i} = imcrop(images{i}, crop);
    end

    if training
        if ismember(status, [3]) % 0 is cell, 1 is fake, 2 is ????, 3 is ignore.
            status = displayImageDiff(cropped{1}, cropped{4}, status, pixelDiff);
        end

        saveToFolder(cellDir, cropped, status, cellData.uniqueID);
        summaryImages{str2num(cellData.frame) + 1}(:,:,statusToChannel(status)) = summaryImages{str2num(cellData.frame) + 1}(:,:,statusToChannel(status)) + uint8(maskedRaw * 255);

        stat{status + 1}(statIdx(status + 1)) = pixelDiff;
        statIdx(status + 1) = statIdx(status + 1) + 1;
    else
        saveToFolder(cellDir, cropped, 0, cellData.uniqueID);
    end

    if rem(cellIdx, 1000) == 0
        disp(num2str(cellIdx))
    end
end

if training
    for k = 1:3; stat{k}(stat{k} > 500) = -3; end
    histogram(stat{1}, 'BinWidth', 10);
    hold on
    histogram(stat{2}, 'BinWidth', 10);
    histogram(stat{3}, 'BinWidth', 10);
    hold off

    disp('Creating summary images...');
    for imgIdx = 1:length(subDirs)
        sumImg{1} = cat(3, loadedFrames{imgIdx,1}(:,:,1), loadedFrames{imgIdx,4}(:,:,1), loadedFrames{imgIdx,2}(:,:,1));
        sumImg{2} = summaryImages{imgIdx};
        rawImg = im2uint8(loadedFrames{imgIdx,3});
        sumImg{3} = cat(3,rawImg,rawImg,rawImg);
        savable = [sumImg{:}];
        saveToFolder(cellDir, {savable(:,:,1), savable(:,:,2), savable(:,:,3)},-1, subDirNames(imgIdx));
    end
end

function crop = getCrop(outline, buffer)
    minPos = flip(min(outline));
    maxPos = flip(max(outline));
    crop = [minPos - 1 - buffer maxPos - minPos + 2 + 2 * buffer];
end

function pixels = pixelSum(img, crop)
    fullRGB = sum(sum(imcrop(img, crop))) / 255;
    pixels = fullRGB(1);
end

function trueStatus = displayImageDiff(autoImg, trueImg, status, pixelDiff)
    images = {imresize(autoImg,5,'nearest'), imresize(trueImg,5,'nearest')};
    statStr = "";
    diffStr = "";
    switch status
        case 0
            statStr = "cell";
        case 1
            statStr = "FAKE";
        case 2
            statStr = "????";
        otherwise
            statStr = "Error Status obtained.";
    end
    if pixelDiff == -2
        diffStr = "(auto too concave)";
    elseif pixelDiff == -1
        diffStr = "(hit central true edge)";
    else
        diffStr = "(" + num2str(pixelDiff) + ")";
    end
    trueStatus = makeUI(statStr + " " + diffStr, images);
end

function retStatus = makeUI(msgStr, images)
    % basic figure
    f = figure('Name', 'Cell Preview', 'NumberTitle','off');
    imshowpair(images{1}, images{2});
    title(msgStr);

    % button controls
    status1 = uicontrol('Style', 'pushbutton', 'String', 'cell', 'Callback', @(src, event)setStatus(0));
    status3 = uicontrol('Style', 'pushbutton', 'String', 'not sure', 'Callback', @(src, event)setStatus(2));
    status3.Position = status1.Position + [70 0 0 0];
    status2 = uicontrol('Style', 'pushbutton', 'String', 'fake', 'Callback', @(src, event)setStatus(1));
    status2.Position = status1.Position + [140 0 0 0];

    % callback & halting
    uiwait(f)
    function setStatus(status)
        retStatus = status;
        uiresume(f)
    end
    close(f)
end

function [status, pixelDiff, maskedRaw] = compareImages(cellData, rawImg, trueImg)
    center = [floor(cellData.centre_y) floor(cellData.centre_x)];

    % calculate raw mask, requires for output anyways, via subtraction
    maskedRaw = imfill(im2bw(rawImg), cellData.outline(1, :)) - im2bw(rawImg);

    % make sure the center is inside the cell, otherwise return error code (too concave).
    [in, on] = inpolygon(center(2), center(1), cellData.outline(:, 2), cellData.outline(:, 1));
    if ~in || on
        status = 1;
        pixelDiff = -2;
        return;
    end
    % attempt to get the refined cell area marked.
    % make sure the area being filled is inside any ground truth cell, other return error code (hit central edge)
    if trueImg(center(1), center(2)) > 0
        status = 1;
        pixelDiff = -1;
        return;
    end
    % calculate pixel image of the images via subtraction
    maskedTrue = imfill(im2bw(trueImg), center) - imbinarize(trueImg);

    % calculate difference
    pixelDiff = abs(sum(sum(maskedRaw)) - sum(sum(maskedTrue)));
    pixelDiff = pixelDiff(1);
    if pixelDiff < 100
        status = 0;
    elseif pixelDiff > 200
        status = 1;
    else
        status = 2;
    end
end

function saveToFolder(location, images, status, imgID)
    combinedImage = cat(3, images{1}(:,:,1), images{2}(:,:,1), im2uint8(images{3}));
    subFolder = "";
    switch status
        case -1
            subFolder = "CellDB/summaries/";
        case 0
            subFolder = "CellDB/cells/";
        case 1
            subFolder = "CellDB/fakes/";
        otherwise
            subFolder = "CellDB/unclassified/";
    end
    if ~exist(location + subFolder, 'dir')
        mkdir(location + subFolder);
    end
    imwrite(combinedImage, location + subFolder + imgID + ".tif");
end

function channel = statusToChannel(status)
    switch status
        case 0
            channel = 2;
        case 1
            channel = 1;
        otherwise
            channel = 3;
    end
end
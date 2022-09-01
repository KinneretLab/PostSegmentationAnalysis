addpath('classDefinitions');
% generic global search for a particular folder; works independent of user
search_path = '../*/natsortfiles';
while isempty(dir(search_path))
    search_path = ['../', search_path];
end
addpath(dir(search_path).folder)

mainDir='Z:\Analysis\users\Liora\Movie_Analysis\2021_07_26\2021_07_26_pos2'; % Main directory for movie you are analysing.
cellDir = [mainDir,'\Cells\']; % Cell directory for movie (this is our normal folder structure and should stay consistent).
segDir = [cellDir,'Inference\2022_07_01_CEE3_CEE5_CEE1E_CEE1E_CEE6']; % Segmentation folder.

% various visual configurations for the result images
isBinary = true; % whether binary score images should be saved or a more continuous variant with a variable color.
darken = false; % whether the cell coloring should be darked overall so the raw image can be more visible
erodeCells = true; % whether there should be a buffer space between the indicators of each cell
showBorders = true; % whether the automatic segmentatio borders should be shown (in yellow)
rawInWhite = true; % show the raw image in white instead of blue (channel-wise)

fullCellData = Experiment.load(cellDir).cells;

subDirs = dir(segDir);
subDirs = subDirs([subDirs.isdir] & ~strcmp({subDirs.name},'.') & ~strcmp({subDirs.name},'..'));
subDirNames = natsortfiles({subDirs.name});

% load all frames into memory
if ~exist('loadedFrames', 'var')
    loadedFrames = cell(length(subDirs), 2);
    disp('loading frames...');
    for i = 1:length(subDirNames)
        dirName = subDirNames{i};
        % get all the images
        wireframe = imread(fullfile(segDir, dirName, 'handCorrection.tif'));
        loadedFrames{i, 1} = wireframe(:, :, 1);
        loadedFrames{i, 2} = imread(fullfile(cellDir, 'Raw Cortices', dirName + ".tiff"));
        if mod(i, 50) == 0
            fprintf("%d/%d images done\n", i, length(subDirNames));
        end
    end
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
    images = loadedFrames(cellData.frame, :);

    [fakeImg, cellImg] = fillScore(cellData, images{1});
    summaryImages{cellData.frame} = summaryImages{cellData.frame} + ...
       getWeight(isBinary, cellData.confidence, darken) * 255 * cat(3, tryErode(fakeImg, erodeCells), ...
       tryErode(cellImg, erodeCells), zeros(imgSize));

    if rem(cellIdx, 1000) == 0
        disp(num2str(cellIdx))
    end
end

histogram([fullCellData.confidence], 'BinWidth', 0.01);

disp('Saving images...');
for imgIdx = 1:length(subDirs)
    if rawInWhite
        sumImg = cat(3, summaryImages{imgIdx}(:,:,1), summaryImages{imgIdx}(:,:,2), zeros(imgSize)) + im2uint8(loadedFrames{imgIdx, 2});
    else
        sumImg = cat(3, summaryImages{imgIdx}(:,:,1), summaryImages{imgIdx}(:,:,2), im2uint8(loadedFrames{imgIdx, 2}(:,:,1)));
    end
    saveToFolder(cellDir, sumImg, subDirNames(imgIdx));
end

function [fakeImg, cellImg] = fillScore(cellData, segImg)
    outline = cellData.outline.outline_; % indexes outline
    rawMask = uint8(zeros(size(segImg)));
    for i=1:size(outline, 1)
        rawMask(outline(i,1), outline(i,2)) = 1;
    end
    rawMask = 255 * uint8(imfill(rawMask, 'holes'));
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
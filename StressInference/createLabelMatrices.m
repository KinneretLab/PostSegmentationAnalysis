function [L] = createLabelMatrices(segDir)
% The function creates the label matrices from the segmented images
% according to the requirements for the VMSI pipeline. Segmentation images
% are first expanded using a gaussian blur with sigma=1, and then run with
% matlab's watershed function to get a skeleton with 4-connectivity (rather
% than the original 8). The resulting label matrices are saved as a 3-dim
% matrix of all timepoints.

% Get number of frames from Tissue Miner DBs.
cd(segDir); frames = dir('*.tif*');
L=[];
for k = 1:length(frames)
    thisFile = frames(k).name;
    endName=strfind(thisFile,'.');
    fName = thisFile (1:endName-1); %without the .filetype
    frameDir = [segDir,'\',fName];
    cd(frameDir);
    
    thisIm=importdata('handCorrection.tif');
    thisImGray = rgb2gray(thisIm);
    
    thisImFilt = imgaussfilt(thisImGray,0.4);
    thisImWS = watershed(thisImFilt);

    L(:,:,k) = thisImWS;

end

end


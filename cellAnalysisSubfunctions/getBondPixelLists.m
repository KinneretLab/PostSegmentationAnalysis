function [allBondPixels,allBond3DPixels,allBondIDs,allBondFrames] = getBondPixelLists(fullBondData)
% This function returns two vectors of the length of all pixels of all
% bonds in the dataset, and a matching list of the correct bond_id per
% pixel

allBondPixels = cat(1,fullBondData.coords);
allBond3DPixels = cat(1,fullBondData.smooth3Dcoords);
allBondIDs = [];
allBondFrames = [];
for i = 1:length(fullBondData)
    len = size(fullBondData(i).coords,1);
    thisID = fullBondData(i).bond_id;
    thisFrame = fullBondData(i).frame;
    allBondIDs = [allBondIDs;double(thisID).*ones(len,1)];
    allBondFrames = [allBondFrames; thisFrame.*ones(len,1)];

end

end


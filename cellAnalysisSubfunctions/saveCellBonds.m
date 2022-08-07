function [thisBondData] = saveCellBonds(thisCellData,thisBondData,thisDBondData,thisCell,backProj,verts)
% This function takes the smoothed outline of the cell, and the incdices of
% bonds and vertices within the outline, and saves the smoothed bond
% coordinates to the bond database.

dBonds = thisCellData(thisCell).dBonds;
vertInds = find(verts);
for i=1:length(dBonds)
    dBondInd = ([thisDBondData.dbond_id] == dBonds(i));
    thisBond = thisDBondData(dBondInd).bond;
    orderedVerts = thisDBondData(dBondInd).ordered_vertices;
    if ~isempty(vertInds)
        newFullCoords = backProj((vertInds(i)):(vertInds(i+1)),:);
        newCoords = newFullCoords(2:(end-1),:);
        if ~isempty(thisBond) 
            bondInd = ([thisBondData.bond_id] == thisBond);
            if length(thisBondData(bondInd).vertices)>1
                flipBond = (orderedVerts == fliplr(thisBondData(bondInd).vertices(1:2)));
                if flipBond == 1
                    newCoords = flipud(newCoords);
                end
            end
            thisBondData(bondInd).smooth3Dcoords = newCoords;
            steps = [newFullCoords(2:end,:)-newFullCoords(1:(end-1),:)];
            dist = sum(sqrt(sum(steps.^2,2)));
            thisBondData(bondInd).length = dist;
        end
    else
        newCoords = backProj;
        if ~isempty(thisBond)
            bondInd = ([thisBondData.bond_id] == thisBond);
            thisBondData(bondInd).smooth3Dcoords = newCoords;
            steps = [newCoords(2:end,:)-newCoords(1:(end-1),:)];
            dist = sum(sqrt(sum(steps.^2,2)));
            thisBondData(bondInd).length = dist;
        end
    end
    
end

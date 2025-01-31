 function [outline,bonds,verts] = findCellOutline(thisCellData,thisVertexData,thisBondData,thisDBondData,thisCell)
% This function finds the outline of a given cell defined by it's bonds and
% vertices in correct order. It also returns the indices in the outline
% belonging to the bonds and vertices.

outline = [];
bonds = [];
verts = [];
dBonds = thisCellData(thisCell).dBonds;
for i=1:length(dBonds)
    coords =[];
    dBondInd = ([thisDBondData.dbond_id] == dBonds(i));
    thisBond = thisDBondData(dBondInd).bond;
    orderedVerts = thisDBondData(dBondInd).ordered_vertices;
    if ~isempty(thisBond)
        bondInd = ([thisBondData.bond_id] == thisBond);
    end
    
    if isnan(orderedVerts)
        coords = thisBondData([thisBondData.bond_id] == thisBond).coords;
        outline = [outline; coords];
    else
        vert1Ind = ([thisVertexData.vertex_id]== orderedVerts(1));
        vert2Ind = ([thisVertexData.vertex_id]== orderedVerts(2));
        vert1Coords = [thisVertexData(vert1Ind).x_pos,thisVertexData(vert1Ind).y_pos];
        vert2Coords = [thisVertexData(vert2Ind).x_pos,thisVertexData(vert2Ind).y_pos];
        if ~isempty(thisBond)
            if length(thisBondData(bondInd).vertices)==1
                coords = thisBondData(bondInd).coords;
            else
                flipBond = (orderedVerts == fliplr(thisBondData(bondInd).vertices(1:2)));
                coords = thisBondData(bondInd).coords;
                if flipBond == 1
                    coords = flipud(coords);
                end
            end
        end
        if i==1
            outline = [outline; vert1Coords; coords; vert2Coords];
            verts = [verts,1,zeros(1,size(coords,1)),1];
            bonds = [bonds,0,ones(1,size(coords,1)),0];
            
        else
            outline = [outline; coords; vert2Coords] ;
            verts = [verts,zeros(1,size(coords,1)),1];
            bonds = [bonds,ones(1,size(coords,1)),0];
            
        end
    end
end


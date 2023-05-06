function [] = extractCellDataTMformat(segDir, maskDir,frameList,rawDatasetsDir)
% This function loads final segmentation mask, vertex image, and bond image
% outputs of tissue analyzer, and saves the information a set of tables:
% directed_bonds, bonds, cells, vertices, frames. The directed_bonds table holds only relations, the other tables hold data. 
% All data that is flexible in dimenstions is saved in separate matlab structures
% called "fullCellData" and "fullVertexData".

% Get list of filenames and frames to run over:
files = dir(segDir);
folders = files([files.isdir]);
sortedFolderNames = natsortfiles({folders.name});
index = cellfun(@(x) x(1)~= '.', sortedFolderNames , 'UniformOutput',1);
sortedFolderNames = sortedFolderNames(index);


if isempty(frameList)
    frames = 1:length(sortedFolderNames);
else
    frames = frameList;
end

% Run over all prescribed frames:

 for k = frames
  %  try
    thisFolder = sortedFolderNames{k};
    cd([segDir,'\',thisFolder]);
    
    thisIm = importdata('handCorrection.tif');
    vertexIm = importdata('vertices.tif');
    bondsIm = importdata('boundaryPlotter.tif');
    
    cd(maskDir);
    try
        thisMaskBW = imbinarize(imread([thisFolder,'.tiff']));
    catch
        thisMaskBW = imbinarize(imread([thisFolder,'.tif']));
    end
    
    % Dilate mask a bit so complete cell outlines don't get cut off. This
    % is relevant only for hand corrected segmentations.
    SE = strel("disk",15);
    thisMaskBW = imdilate(thisMaskBW,SE);
    
    if size(thisIm,3)>1
        thisImGray = rgb2gray(thisIm);
    else
        thisImGray = thisIm;
    end

    thisImGray(1,:) = 0; thisImGray(end,:) = 0; thisImGray(:,1) = 0; thisImGray(:,end) = 0;
    thisImBW = imbinarize(thisImGray);
    thisImBW = thisImBW.*thisMaskBW;
    thisImWB = imcomplement(thisImBW);
    
    CC = bwconncomp(thisImWB,4);
    B = bwboundaries(thisImWB,4);
    L = labelmatrix(CC);
    stats = regionprops(CC);
    RGB = label2rgb(L,'jet','k','shuffle');
    background = find([stats.Area]==max([stats.Area])); % This can possibly be changed so that if there is no background, or multiple background regions, we will be able to work with it. At the moment, there is always a frame of one pixel that is black at the edge of the image, so this can function as the background.
    
    % Initialize structures:
    frameCellData = struct();
    frameVertexData = struct();
    
    for i = 1:length(stats)
        if i~=background
            shift = (i>background);
            % Fill data for this cell into struct
            frameCellData(i-shift).frame = k;
            frameCellData(i-shift).centre_x = stats(i).Centroid(1);
            frameCellData(i-shift).centre_y = stats(i).Centroid(2);
            [thisX,thisY] = ind2sub(size(L),CC.PixelIdxList{1,i}(round(length(CC.PixelIdxList{1,i})/2)));
            cellLabel = L(thisX,thisY);
            cellLabelC =  L( round(frameCellData(i-shift).centre_y),round(frameCellData(i-shift).centre_x));
            if (cellLabel == cellLabelC)
                frameCellData(i-shift).isConvex = 1;
            else
                frameCellData(i-shift).isConvex = 0;
            end
            frameCellData(i-shift).outline = fliplr(B{cellLabel});
            frameCellData(i-shift).cell_id = uniqueID(k,cellLabel);
            frameCellData(i-shift).vertices = [];
            frameCellData(i-shift).bonds = [];
            frameCellData(i-shift).ordered_vertices = [];
            frameCellData(i-shift).dBonds = [];
            frameCellData(i-shift).isEdge = 0;

        end
    end
    
    % Get bonds
    frameBondData = struct();
    frame_dBonds = struct();
    bCount = 0;
    rImage = bondsIm(:,:,1).*uint8(thisMaskBW);
    gImage = bondsIm(:,:,2).*uint8(thisMaskBW); 
    bImage = bondsIm(:,:,3).*uint8(thisMaskBW);
    
    bvalsR = unique(rImage);
    bvalsG = unique(gImage); 
    bvalsB = unique(bImage);
    
    for iR = 1:length(bvalsR)
        for iG = 1:length(bvalsG)
            for iB = 1:length(bvalsB)
                if ~((bvalsB(iB)+bvalsG(iG)+bvalsR(iR)) ==0 || ((bvalsR(iR) == max(bvalsR))&&(bvalsG(iG) == max(bvalsG))&&(bvalsB(iB)==max(bvalsB))))
                    sumIm = (rImage == bvalsR(iR))+ (gImage == bvalsG(iG))+ (bImage == bvalsB(iB));
                    [thisBy,thisBx] = find(sumIm==3);
                    if thisBx ~= 0
                        bCount = bCount+1;
                        frameBondData(bCount).RGBvals = [bvalsR(iR),bvalsG(iG),bvalsB(iB)];
                        frameBondData(bCount).coords = [thisBx,thisBy];
                        frameBondData(bCount).frame = k;
                        frameBondData(bCount).bond_id = uniqueID(k,bCount);
                        frameBondData(bCount).vertices = [];
                        frameBondData(bCount).cells = [];
                        
                    end
                end
            end
        end
    end
    
    % Get vertices
    
    if size(vertexIm,3)>1
        vertexImGray = rgb2gray(vertexIm);
    else
        vertexImGray = vertexIm;
    end
    vertexImBW = imbinarize(vertexImGray);
    vertexImBW = vertexImBW.*thisMaskBW;
    
    [v_y,v_x]=find(vertexImBW);
    % Initiate struct for saving adjacent vertex pairs for creating bonds
    % between these vertices:
    adj_pairs = struct(); adj_count = 0;

    for j=1:length(v_x)
        Lvals = unique(L((v_y(j)-1):(v_y(j)+1),(v_x(j)-1):(v_x(j)+1)));
        Lvals = Lvals(Lvals>0);
        frameVertexData(j).isEdge = length(find(Lvals==background));
        Lvals = Lvals(Lvals~=background);
        frameVertexData(j).frame = k;
        frameVertexData(j).x_pos = v_x(j);
        frameVertexData(j).y_pos = v_y(j);
        frameVertexData(j).vertex_id = uniqueID(k,j);
        % Assign cells to vertices
        cIndex =[];
        idList = [];
        for l = 1:length(Lvals)
            cellID = uniqueID(k,Lvals(l));
            idList(l) = cellID ;
            cIndex(l) = find([frameCellData.cell_id]== cellID);
        end
        frameVertexData(j).cells = idList;
        % Assign vertices back to cells
        for m=1:length(cIndex)
            frameCellData(cIndex(m)).vertices = unique([frameCellData(cIndex(m)).vertices,frameVertexData(j).vertex_id]);
            if frameVertexData(j).isEdge > 0
                frameCellData(cIndex(m)).isEdge = 1;         
            end
        end

        % Assign neighbouring bonds to vertex
        VxInds = (v_x(j)-1):(v_x(j)+1);
        VyInds = (v_y(j)-1):(v_y(j)+1);
        VBvals = bondsIm(VyInds,VxInds,:);
        VBvalsList = reshape(VBvals,9,3);
        origVBvalsList = VBvalsList;
        % Find adjacent vertices
        VVvals = vertexImBW((v_y(j)-1):(v_y(j)+1),(v_x(j)-1):(v_x(j)+1));
        adjacentVerts = setdiff(find(VVvals),5);
        if ~isempty(adjacentVerts)
            for a = 1:length(adjacentVerts)
                adj_count = adj_count+1;
                [ay,ax] = ind2sub([3,3],adjacentVerts(a));
                newVx = VxInds(ax);
                newVy = VyInds(ay);
                % Need to check for every pair which vertex of the two is
                % the closer one to each bond, and match them accordingly.
                % 
                newVxInds = (newVx-1):(newVx+1);
                newVyInds = (newVy-1):(newVy+1);
                newVBvals = bondsIm(newVyInds,newVxInds,:);
                newVBvalsList = reshape(newVBvals,9,3);
                jointVBvals = intersect(origVBvalsList,newVBvalsList,'rows');
                jointVBvals = setdiff(jointVBvals,[0,0,0],'rows');
                jointVBvals = setdiff(jointVBvals,[255,255,255],'rows');
                [~, vert1index]=ismember(jointVBvals,origVBvalsList,'rows');
                for jv = 1:size(jointVBvals,1)
                    [bIndY,bIndX] = ind2sub([3,3],vert1index(jv));
                    bCoordX = VxInds(bIndX); 
                    bCoordY = VyInds(bIndY);
                    dist1 = sqrt((v_x(j)-bCoordX)^2+(v_y(j)-bCoordY)^2);
                    dist2 = sqrt((newVx-bCoordX)^2+(newVy-bCoordY)^2);
                    if dist2<dist1
                        VBvalsList = VBvalsList(~ismember(VBvalsList, jointVBvals(jv,:), 'rows'),:);
                    end
                end
                 VBvalsList = unique(VBvalsList,'rows');
                adj_pairs(adj_count).vertex1_coords = [v_x(j),v_y(j)];
                adj_pairs(adj_count).vertex2_coords = [newVx,newVy];
            end
        end
        bNums=[];
        for p = 1:size(VBvalsList,1)
            thisBNum = find(cellfun(@(x)isequal(x,VBvalsList(p,:)),{frameBondData.RGBvals}));
            if ~isempty(thisBNum)
                bID = frameBondData(thisBNum).bond_id;
                bNums(p) = bID;
            end
        end
        bNums = unique(bNums); bNums = bNums(bNums~=0);
        frameVertexData(j).bonds = bNums; 
        for q=1:length(bNums)
            thisInd = find([frameBondData.bond_id]== bNums(q));
            frameBondData(thisInd).vertices = [frameBondData(thisInd).vertices,frameVertexData(j).vertex_id];
        end
        
    end
    
    % Connect bonds and cells:
    
    for r = 1:length(frameBondData)
        [ref_point] = fliplr(frameBondData(r).coords(round(length(frameBondData(r).coords)/2),:));
        Lvals_b = unique(L((ref_point(1)-1):(ref_point(1)+1),(ref_point(2)-1):(ref_point(2)+1)));
        Lvals_b = Lvals_b(Lvals_b>0);
        Lvals_b = Lvals_b(Lvals_b~=background);
        idList = [];
        cIndex =[];
        for l = 1:length(Lvals_b)
             cellID = uniqueID(k,Lvals_b(l));
            idList(l) = cellID ;
            cIndex(l) = find([frameCellData.cell_id]== cellID);
        end
        frameBondData(r).cells = idList;
        % Make sure bond vertices are connected to these cells:
        bond_Verts =  frameBondData(r).vertices;
        for bv = 1:length(bond_Verts)
            bv_ind = [frameVertexData.vertex_id] == bond_Verts(bv);
            frameVertexData(bv_ind).cells = unique([frameVertexData(bv_ind).cells,idList]);
        end
        for c = 1:length(cIndex)
            frameCellData(cIndex(c)).bonds = unique([frameCellData(cIndex(c)).bonds,frameBondData(r).bond_id]);
            frameCellData(cIndex(c)).vertices = unique([frameCellData(cIndex(c)).vertices, bond_Verts]);
        end
    end
    
    % Correctly order bond pixels along line starting from first listed
    % vertex
    imSize = size(thisMaskBW);
    for r = 1:length(frameBondData)
        ordered_list_sub=[];
        thisBondVerts = frameBondData(r).vertices;
        if ~isempty(thisBondVerts) % Cases where cells are connected to other cells
            thisVertInd = find([frameVertexData.vertex_id]== thisBondVerts(1));
            vertX = frameVertexData(thisVertInd).x_pos;
            vertY = frameVertexData(thisVertInd).y_pos;
        else % Case where cell is not touching any other neighbouring cells
            vertX = frameBondData(r).coords(1,1);
            vertY = frameBondData(r).coords(1,2);
            frameBondData(r).vertices = NaN;
        end
        thisBondIm = zeros(imSize);
        thisBondIm(vertX,vertY) = 1;
        thisBondIm(sub2ind(imSize,frameBondData(r).coords(:,1),frameBondData(r).coords(:,2)))=1;
        mat_dist = bwdistgeodesic(imbinarize(thisBondIm),vertY,vertX,'quasi-euclidean'); %'quasi-euclidean' for 8-connectivity
        comp = find(thisBondIm);
        comp(:,2) = mat_dist(comp(:,1));
        ordered_list_ind = sortrows(comp,2);
        [ordered_list_sub(:,1), ordered_list_sub(:,2)] = ind2sub(size(thisBondIm),ordered_list_ind(:,1));
        frameBondData(r).coords =  ordered_list_sub(2:end,:);
    end
    
        
     % Create bond between pairs of adjacent  vertices
     if adj_count>0
         for pairs = 1:length(adj_pairs)
             vertIndX1 = find([frameVertexData.x_pos]== adj_pairs(pairs).vertex1_coords(1));
             vertIndY1 = find([frameVertexData.y_pos]== adj_pairs(pairs).vertex1_coords(2));
             vertInd1 = intersect(vertIndX1,vertIndY1);
             
             vertIndX2 = find([frameVertexData.x_pos]== adj_pairs(pairs).vertex2_coords(1));
             vertIndY2 = find([frameVertexData.y_pos]== adj_pairs(pairs).vertex2_coords(2));
             vertInd2 = intersect(vertIndX2,vertIndY2);
             
             theseVerts = [frameVertexData(vertInd1).vertex_id,frameVertexData(vertInd2).vertex_id];
             % Check if a bond already exists for this pair:
             bondCheck = cellfun(@(x)ismember(theseVerts,x),{frameBondData.vertices},'UniformOutput',false);
             bondCheckTotal = find(cellfun(@sum,bondCheck)==2);
             if isempty(bondCheckTotal)
                 % If not, create the bond:
                 newBondFrameIndex = length(frameBondData);
                 newBondID = uniqueID(k,newBondFrameIndex+1);
                 frameBondData(newBondFrameIndex+1).frame = k;
                 frameBondData(newBondFrameIndex+1).coords = []; % No pixels between the two vertices
                 frameBondData(newBondFrameIndex+1).bond_id = newBondID;
                 frameBondData(newBondFrameIndex+1).RGBvals = [];
                 frameBondData(newBondFrameIndex+1).vertices = [frameVertexData(vertInd1).vertex_id,frameVertexData(vertInd2).vertex_id];
                 frameVertexData(vertInd1).bonds = [ frameVertexData(vertInd1).bonds,newBondID];
                 frameVertexData(vertInd2).bonds = [ frameVertexData(vertInd2).bonds,newBondID];
                 
             end
         end
     end
    
    % Create directed bonds table
    dBond_count = 0;
    for s = 1:length(frameCellData)
        if (isempty(frameCellData(s).vertices)&& length(frameCellData(s).bonds) == 1) % Case of detached cell with one bond
            this_dBond = struct();
            dBond_count = dBond_count+1;
            this_dBond.dbond_id = uniqueID(k,dBond_count);
            this_dBond.ordered_vertices = [nan,nan];
            this_dBond.cell = frameCellData(s).cell_id;
            this_dBond.bond = frameCellData(s).bonds;
            this_dBond.frame = k;
            this_dBond.next_dBond = this_dBond.dbond_id;
            
            frameCellData(s).dBonds = unique([frameCellData(s).dBonds,this_dBond.dbond_id]);
            frameCellData(s).isEdge = 1;
            
            if isempty(fieldnames(frame_dBonds)) % Set fields for first entry in frame_dBonds
                frame_dBonds = this_dBond;
            else
                frame_dBonds = [frame_dBonds,this_dBond];
            end
            
        else if ~isempty(frameCellData(s).vertices)
                verts = frameCellData(s).vertices;
                if or(length(verts)== 2 ,length(verts)== 1)
                    ordered_verts = verts;
                else
                    % Choose the first vertex in the list as the starting
                    % point, find and choose one of it's neighbouring
                    % vertices, and continue around the cell. At the end,
                    % check if order is clockwise or anti-clockwise and
                    % correct so all are clockwise (which corresponds to
                    % anti-clockwise in the image that is read top to bottom).
                    ordered_verts = [];
                    ordered_verts(1) = verts(1);
                    vertBondInds = logical(cell2mat(cellfun(@(x)ismember(ordered_verts(1),x),{frameBondData.vertices},'UniformOutput',false)));
                    bond_verts = [frameBondData(vertBondInds).vertices];
                    bond_verts = intersect(bond_verts,verts);
                    bond_verts = setdiff(bond_verts,ordered_verts(1));
                    % Choose one of the adjacent vertices (without knowing
                    % if clockwise or not)
                    ordered_verts(2) = bond_verts(1);
                    % Fill in the next ordered vertices based on the remaining
                    % vertices shared by the relevant bonds:
                    for vi = 2:(length(verts)-1)
                        vertBondInds = logical(cell2mat(cellfun(@(x)ismember(ordered_verts(vi),x),{frameBondData.vertices},'UniformOutput',false)));
                        bond_verts = [frameBondData(vertBondInds).vertices];
                        bond_verts = intersect(bond_verts,verts); bond_verts = setdiff(bond_verts,ordered_verts); 
                        if length(bond_verts)==2 % Case that happens when there are segmented cells missing 
                            findBs1 = cellfun(@(x)ismember([bond_verts(1),ordered_verts(vi)],x),{frameBondData.vertices},'UniformOutput',false);
                            findBs2 = cellfun(@(x)ismember([bond_verts(2),ordered_verts(vi)],x),{frameBondData.vertices},'UniformOutput',false);
                            v1check = ismember(frameCellData(s).cell_id,frameBondData(cellfun(@sum,findBs1)==2).cells);
                            v2check = ismember(frameCellData(s).cell_id,frameBondData(cellfun(@sum,findBs2)==2).cells);
                            bond_verts = bond_verts([v1check,v2check]);
                        end
                        ordered_verts(vi+1) = bond_verts;
                    end
                    x = [];
                    y = [];
                    for vi=1:length(ordered_verts)
                        x(vi) = frameVertexData([frameVertexData.vertex_id] == ordered_verts(vi)).x_pos;
                        y(vi) = frameVertexData([frameVertexData.vertex_id] == ordered_verts(vi)).y_pos;
                    end
                    tf = ispolycw(x,y);
                    if ~tf
                        ordered_verts(2:end) = fliplr(ordered_verts(2:end));
                    end
                end

                frameCellData(s).ordered_vertices = ordered_verts;
                ordered_verts = [ordered_verts,ordered_verts(1)];
                last_dB_count = dBond_count;
                for vj = 1:length(ordered_verts)-1
                    theseVs = [ordered_verts(vj),ordered_verts(vj+1)];
                    findBs = cellfun(@(x)ismember(theseVs,x),{frameBondData.vertices},'UniformOutput',false);
                    dbond_bnum = find(cellfun(@sum,findBs)==2);
                    dbond_bID = [frameBondData(dbond_bnum).bond_id];
                    for ii = 1:length(dbond_bnum)
                        % Make sure bonds have all cells that belong to them
                        frameBondData(dbond_bnum(ii)).cells = unique([frameBondData(dbond_bnum(ii)).cells,frameCellData(s).cell_id]);
                    end

                    % Directed bonds
                    this_dBond = struct();
                    dBond_count = dBond_count+1;
                    this_dBond.dbond_id = uniqueID(k,dBond_count);
                    this_dBond.ordered_vertices = [ordered_verts(vj),ordered_verts(vj+1)];
                    this_dBond.cell = frameCellData(s).cell_id;
                    this_dBond.bond = dbond_bID;
                    this_dBond.frame = k;
                    if vj == length(ordered_verts)-1
                        this_dBond.next_dBond = uniqueID(k, last_dB_count + 1);
                    else
                        this_dBond.next_dBond = uniqueID(k, dBond_count + 1);
                    end
                    % Resolve case where two bonds are wrongly linked to a
                    % single d_bond and can be ruled out by link to cell:
                    if length(this_dBond.bond)>1
                        db_cell_bonds = frameCellData(s).bonds;
                        bond_flag = ismember(this_dBond.bond,db_cell_bonds);
                        this_dBond.bond = this_dBond.bond(bond_flag);
                    end

                    % Link d_bonds to cells in cell database:
                    frameCellData(s).dBonds = unique([frameCellData(s).dBonds,this_dBond.dbond_id]);
                    
                    if isempty(fieldnames(frame_dBonds)) % Set fields for first entry in frame_dBonds
                        frame_dBonds = this_dBond;
                    else
                        frame_dBonds = [frame_dBonds,this_dBond];
                    end
                end
            end
        end
    end
    
    % Find conjugate d_bonds and resolve cases where cells have just two
    % bonds:
    for t = 1:length(frame_dBonds)
        db_bond = frame_dBonds(t).bond;
        if length(db_bond) == 1
            findConj = find(cellfun(@(x)isequal(x,db_bond),{frame_dBonds.bond}));
            findConj = findConj(findConj~=t);
            if (length(findConj)>1)
                for t1 = 1:length(findConj)
                    db_ordered_vert = frame_dBonds(t).ordered_vertices;
                    conj_ordered_vert = frame_dBonds(findConj(t1)).ordered_vertices;
                    if isequal(db_ordered_vert,fliplr(conj_ordered_vert))
                        frame_dBonds(t).conjugate_dBond = frame_dBonds(findConj(t1)).dbond_id;
                    end
                end
            else
                if ~isempty(findConj)
                    frame_dBonds(t).conjugate_dBond = frame_dBonds(findConj).dbond_id;
                else
                    frame_dBonds(t).conjugate_dBond = NaN;
                end
            end
            
            
        else if length(db_bond) == 2
                for t2 = 1:length(db_bond)
                    findConj = find(cell2mat(cellfun(@(x)ismember(db_bond(t2),x),{frame_dBonds.bond},'UniformOutput',false)));
                    findConj = findConj(findConj~=t);
                    nextDBond_ind =  find([frame_dBonds.dbond_id]== frame_dBonds(t).next_dBond);
                    findConj = findConj(findConj~=nextDBond_ind);
                    
                    if ~isempty(findConj)
                        db_ordered_vert = frame_dBonds(t).ordered_vertices;
                        conj_ordered_vert = frame_dBonds(findConj).ordered_vertices;
                        if isequal(db_ordered_vert,fliplr(conj_ordered_vert))
                            frame_dBonds(t).conjugate_dBond = frame_dBonds(findConj).dbond_id;
                            frame_dBonds(t).bond = db_bond(t2);
                        else
                            frame_dBonds(t).bond = db_bond(db_bond~=db_bond(t2));
                            
                        end
                    else
                        frame_dBonds(t).conjugate_dBond = NaN;
                        
                    end
                end
            end
            
        end

    end
    
  % Save data to folder.
  cd(rawDatasetsDir);
  save([thisFolder,'_CellData'],'frameCellData');
  save([thisFolder,'_VertexData'],'frameVertexData');
  save([thisFolder,'_BondData'],'frameBondData');
  save([thisFolder,'_DBondData'],'frame_dBonds');
  
  disp(['Done with frame ',num2str(k)])
%   %  catch
% 
%         disp(['Skipped frame ',num2str(k)])
% 
%     end
end

end

% x-value from DB needs to be second index in matlab, y-value first index.
% When using imshow will show up as correct X,Y as in DB.





classdef Cell
    properties
        cell_id
        frame
        center_x
        center_y
        center_z
        area
        aspect_ratio
        perimeter
        is_edge
        is_convex
        elong_xx
        elong_yy
        elong_zz
        norm_x
        norm_y
        norm_z
        fibre_orientation
        fibre_localOP
        fibre_coherence
        score
        bb_xStart
        bb_yStart
        bb_xEnd
        bb_yEnd
        DB
    end
    
    methods
        
        function obj = Cell(db,cell_table_row)
            if nargin > 0
                for name = cell_table_row.Properties.VariableNames
                    obj.(name{1}) = cell_table_row{1, name}; %% be careful with variable refactoring
                end
                obj.DB = db;
            end
        end
        
        function dBonds = dBonds(obj)
            thisID = [obj.cell_id];
            dbArray = [obj.DB];
            dbFolderArray = {dbArray.folder_};
            [~,ia,ic] = unique(dbFolderArray);
            dBonds = DBond();
            for i=1:length(ia)
                dBondArray{i} = dbArray(ia(i)).dBonds;
            end
            maxLength = 0;
            flags = [];
            for i=1:length(thisID)
                if mod(i,100) ==0
                    sprintf(['Finding directed bonds for cell # ',num2str(i)]);
                end
                cellIDArray = [dBondArray{ic(i)}.cell_id];
                flags = (cellIDArray == thisID(i));
                thisLength = sum(flags);
                if thisLength > maxLength
                    dBonds(:,(maxLength+1):thisLength) = DBond();
                    maxLength = thisLength;
                end
                dBonds(i,1:thisLength) = dBondArray{ic(i)}(flags);
            end
        end
        
        function frames = frames(obj)
            frameList = [obj.frame];
            dbArray = [obj.DB];
            dbFolderArray = {dbArray.folder_};
            [~,ia,ic] = unique(dbFolderArray);
            for i=1:length(ia)
                frameArray{i,:} = dbArray(ia(i)).frames;
            end
            flags = [];
            frames = Frame();
            for i=1:length(frameList)
                if mod(i,100) ==0
                    sprintf(['Returning frame for cell # ',num2str(i)]);
                end
                frameNumArray = [frameArray{ic(i),:}.frame];
                flags = (frameNumArray == frameList(i));
                frames(i) = frameArray{ic(i)}(flags);
            end
        end
        
        
        function bonds = bonds(obj)
            theseDBonds = dBonds(obj);
            dbArray = [obj.DB];
            dbFolderArray = {dbArray.folder_};
            [~,ia,ic] = unique(dbFolderArray);
            for i=1:length(ia)
                bondArray{i} = dbArray(ia(i)).bonds;
            end
            flags = [];
            for i=1:size(obj,2)
                if mod(i,100) ==0
                    sprintf(['Finding bonds for cell # ',num2str(i)])
                end
                for j=1:length(theseDBonds(i,:))
                    bondIDArray = [bondArray{ic(i)}.bond_id];
                    thisID = theseDBonds(i,j).bond_id;
                    if ~isempty(thisID)
                        flag = (bondIDArray == thisID);
                        bonds(i,j) = bondArray{ic(i)}(flag);
                    else
                        bonds(i,j) = Bond();
                    end
                end
            end

        end
        
        function vertices = vertices(obj)
            theseDBonds = dBonds(obj);
            dbArray = [obj.DB];
            dbFolderArray = {dbArray.folder_};
            [~,ia,ic] = unique(dbFolderArray);
            for i=1:length(ia)
                vertexArray{i} = dbArray(ia(i)).vertices;
            end
            flags = [];
            for i=1:size(obj,2)
                if mod(i,100) ==0
                    sprintf(['Finding vertices for cell # ',num2str(i)])
                end
                for j=1:length(theseDBonds(i,:))
                    vertexIDArray = [vertexArray{ic(i)}.vertex_id];
                    thisID = theseDBonds(i,j).vertex_id;
                    if ~isempty(thisID)
                        flag = (vertexIDArray == thisID);
                        vertices(i,j) = vertexArray{ic(i)}(flag);
                    else
                        vertices(i,j) = Vertex();
                    end
                end
            end
            
        end
        
        function outline = outline(obj) % Currently runs on a 1-dimensional list because of dBonds function.
            theseDBonds = dBonds(obj); % Currently runs on a 1-dimensional list
            dbArray = [obj.DB];
            dbFolderArray = {dbArray.folder_};
            [~,ia,ic] = unique(dbFolderArray);
            for i=1:length(ia)
                bondArray{i} = dbArray(ia(i)).bonds;
                pixelListArray{i} = dbArray(ia(i)).bond_pixel_lists;
            end
            flags = [];
            for i=1:length(obj)
                if isempty(obj(i).outline)
                    if mod(i,10) ==0
                        sprintf(['Finding outline for cell # ',num2str(i)])
                    end
                    orderedDBonds = DBond();
                    orderedDBonds(1) = theseDBonds(i,1);
                    orderedBonds = Bond();
                    % Order cell's dbonds
                    for j=1:(length(theseDBonds(i,:))-1)
                        nextDBond = orderedDBonds(j).left_dbond_id;
                        cellDBondIDs = [theseDBonds(i,:).dbond_id];
                        flag = (cellDBondIDs == nextDBond);
                        orderedDBonds(j+1) = theseDBonds(i,flag);
                    end
                    % Get ordered vertices
                    orderedVertices = [orderedDBonds.vertex_id];
                    % Get bonds for ordered dbonds:
                    for j=1:length(orderedDBonds)
                        bondIDArray = [bondArray{ic(i)}.bond_id];
                        thisID = orderedDBonds(j).bond_id;
                        flag = (bondIDArray == thisID);
                        orderedBonds(j) = bondArray{ic(i)}(flag);
                    end
                    % Get coordinates for each of the bonds:
                    for k=1:length(orderedBonds)
                        thisID = orderedBonds(k).bond_id;
                        bondIDArray = [pixelListArray{ic(i)}.pixel_bondID];
                        flags = (bondIDArray == thisID);
                        orderedBonds(k).pixel_list = pixelListArray{ic(i)}(flags);
                    end
                     
                    
                    
                end
            end
            
        end
        
    end
        
    
end
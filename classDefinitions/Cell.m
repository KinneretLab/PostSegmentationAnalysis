classdef Cell < PhysicalEntity
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
        confidence
        bb_xStart
        bb_yStart
        bb_xEnd
        bb_yEnd
        outline_
        neighbors_
    end
    
    methods
        
        function obj = Cell(varargin)
            if ~isempty(varargin)
                varargin = [varargin(:)', {'confidence'}, {nan}];
            end
            obj@PhysicalEntity(varargin)
        end

        function id = uniqueID(~)
            id = "cell_id";
        end
        
        function cells = neighbors(obj, varargin)
            index_flag = arrayfun(@(entity) isempty(entity.neighbors_), obj);
            obj_to_index = obj(index_flag);
            if ~isempty(obj_to_index)
                fprintf("Indexing neighbors for %d cells\n", length(obj_to_index));
                index_result = obj(index_flag).dBonds.conjugate.cells;
                for i=1:size(index_result, 1)
                    neighbor_row = index_result(i, :);
                    obj_to_index(i).neighbors_ = unique(neighbor_row(~isnan(neighbor_row)));
                end
            end
            sizes = arrayfun(@(entity) length(entity.neighbors_), obj);
            cells(length(obj), max(sizes)) = Cell;
            for i=1:length(obj)
                cells(i, 1:sizes(i)) = obj(i).neighbors_;
            end
            % filter result and put it into result_arr
            if nargin > 1
                cells = cells(varargin{:});
            end
        end
        
        function dbonds = dBonds(obj)
            index = containers.Map;
            clazz = class(DBond);
            lookup_result = cell(size(obj));
            for lookup_idx = 1:length(obj)
                entity = obj(lookup_idx);
                if isnan(entity)
                    continue;
                end
                map_key = [entity.experiment.folder_, '_', clazz];
                full_map_key = [map_key, '_', entity.frame];
                if ~index.isKey(full_map_key)
                    full_dbonds = entity.experiment.lookup(clazz);
                    frame_num = [full_dbonds.frame];
                    for frame_id=unique(frame_num)
                        index([map_key, '_', frame_id]) = full_dbonds(frame_num == frame_id);
                    end
                end
                all_dbonds = index(full_map_key);
                lookup_result{lookup_idx} = all_dbonds([all_dbonds.cell_id] == entity.cell_id);
            end
            sizes = cellfun(@(result) (length(result)), lookup_result);
            dbonds(length(obj), max(sizes)) = DBond;
            for i=1:length(obj)
                dbonds(i, 1:sizes(i)) = lookup_result{i};
            end
        end

        function id_in_frame = idInFrame(obj)
            w = floor((sqrt(8 * obj.cell_id + 1) - 1) / 2);
            t = (w .^ 2 + w) / 2;
            id_in_frame = w - obj.cell_id + t;
        end

        function strID = strID(obj)
            strID = obj.experiment.frames([obj.experiment.frames.frame] == obj.frame).frame_name + "_" + obj.idInFrame;
        end

        function frames = frames(obj)
            frameList = [obj.frame];
            dbArray = [obj.experiment];
            dbFolderArray = {dbArray.folder_};
            [~,ia,ic] = unique(dbFolderArray);
            for i=1:length(ia)
                frameArray{i,:} = dbArray(ia(i)).frames;
            end
            flags = [];
            frames = Frame();
            for i=1:length(frameList)
                if mod(i,1000) ==0
                    disp(sprintf(['Returning frame for cell # ',num2str(i)]));
                end
                frameNumArray = [frameArray{ic(i),:}.frame];
                flags = (frameNumArray == frameList(i));
                frames(i) = frameArray{ic(i)}(flags);
            end
        end

        
        function bonds = bonds(obj)
            theseDBonds = dBonds(obj);
            dbArray = [obj.experiment];
            dbFolderArray = {dbArray.folder_};
            [~,ia,ic] = unique(dbFolderArray);
            for i=1:length(ia)
                bondArray{i} = dbArray(ia(i)).bonds;
            end
            flags = [];
            for i=1:size(obj,2)
                if mod(i,100) ==0
                    disp(sprintf(['Finding bonds for cell # ',num2str(i)]));
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
            dbArray = [obj.experiment];
            dbFolderArray = {dbArray.folder_};
            [~,ia,ic] = unique(dbFolderArray);
            for i=1:length(ia)
                vertexArray{i} = dbArray(ia(i)).vertices;
            end
            flags = [];
            for i=1:size(obj,2)
                if mod(i,100) ==0
                    disp(sprintf(['Finding vertices for cell # ',num2str(i)]));
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

        function obj = outline(obj) % Currently runs on a 1-dimensional list because of dBonds function.
            disp(sprintf('Getting directed bonds'));
            theseDBonds = dBonds(obj); % Currently runs on a 1-dimensional list
            dbArray = [obj.experiment];
            dbFolderArray = {dbArray.folder_};
            [~,ia,ic] = unique(dbFolderArray);
            for i=1:length(ia)
                disp(sprintf('Creating bond array'));
                bondArray{i} = dbArray(ia(i)).bonds;
                disp(sprintf('Creating bond pixel list array'));
                pixelListArray{i} = dbArray(ia(i)).bond_pixel_lists;
                disp(sprintf('Creating vertex array'));
                vertexArray{i} = dbArray(ia(i)).vertices;

            end
            flags = [];
            for i=1:length(obj)
                if mod(i,50) == 0
                    disp(sprintf(['Finding outline for cell # ',num2str(i)]));
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
                % Get coordinates for each of the bonds, flip if necessary, and complete outline with vertices:
                thisOutline = [];
                for k=1:length(orderedBonds)
                  thisID = orderedBonds(k).bond_id;
                    bondIDArray = [pixelListArray{ic(i)}.pixel_bondID];
                    flags = (bondIDArray == thisID);
                    orderedBonds(k).pixel_list = pixelListArray{ic(i)}(flags);
                    startVertex = vertexArray{ic(i)}([vertexArray{ic(i)}.vertex_id] == orderedVertices(k));
                    if ~isempty(orderedBonds(k).pixel_list)
                        [~,I] = min(sqrt((orderedBonds(k).pixel_list.orig_x_coord-startVertex.x_pos).^2 +(orderedBonds(k).pixel_list.orig_y_coord-startVertex.y_pos).^2));
                        if I == 1
                            theseCoords =  [orderedBonds(k).pixel_list.orig_x_coord,orderedBonds(k).pixel_list.orig_y_coord];
                        else if I==length(orderedBonds(k).pixel_list.orig_x_coord)
                                theseCoords =  flipud([orderedBonds(k).pixel_list.orig_x_coord,orderedBonds(k).pixel_list.orig_y_coord]);
                            end
                        end
                        thisOutline = [thisOutline;[startVertex.x_pos,startVertex.y_pos];theseCoords];
                    else
                        thisOutline = [thisOutline;[startVertex.x_pos,startVertex.y_pos]];
                    end
                end
                obj(i).outline_ = thisOutline;
            end

        end

    end

end
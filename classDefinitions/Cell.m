classdef Cell < PhysicalEntity
    % CELL The base biological unit of life, and the focus of our work.
    % Most of the graphing we do happens on this class type, ad there many
    % phenomena relevant to cells.
    % Cells have the biggest presence in any frame, and are the only
    % objects that directly have a confidence score, which indicates how
    % reliable they are for scienfitic study.
    properties
        % the unique identifier of this CELL
        % type: int
        cell_id
        % the ID of the frame this CELL exists in
        % type: int
        frame
        % type: double
        center_x
        % type: double
        center_y
        % type: double
        center_z
        % the geometrically corrected area of the cell, that is, how much space is occupies.
        % type: double
        area
        % type: double
        aspect_ratio
        % the geometrically corrected perimeter of the cell, that is, how much space the outline occupies.
        % type: double
        perimeter
        % Does the cell exist at the edge of the animal?
        % Set to 1 if the cell is next to the empty void, and 0 if it has a
        % neighboring cell in every direction.
        % type: boolean
        is_edge
        % Does the cell's geometric center exist outside of the cell?
        % Set to 1 if the cell's geometric center is outside the cell, and
        % 0 if it is inside the cell.
        % if this is set to 1, it is reasonable to assume the cell is fake.
        % type: boolean
        is_convex
        % type: double
        elong_xx
        % type: double
        elong_yy
        % type: double
        elong_zz
        % type: double
        norm_x
        % type: double
        norm_y
        % type: double
        norm_z
        % type: double
        fibre_orientation
        % type: double
        fibre_localOP
        % type: double
        fibre_coherence
        % Defines how sure we are this cell really exists.
        % values over 0.5 yield confidence the cell exists, while lower
        % values indicate uncertainty for the bond.
        % type: double (0.0-1.0)
        confidence
        % The lower X coordinate of the rectangle (bounding box) containing the pixels of the cell in its frame.
        % type: int
        bb_xStart
        % The lower Y coordinate of the rectangle (bounding box) containing the pixels of the cell in its frame.
        % type: int
        bb_yStart
        % The higher X coordinate of the rectangle (bounding box) containing the pixels of the cell in its frame.
        % type: int
        bb_xEnd
        % The higher Y coordinate of the rectangle (bounding box) containing the pixels of the cell in its frame.
        % type: int
        bb_yEnd
        % the list of pixel coordinates indicating the edges of the cell
        % you can calculate these values for retrieval using CELL#OUTLINE()
        % then retrieve them from this variable.
        % type: double[][]
        outline_
        % An internal vairblae listing the cells that share a border with this cell.
        % you can access this using CELL#NEIGHBORS
        % type: CELL[]
        neighbors_
        plot_pixels_
    end
    
    methods
        
        function obj = Cell(varargin)
            % CELL construct an array of cells.
            % This includes NaNs for any calculated value so things don't
            % mess up in array calculations.
            obj@PhysicalEntity([varargin(:)', {'confidence'}, {nan}, {'center_x'}, {nan}, ...
                {'center_y'}, {nan}, {'center_z'}, {nan}, {'area'}, {nan}, {'aspect_ratio'}, {nan}, ...
                {'perimeter'}, {nan}, {'is_edge'}, {nan}, {'is_convex'}, {nan}, {'elong_xx'}, {nan}, ...
                {'elong_yy'}, {nan}, {'elong_zz'}, {nan}, {'norm_x'}, {nan}, {'norm_y'}, {nan}, ...
                {'norm_z'}, {nan}, {'fibre_orientation'}, {nan}, {'fibre_localOP'}, {nan}, ...
                {'fibre_coherence'}, {nan}, {'bb_xStart'}, {nan}, {'bb_yStart'}, {nan}, ...
                {'bb_xEnd'}, {nan}, {'bb_yEnd'}, {nan}])
        end

        function id = uniqueID(~)
            id = "cell_id";
        end
        
        function cells = neighbors(obj, varargin)
            % NEIGHBORS Find all the cells that share a border with this cell.
            % That is, this only has level 1 neighbors.
            % Parameters:
            %   varargin: additional MATLAB builtin operations to apply on
            %   the result.
            % Return type: CELL[]
            cells = obj.getOrCalculate(class(Cell), "neighbors_", @(cell_arr) cell_arr.dBonds.conjugate.cells, varargin{:});
        end

        function id_in_frame = idInFrame(obj)
            % IDINFRAME find the unique ID of this cell, but within the frame it exists in.
            % This allows or a more consistent and use ordering of the
            % cells for the cost of uniqueness for the entire experiment.
            % Could be useful for tracking.
            % Return type: int[]
            w = floor((sqrt(8 * [obj.cell_id] + 1) - 1) / 2);
            t = (w .^ 2 + w) / 2;
            id_in_frame = w - [obj.cell_id] + t;
        end

        function strID = strID(obj)
            % STRID find the unique name (not ID) of this cell.
            % This is more useful for file-system operations like saving
            % the cell image in a seperate file.
            % Return type: string[]
            strID = convertCharsToStrings({obj.frames.frame_name}) + "_" + obj.idInFrame;
        end

        function bonds = bonds(obj, varargin)
            % VERTICES calculates the bonds each cell in this array borders (or touches).
            % Parameters:
            %   varargin: additional MATLAB builtin operations to apply on
            %   the result.
            % Return type: BOND[]
            bonds = obj.dBonds.bonds(varargin{:});
        end

        function vertices = vertices(obj, varargin)
            % VERTICES calculates the vertices each cell in this array borders (or touches).
            % Parameters:
            %   varargin: additional MATLAB builtin operations to apply on
            %   the result.
            % Return type: VERTEX[]
            vertices = obj.dBonds.startVertices(varargin{:});
        end
        
        function cells = cells(obj, varargin)
            % CELLS the identity function
            % Parameters:
            %   varargin: additional MATLAB builtin operations to apply on
            %   the result.
            % Return type: CELL[]
            cells = obj(varargin{:});
        end



        function obj = outline(obj)
            % OUTLINE Calculates the list of pixel coordinates indicating the edges of the cell
            % you can retrieve them from the variable CELL#outline_.
            % Currently runs on a 1-dimensional list, if multidiemnsional array is given, it is first flattened.
            obj = flatten(obj);
            fprintf('Getting directed bonds');
            theseDBonds = dBonds(obj); % Currently runs on a 1-dimensional list
            dbArray = [obj.experiment];
            dbFolderArray = {dbArray.folder_};
            [~,ia,ic] = unique(dbFolderArray);
            for i=1:length(ia)
                fprintf('Creating bond array\n');
                bondArray{i} = dbArray(ia(i)).bonds;
                fprintf('Creating bond pixel list array\n');
                pixelListArray{i} = dbArray(ia(i)).bondPixelLists;
                fprintf('Creating vertex array\n');
                vertexArray{i} = dbArray(ia(i)).vertices;

            end
            flags = [];
            for i=1:length(obj)
                if mod(i,50) == 0
                    fprintf('Finding outline for cell #%d \n', i);
                end
                if isempty(obj(i).outline_)
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

        function plot_pixels = plot_pixels(obj)
            plot_pixels = {};
            obj = flatten(obj);
            sprintf('Getting cell outlines')
            obj = outline(obj);
            disp(sprintf('Finding pixels inside cell outlines'));
            for i=1:length(obj)
                if isempty(obj(i).plot_pixels_)
                    minX = floor(min(obj(i).outline_(:,1)));
                    maxX = ceil(max(obj(i).outline_(:,1)));
                    minY = floor(min(obj(i).outline_(:,2)));
                    maxY = ceil(max(obj(i).outline_(:,2)));
                    [xq,yq] = meshgrid([minX:maxX],[minY:maxY]);
                    in = inpolygon(xq,yq,obj(i).outline_(:,1),obj(i).outline_(:,2));
                    obj(i).plot_pixels_ = [xq(in),yq(in)];

                end
                plot_pixels{i} = obj(i).plot_pixels_;
            end

        end

    end

end
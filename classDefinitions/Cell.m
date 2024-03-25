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
        center_x = nan;
        % type: double
        center_y = nan;
        % type: double
        center_z = nan;
        % the geometrically corrected area of the cell, that is, how much space is occupies.
        % type: double
        area = nan;
        % type: double
        aspect_ratio = nan;
        % the geometrically corrected perimeter of the cell, that is, how much space the outline occupies.
        % type: double
        perimeter = nan;
        % Does the cell exist at the edge of the animal?
        % Set to 1 if the cell is next to the empty void, and 0 if it has a
        % neighboring cell in every direction.
        % type: boolean
        is_edge = nan;
        % Does the cell's geometric center exist outside of the cell?
        % Set to 1 if the cell's geometric center is outside the cell, and
        % 0 if it is inside the cell.
        % if this is set to 1, it is reasonable to assume the cell is fake.
        % type: boolean
        is_convex = nan;
        % type: double
        elong_xx = nan;
        % type: double
        elong_yy = nan;
        % type: double
        elong_zz = nan;
        % type: double
        norm_x = nan;
        % type: double
        norm_y = nan;
        % type: double
        norm_z = nan;
        % type: double
        fibre_orientation = nan;
        % type: double
        fibre_localOP = nan;
        % type: double
        fibre_coherence = nan;
        % Defines how sure we are this cell really exists.
        % values over 0.5 yield confidence the cell exists, while lower
        % values indicate uncertainty for the bond.
        % type: double (0.0-1.0)
        confidence = nan;
        % The lower X coordinate of the rectangle (bounding box) containing the pixels of the cell in its frame.
        % type: int
        bb_xStart = nan;
        % The lower Y coordinate of the rectangle (bounding box) containing the pixels of the cell in its frame.
        % type: int
        bb_yStart = nan;
        % The higher X coordinate of the rectangle (bounding box) containing the pixels of the cell in its frame.
        % type: int
        bb_xEnd = nan;
        % The higher Y coordinate of the rectangle (bounding box) containing the pixels of the cell in its frame.
        % type: int
        bb_yEnd = nan;
        % Magnitude of cell shape tensor Q calculated from cell projected on tangent plane and then rotated to xy plane around the intersection axis:
        Q = [];
        % Qxx element of cell shpae tensor Q calculated from cell projected on tangent plane and then rotated to xy plane around the intersection axis:
        Q_xx = [];
        % Qxy element of cell shpae tensor Q calculated from cell projected on tangent plane and then rotated to xy plane around the intersection axis:
        Q_xy = [];
        % the list of pixel coordinates indicating the edges of the cell
        % you can calculate these values for retrieval using CELL#OUTLINE()
        % then retrieve them from this variable.
        % type: double[][]
        outline_
        % An internal vairblae listing the cells that share a border with this cell.
        % you can access this using CELL#NEIGHBORS
        % type: CELL[]
        neighbors_ = Null.null;
        % List of pixels inside cell used for plotting in images
        plot_pixels_

    end

    methods

        function obj = Cell(varargin)
            % CELL construct an array of cells.
            % This includes NaNs for any calculated value so things don't
            % mess up in array calculations.
            obj@PhysicalEntity(varargin)
        end

        function id = uniqueID(~)
            id = "cell_id";
        end

        function logger = logger(~)
            logger = Logger('Cell');
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

        function q_xx = q_xx(obj, varargin)
            % Get or calculate the xx element of Q shape tensor
            % Parameters:
            %   varargin: additional MATLAB builtin operations to apply on
            %   the result.
            % Return type: DOUBLE[]
            full_q = obj.getOrCalculate('double', ["Q_xx","Q_xy","Q"], @calculateCellQ,varargin{:});
            q_xx = full_q(1,:);   
        end

        function q_xy = q_xy(obj, varargin)
            % Get or calculate the xy element of Q shape tensor
            % Parameters:
            %   varargin: additional MATLAB builtin operations to apply on
            %   the result.
            % Return type: DOUBLE[]
            full_q = obj.getOrCalculate('double', ["Q_xx","Q_xy","Q"], @calculateCellQ,varargin{:});
            q_xy = full_q(2,:);
        end

        function q = q(obj, varargin)
            % Get or calculate the magnitude of Q shape tensor
            % Parameters:
            %   varargin: additional MATLAB builtin operations to apply on
            %   the result.
            % Return type: DOUBLE[]
            full_q = obj.getOrCalculate('double', ["Q_xx","Q_xy","Q"], @calculateCellQ,varargin{:});
            q = full_q(3,:);
        end

        function obj = outline(obj)
            % OUTLINE Calculates the list of pixel coordinates indicating the edges of the cell
            % you can retrieve them from the variable CELL#outline_.
            % Currently runs on a 1-dimensional list, if multidiemnsional array is given, it is first flattened.
            obj = flatten(obj);
            obj.logger.debug('Getting directed bonds');
            theseDBonds = dBonds(obj); % Currently runs on a 1-dimensional list
            theseVertices = obj.vertices; % Get vertices for all cells
            theseBonds = obj.bonds; % Get bonds for each cell
            obj.bonds.coords; % Get bonds and get pixel list for all of them
            flags = [];
            for i=1:length(obj)
                obj.logger.progress('Finding outline for cell', i, length(obj));
                if isempty(obj(i).outline_)
                    orderedDBonds = DBond();
                    orderedDBonds(1) = theseDBonds(i,1);
                    orderedBonds = Bond();
                    cellDBonds = theseDBonds(i,:); % Make sure only non-empty dbonds are used:
                    numDBonds = length(cellDBonds(~isnan(cellDBonds)));
                    % Order cell's dbonds
                    if numDBonds>1
                        for j=1:(numDBonds-1)
                            nextDBond = orderedDBonds(j).left_dbond_id;
                            cellDBondIDs = [theseDBonds(i,:).dbond_id];
                            flag = (cellDBondIDs == nextDBond);
                            orderedDBonds(j+1) = theseDBonds(i,flag);
                        end
                    end
                    % Get ordered vertices
                    orderedVertices = [orderedDBonds.vertex_id];
                    % Get cell bonds:
                    cellBonds = unique(theseBonds(i,:));
                    % Get bonds for ordered dbonds:
                    for j=1:length(orderedDBonds)
                        bondIDArray = [cellBonds.bond_id];
                        thisID = orderedDBonds(j).bond_id;
                        flag = (bondIDArray == thisID);
                        orderedBonds(j) = cellBonds(flag);
                    end
                    % Get coordinates for each of the bonds, flip if necessary, and complete outline with vertices:
                    thisOutline = [];
                    for k=1:length(orderedBonds)
                        cellVertices = theseVertices(i,:);
                        startVertex = cellVertices([cellVertices.vertex_id] == orderedVertices(k));
                        if isempty(startVertex)
                            theseCoords =  [orderedBonds(k).pixel_list.orig_x_coord,orderedBonds(k).pixel_list.orig_y_coord];
                            thisOutline = [thisOutline; theseCoords];
                        else
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
                    end
                    obj(i).outline_ = thisOutline;
                end
            end

        end

        function plot_pixels = plot_pixels(obj)
            plot_pixels = {};
            obj = flatten(obj);
            obj.logger.debug('Getting cell outlines')
            obj = outline(obj);
            obj.logger.info('Finding pixels inside cell outlines');
            for i=1:length(obj)
                if isempty(obj(i).plot_pixels_)
                    minX = floor(min(obj(i).outline_(:,1)));
                    maxX = ceil(max(obj(i).outline_(:,1)));
                    minY = floor(min(obj(i).outline_(:,2)));
                    maxY = ceil(max(obj(i).outline_(:,2)));
                    [xq,yq] = meshgrid([minX:maxX],[minY:maxY]);
                    [in,on] = inpolygon(xq,yq,round(obj(i).outline_(:,1)),round(obj(i).outline_(:,2)));
                    obj(i).plot_pixels_ = [xq(in & (~on)),yq(in & (~on))];

                end
                plot_pixels{i} = obj(i).plot_pixels_;
            end

        end

        function list_pixels = list_pixels(obj)
            list_pixels = [];
            obj = flatten(obj);
            list_pixels(:,1) = [obj.center_x];
            list_pixels(:,2) = [obj.center_y];
            %         list_pixels(:,3) = [obj.center_z];

        end

        function pair_arr = createNeighborPairs(obj)
            pair_arr = [];
            obj.frames.cells.neighbors;
            for i=1:length(obj)
                obj.logger.progress('Finding pairs for cell', i, length(obj));
                % Create first rank neihgbour pairs
                if ~Null.isNull(obj(i).neighbors_) & ~isempty(obj(i).neighbors_)
                    cell_pairs = {};
                    cell_pairs{1} = Pair([repmat(obj(i),length(obj(i).neighbors_),1), obj(i).neighbors_'],ones(length(obj(i).neighbors_),1));
                    % Proceed to further ranks:
                    stopCount = 0;
                    rank = 1;
                    allNeighbors = [];
                    while ~stopCount
                        theseNeighbors = unique(arrayfun( @(arr) arr.elements(2), cell_pairs{rank}));
                        allNeighbors = [allNeighbors,theseNeighbors];
                        rank = rank+1;
                        cell_pairs{rank} = {};
                        for j=1:length(theseNeighbors)
                            new_neighbors = unique(theseNeighbors(j).neighbors_);
                            new_neighbors = new_neighbors(ne(new_neighbors,obj(i)));
                            new_neighbors = setdiff(new_neighbors,allNeighbors);
                            if ~isnan(new_neighbors)
                                new_pairs = Pair([repmat(obj(i),length(new_neighbors),1), new_neighbors'],rank*ones(length(new_neighbors),1));
                                cell_pairs{rank} = [cell_pairs{rank},new_pairs];
                            end
                        end
                        stopCount = isempty(cell_pairs{rank});
                    end
                    pair_arr = [pair_arr,[cell_pairs{1,:}]];
                end
            end
        end

        function cell_dist = cellDist(obj,obj2)

            obj = flatten(obj);
            pair_arr = unique(obj2.createNeighborPairs);
            pair_cells = arrayfun(@(pair) pair.elements(2),pair_arr);
            cell_dist = [];
            for i=1:length(obj)
                if obj(i) == obj2
                    cell_dist(i) = 0;
                else
                    if obj(i).frame ~= obj2.frame

                        cell_dist(i) = Nan;
                    else
                        cell_dist(i) = pair_arr(pair_cells == obj(i)).distance;
                    end
                end
            end

        end

        function [Q] = calculateCellQ(obj)
            % Get directed bonds for all cells:
            obj = flatten(obj);
            obj.logger.debug('Getting directed bonds')
            theseDBonds = dBonds(obj); % Currently runs on a 1-dimensional list
            obj.logger.debug('Getting vertices')
            these_vertices = obj.vertices;
            Q = [];
            Q_xx_cell = [];
            Q_xy_cell = [];
            Q_cell = [];
            obj.logger.info('Starting Q calculation')
            for i=1:length(obj)
                obj.logger.progress('Calculating Q for cell', i, length(obj));
                     % This was to order the dBonds, but they should be ordered to begin with.
%                     orderedDBonds = DBond();
%                     orderedDBonds(1) = theseDBonds(i,1);
%                     cellDBonds = theseDBonds(i,:); % Make sure only non-empty dbonds are used:
%                     numDBonds = length(cellDBonds(~isnan(cellDBonds)));
%                     % Order cell's dbonds
%                     if numDBonds>1
%                         for j=1:(numDBonds-1)
%                             nextDBond = orderedDBonds(j).left_dbond_id;
%                             cellDBondIDs = [theseDBonds(i,:).dbond_id];
%                             flag = (cellDBondIDs == nextDBond);
%                             orderedDBonds(j+1) = theseDBonds(i,flag);
%                         end
%                     end
                    % Get ordered vertices
                    ordered_vertices = [theseDBonds(i,:).vertex_id];
                    cell_vertices = these_vertices(i,:);

                    if ordered_vertices ~= 0
                        % Place first vertex again at the end of list
                        % of ordered vertices:
                        ordered_vertices = [ordered_vertices,ordered_vertices(1)];
                        % Get cell centre
                        c_x = obj(i).center_x;
                        c_y = obj(i).center_y;
                        c_z = obj(i).center_z;

                        % Initialize arrays of triangle measures:
                        triangle_Q = []; two_phi= [];tri_area = [];
                        % Run over triangles comprising the cell:
                        for j=1:length(ordered_vertices)-1

                            v1 = cell_vertices([cell_vertices.vertex_id]==ordered_vertices(j));
                            v2 = cell_vertices([cell_vertices.vertex_id]==ordered_vertices(j+1));

                            v1_x = v1.x_pos;
                            v1_y = v1.y_pos;
                            v1_z = v1.z_pos;
                            v2_x = v2.x_pos;
                            v2_y = v2.y_pos;
                            v2_z = v2.z_pos;

                            % Project vertices onto plane defined by
                            % normal and going through the centre of
                            % the cell:
                            N = [obj(i).norm_x,obj(i).norm_y,obj(i).norm_z];

                            tri_verts = [c_x,c_y,c_z; v2_x,v2_y,v2_z; v1_x,v1_y,v1_z]; % To make the tirangles counter-clockwise when y is read bottom to top
                            proj = tri_verts - ((tri_verts - [c_x,c_y,c_z])*(N')) * N;

                            % Rotate to xy plane through cell centre
                            RZ = [N(1)/sqrt((N(1)^2)+(N(2)^2)) N(2)/sqrt((N(1)^2)+(N(2)^2))  0 ; -N(2)/sqrt((N(1)^2)+(N(2)^2)) N(1)/sqrt((N(1)^2)+(N(2)^2)) 0; 0 0 1];
                            Nprime = RZ*N';
                            RY = [Nprime(3) 0 -Nprime(1); 0 1 0 ; Nprime(1) 0 Nprime(3)];
                            translatedProj = proj-[c_x,c_y,c_z];
                            rotatedProj = (RY*(RZ*translatedProj'))';

                            % Deal with case of N being in the Z direction
                            if or(round(N,4) == [0,0,1],round(N,4) == [0,0,-1])
                                rotatedProj = translatedProj;
                            end

                            % Calculate Q for triangle on xy plane

                            [triangle_Q(j),two_phi(j),tri_area(j)] = obj.calculateTriangleQ(rotatedProj(:,1:2));

                        end

                        % Calculate Q for cell on xy plane by an area weighted
                        % average over triangles:
                        if isreal(triangle_Q)

                            Q_xx = triangle_Q.*cos(two_phi);
                            Q_xy= triangle_Q.*sin(two_phi);
                            Q_xx_area = Q_xx.*tri_area;
                            Q_xy_area= Q_xy.*tri_area;
                        else
                            Q_xx = nan;
                            Q_xy= nan;
                            Q_xx_area = nan;
                            Q_xy_area= nan;
                        end

                    else
                        Q_xx = nan;
                        Q_xy= nan;
                        Q_xx_area = nan;
                        Q_xy_area= nan;
                    end

                    Q_xx_cell(i) = sum(Q_xx_area)/sum(tri_area);
                    Q_xy_cell(i) = sum(Q_xy_area)/sum(tri_area);
                    Q_cell(i) = sqrt(Q_xx_cell(i)^2 + Q_xy_cell(i)^2);

                    % Save Q calculated from xy plane

                    obj(i).Q = Q_cell(i);
                    obj(i).Q_xx = Q_xx_cell(i);
                    obj(i).Q_xy = Q_xy_cell(i);

            end
            Q = [Q_xx_cell; Q_xy_cell; Q_cell];
        end

        function [axis] = referenceAxis(obj,mode,varargin)
            % Calculate reference axis for projecting cell shape tensor.
            % Currently the two options are the axis between the cell and
            % the defect location, and the local fibre orientation axis.
            % More options can be added. For both options, the direction
            % is found in the tangent plane and then rotated to the xy
            % plane in the same way as the cell, so the projection of the
            % cell Q on the reference axis can be done in 2d on the xy
            % plane.
            obj = flatten(obj);
            axis = [];
            for i=1:length(obj)
                if strcmp(mode,'by_defect')
                    if nargin<3
                        defect_idx = 1;
                    else
                        defect_idx = varargin{1};
                    end
                    defects = obj(i).frames.defects; % Get defect from the cell's frame;
                    defect_loc = defects(defect_idx).list_pixels;
                    % Calculate axis between defect and cell centre
                    % projected on xy plane
                    planar_axis = [defect_loc(1)-obj(i).center_x,defect_loc(2)-obj(i).center_y,0];

                elseif strcmp(mode,'by_fibre_orientation')
                    % Calculate axis as orientation of fibres projected
                    % on xy plane
                    planar_axis = [cos(obj(i).fibre_orientation),sin(obj(i).fibre_orientation),0];
                else
                    obj.logger.error('Mode not recognized');
                    return
                end

                % Project planar axis back onto cell tangent plane:
                N = [obj(i).norm_x,obj(i).norm_y,obj(i).norm_z];
                proj_axis = planar_axis - planar_axis*(N') * N;
                % Normalize axis length to 1
                proj_axis = proj_axis/norm(proj_axis);

                % Rotate to xy plane using same transformation as for
                % cell (rotating round intersection axis between cell
                % tangent plane and xy plane):

                RZ = [N(1)/sqrt((N(1)^2)+(N(2)^2)) N(2)/sqrt((N(1)^2)+(N(2)^2))  0 ; -N(2)/sqrt((N(1)^2)+(N(2)^2)) N(1)/sqrt((N(1)^2)+(N(2)^2)) 0; 0 0 1];
                Nprime = RZ*N';
                RY = [Nprime(3) 0 -Nprime(1); 0 1 0 ; Nprime(1) 0 Nprime(3)];
                axis(i,:) = (RY*(RZ*proj_axis'))';

            end
            axis = axis(:,1:2);
        end

    end
end
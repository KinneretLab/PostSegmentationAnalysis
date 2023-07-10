classdef TrueVertex < PhysicalEntity
    % TRUEVERTEX A point of combination of vertices that represent an
    % actual cell vertex in the organism. This can potentially not be a
    % physical point
    properties
        % the ID of the frame this TrueVertex exists in
        % type: int
        frame
        % the unique identifier of this entity
        % type: int
        vertex_id
        % the pixel X coordinate of the vertex in the image
        x_pos
        % the pixel Y coordinate of the vertex in the image
        y_pos
        % is this vertex an existing vertex in the segmented image, or a
        % combination of multiple very close vertices?
        % type: bool
        physical = false;
        % a list of the technical vertices this true vertex describes.
        % type: Vertex[]
        children
        % the minimum distance from the center to all the child vertices.
        % type: double
        radius
        % the radius constraint used to merge vertices
        % type: double
        radius_filter
        % the non-trivial bonds connected to this true vertex.
        % Use TRUEVERTEX#bonds to obtain this value.
        % type: BOND[]
        bonds_ = Null.null;
    end
    
    methods
        function obj = TrueVertex(experiment, varargin)
            obj@PhysicalEntity({});
            if nargin > 0
                if nargin > 1
                    radius_filter = varargin{1};
                else
                    radius_filter = 5;
                end
                short_bonds = experiment.bonds;
                bond_length = [short_bonds.bond_length];
                short_bonds = short_bonds(isnan(bond_length) | bond_length <= radius_filter);
                obj.logger.info("Getting vertices for short bonds...");
                candidates = short_bonds.vertices;
                flat = candidates.flatten;
                % a potential way to make this more efficient is using a
                % KD-tree. The important thing here to resolve is
                % duplicate searches.
                children = {candidates(1, :)};
                candidates(1, :) = [];
                total = size(candidates, 1);
                while size(candidates, 1) > 0
                    obj.logger.progress("Merging vertex lists", total - size(candidates, 1), total);
                    % search for duplicates
                    found = find(~isnan(candidates) & ismember(candidates, children{end}));
                    if isempty(found)
                        children{end+1} = candidates(1, :);
                        candidates(1, :) = [];
                    else
                        [rows, ~] = ind2sub(size(candidates), found);
                        to_append = candidates(rows, :);
                        candidates(rows, :) = [];
                        children{end} = unique([children{end}, to_append(:)']);
                    end
                end
                obj.logger.progress("Merging vertex lists", total, total);
                solo_vertices = experiment.vertices;
                solo_vertices = solo_vertices(~ismember(solo_vertices, flat));
                l = length(solo_vertices);
                obj(1, l + length(children)) = feval(class(obj));
                % set experiment
                [obj.experiment] = deal(experiment);
                [obj.radius_filter] = deal(radius_filter);
                % set physical/non-physical
                [obj(1:l).physical] = deal(true);
                % set base propertoes for solo cells
                obj.logger.info("Setting solo vertex properties...");
                solo_cell_arr = num2cell(solo_vertices);
                [obj(1:l).children] = solo_cell_arr{:};
                [obj(1:l).frame] = solo_vertices.frame;
                [obj(1:l).x_pos] = solo_vertices.x_pos;
                [obj(1:l).y_pos] = solo_vertices.y_pos;
                [obj(1:l).vertex_id] = solo_vertices.vertex_id;
                % set base properties for merged cells
                obj.logger.info("Setting merged vertex properties...");
                [obj((l+1):end).children] = children{:};
                intermediate = cellfun(@(vertices) vertices(1).frame, children, 'UniformOutput', false);
                [obj((l+1):end).frame] = intermediate{:};
                intermediate = cellfun(@(vertices) mean([vertices.x_pos]), children, 'UniformOutput', false);
                [obj((l+1):end).x_pos] = intermediate{:};
                intermediate = cellfun(@(vertices) mean([vertices.y_pos]), children, 'UniformOutput', false);
                [obj((l+1):end).y_pos] = intermediate{:};
                intermediate = cellfun(@(vertices) min([vertices.vertex_id]), children, 'UniformOutput', false);
                [obj((l+1):end).vertex_id] = intermediate{:};
            end
        end

        function id = uniqueID(~)
            id = "vertex_id";
        end
        
        function logger = logger(~)
            logger = Logger('TrueVertex');
        end
        
        function n = nargs(~)
            n = 1;
        end
        
        function bonds = bonds(obj, varargin)
            % BONDS calculates the bonds each vertex in this array touches.
            % Parameters:
            %   varargin: additional MATLAB builtin operations to apply on
            %   the result.
            % Return type: BOND[]
            bonds = obj.getOrCalculate(class(Bond), "bonds_", @calcBonds, varargin{:});
        end
        
        function list_pixels = list_pixels(obj)
            
            list_pixels = [];
            obj = flatten(obj);
            list_pixels(:,1) = [obj.x_pos];
            list_pixels(:,2) = [obj.y_pos];
        end
    end
    
    methods (Access = private)
        function bonds = calcBonds(obj)
            % merge the children into an array
            sizes = arrayfun(@(entity) length(entity.children), obj);
            vertices(numel(obj), max(sizes, [], 'all')) = Vertex;
            for i=1:numel(obj)
                if sizes(i) > 0
                    vertices(i, 1:sizes(i)) = obj(i).children;
                end
            end
            
            % get the relevent bonds
            all_bonds = vertices.bonds;
            % merge and remove bonds that are too small
            bonds = reshape(all_bonds, size(all_bonds, 1), []);
            bonds([bonds.bond_length] <= obj(1).radius_filter) = Bond;
        end
    end
end


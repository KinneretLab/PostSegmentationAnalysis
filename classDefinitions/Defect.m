classdef Defect < PhysicalEntity
    % VERTEX A point on the graph that represents one of the edges of a bond.
    % Vertices acts as the oundray both between 3 cells or more, or between 3
    % bonds (or dbonds) or more.
    % At the end of the day, this is just a physical point.
    properties
        % the ID of the frame this Vertex exists in
        % type: int
        frame
        % the unique identifier of this defect, tracked through the movie
        % type: int
        defect_id
%         % a unique identifier per defect and frame
%         unique_id
        % the pixel X coordinate of the vertex in the image
        x_pos
        % the pixel Y coordinate of the vertex in the image
        y_pos
        % defect type (topological charge)
        type
        % comment (normal, spread out, based on neighbouring frames,
        % unclear)
        comment

    end
    
    methods
        
        function obj = Defect(varargin)
            % VERTEX construct an array of Vertexes. Nothing special.
            obj@PhysicalEntity(varargin)
        end

        function id = uniqueID(~)
            id = "defect_id";
        end
        
        function logger = logger(~)
            logger = Logger('Defect');
        end
        
        function defects = defects(obj, varargin)
            % DEFEECTS the identity function
            % Parameters:
            %   varargin: additional MATLAB builtin operations to apply on
            %   the result.
            % Return type: DEFECT[]
            defects = obj(varargin{:});
        end
        
        function defect_cell = cells(obj, use_defect_pair)
            % CELLS calculates the cell with the closest centre to the
            % defect location. If 'use_defect_pair' = 1, this means the
            % function will check if there is a pair of +1/2,+1/2
            % defects, and return the cell at the midpoint
            % between them.
            % Parameters:
            %   varargin: additional MATLAB builtin operations to apply on
            %   the result.
            % Return type: CELL[]
            defect_cell = Cell();
            obj = flatten(obj);
            for i = 1:length(obj)
                if strcmp(use_defect_pair,'use_defect_pair')
                   frame_defects = obj(i).siblings('frame');
                   pair_exist = length(frame_defects)==2;
                   pair_type = isequal([frame_defects.type],[1/2,1/2]);
                   if pair_exist && pair_type % Check whether there is a pair of +1/2 defects in the frame, and find cell closest to centre between them:
                        all_cells = obj(i).frames.cells;
                        dist1 = frame_defects(1).pixelDist2d(all_cells);
                        dist2 = frame_defects(2).pixelDist2d(all_cells);
                        [~,ind] = min(dist1+dist2);
                        defect_cell(i) = all_cells(ind);
                   else
                       % Follow case of single defect:
                       all_cells = obj(i).frames.cells; % Find all cells in frame
                       dist = obj(i).pixelDist2d(all_cells); % Find 2d distance between cells and defect
                       [~,ind] = min(dist);
                       defect_cell(i) = all_cells(ind);
                   end
                else
                    % Case of single defect:
                    all_cells = obj(i).frames.cells;
                    if ~isempty(all_cells)
                        dist = obj(i).pixelDist2d(all_cells);
                        [~,ind] = min(dist);
                        defect_cell(i) = all_cells(ind);

                    end
                end
            end
        end

        function list_pixels = list_pixels(obj)
            list_pixels = [];
            obj = flatten(obj);
            list_pixels(:,1) = [obj.x_pos];
            list_pixels(:,2) = [obj.y_pos];
        end
        
    end
    
end
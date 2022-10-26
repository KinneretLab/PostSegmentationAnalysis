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
        
        function list_pixels = list_pixels(obj)
            list_pixels = [];
            obj = flatten(obj);
            list_pixels(:,1) = [obj.x_pos];
            list_pixels(:,2) = [obj.y_pos];
        end
        
    end
    
end
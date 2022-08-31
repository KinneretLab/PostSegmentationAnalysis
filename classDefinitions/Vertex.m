classdef Vertex < PhysicalEntity
    properties
        frame
        vertex_id
        x_pos
        y_pos
    end
    
    methods
        
        function obj = Vertex(varargin)
            obj@PhysicalEntity(varargin)
        end

        function id = uniqueID(~)
            id = "vertex_id";
        end
        
        function vertices = vertices(obj, varargin)
            vertices = obj(varargin{:});
        end
        
        function bonds = bonds(obj, varargin)
            dbonds = [obj.dbonds, obj.lookupMany(clazz, "vertex_id", "vertex2_id")];
            bonds = dbonds.bonds;
            for i=1:length(obj)
                temp = unique(bonds(i,:));
                temp = temp(~isnan(temp));
                bonds(i, :) = Bond;
                bonds(i, 1:length(temp)) = temp;
            end
            % filter result and put it into result_arr
            if nargin > 1
                bonds = bonds(varargin{:});
            end
        end
        
        function cells = cells(obj, varargin)
            dbonds = [obj.dbonds, obj.lookupMany(clazz, "vertex_id", "vertex2_id")];
            cells = dbonds.cells;
            for i=1:length(obj)
                temp = unique(cells(i,:));
                temp = temp(~isnan(temp));
                cells(i, :) = Cell;
                cells(i, 1:length(temp)) = temp;
            end
            % filter result and put it into result_arr
            if nargin > 1
                cells = cells(varargin{:});
            end
        end
        
    end
    
end
classdef DBond < PhysicalEntity
    properties
        frame
        dbond_id
        cell_id
        conj_dbond_id
        bond_id
        vertex_id
        vertex2_id
        left_dbond_id
    end
    
    methods
        
        function obj = DBond(varargin)
            obj@PhysicalEntity(varargin)
        end

        function id = uniqueID(~)
            id = "dbond_id";
        end
        
        function dbonds = conjugate(obj, varargin)
            dbonds = obj.lookup1(class(DBond), "conj_dbond_id", "dbond_id", varargin{:});
        end
        
        function dbonds = next(obj, varargin)
            dbonds = obj.lookup1(class(DBond), "left_dbond_id", "dbond_id", varargin{:});
        end
        
        function cells = cells(obj, varargin)
            cells = obj.lookup1(class(Cell), "cell_id", "cell_id", varargin{:});
        end
        
        function bonds = bonds(obj, varargin)
            bonds = obj.lookup1(class(Bond), "bond_id", "bond_id", varargin{:});
        end
        
        function vertices = startVertices(obj, varargin)
            vertices = obj.lookup1(class(Vertex), "vertex_id", "vertex_id", varargin{:});
        end
        
        function vertices = endVertices(obj, varargin)
            vertices = obj.lookup1(class(Vertex), "vertex2_id", "vertex_id", varargin{:});
        end
        
        function vertices = vertices(obj, varargin)
            if length(obj) ~= numel(obj)
                disp("multi-value lookup applied on a 2D matrix. This is illegal. Please flatten and re-apply.");
            end
            vertices = [reshape(obj.startVertices, [], 1), reshape(obj.endVertices, [], 1)];
        end
        
        function coords = coords(obj, varargin)
            coords = obj.bonds.coords(varargin{:});
        end
    end
end
classdef DBond < PhysicalEntity
    % DBOND A directed bond is a bond-like entity (that is, a line) with a direction.
    % Directed bonds are the basic units of the data, since they always
    % belong uniquely to one, and only one object.
    %   It is obvious that a DBond belongs to the Bond it shares coordinates
    %   with.
    %   DBond has two vertices, but its starting vertex is the one that
    %   counts (though we have a way to get the other one)
    %   Each DBond also points towards he next DBond, as they always form a
    %   cyclic list. This list of DBonds uniquely cover a single cell, to
    %   which this DBond belongs.
    % When implementing a lookup, make sure to first go here then get the
    % target entity for increased efficiency.
    properties
        % the ID of the frame this DBond exists in
        % type: int
        frame
        % the unique identifier of this DBond
        % type: int
        dbond_id
        % the ID of the cell this DBond creates a boundry for
        % type: int
        cell_id
        % the ID of the directed bond pointing the opposite direction and shares the same bond.
        % Note that this doesn't have to exist for edge dbonds, in which
        % case NaN will be returned.
        % type: int or NaN
        conj_dbond_id
        % the ID of the bond this DBond belongs to
        % type: int
        bond_id
        % the ID of the vertex this DBond starts from
        % type: int
        vertex_id
        % the ID of the vertex this DBond points to
        % type: int
        vertex2_id
        % the ID of the the DBond this DBond points to (it points to its base)
        % type: int
        left_dbond_id
    end
    
    methods
        
        function obj = DBond(varargin)
            % DBOND construct an array of DBonds. Nothing special.
            obj@PhysicalEntity(varargin)
        end

        function id = uniqueID(~)
            id = "dbond_id";
        end
        
        function logger = logger(~)
            logger = Logger('DBond');
        end
        
        function dbonds = conjugate(obj, varargin)
            % CONJUGATE calculates the DBOND pointing the opposite direction and shares the same bond for each entry in this array.
            % Note that this doesn't have to exist for edge dbonds, in which
            % case a NaN DBOND will be returned.
            % Parameters:
            %   varargin: additional MATLAB builtin operations to apply on
            %   the result.
            % Return type: DBOND[]
            dbonds = obj.lookup1(class(DBond), "conj_dbond_id", "dbond_id", varargin{:});
        end
        
        function dbonds = next(obj, varargin)
            % NEXT calculates the DBOND this DBOND points to (it points to its base) for each entry in this array.
            % Parameters:
            %   varargin: additional MATLAB builtin operations to apply on
            %   the result.
            % Return type: DBOND[]
            dbonds = obj.lookup1(class(DBond), "left_dbond_id", "dbond_id", varargin{:});
        end
        
        function cells = cells(obj, varargin)
            % CELLS calculates the cells each dbond in this array belongs to.
            % Parameters:
            %   varargin: additional MATLAB builtin operations to apply on
            %   the result.
            % Return type: CELL[]
            cells = obj.lookup1(class(Cell), "cell_id", "cell_id", varargin{:});
        end
        
        function bonds = bonds(obj, varargin)
            % BONDS calculates the bonds each dbond in this array belongs to.
            % Parameters:
            %   varargin: additional MATLAB builtin operations to apply on
            %   the result.
            % Return type: BOND[]
            bonds = obj.lookup1(class(Bond), "bond_id", "bond_id", varargin{:});
        end
        
        function vertices = startVertices(obj, varargin)
            % STARTVERTICES calculates the vertices each dbond in this array starts from.
            % Parameters:
            %   varargin: additional MATLAB builtin operations to apply on
            %   the result.
            % Return type: VERTEX[]
            vertices = obj.lookup1(class(Vertex), "vertex_id", "vertex_id", varargin{:});
        end
        
        function vertices = endVertices(obj, varargin)
            % ENDVERTICES calculates the vertices each dbond in this array points to.
            % Parameters:
            %   varargin: additional MATLAB builtin operations to apply on
            %   the result.
            % Return type: VERTEX[]
            vertices = obj.lookup1(class(Vertex), "vertex2_id", "vertex_id", varargin{:});
        end
        
        function vertices = vertices(obj, varargin)
            % VERTICES calculates the vertices each dbond in this array touches.
            % Parameters:
            %   varargin: additional MATLAB builtin operations to apply on
            %   the result.
            % Return type: VERTEX[]
            if length(obj) ~= numel(obj)
                disp("multi-value lookup applied on a 2D matrix. This is illegal. Please flatten and re-apply.");
            end
            vertices = [reshape(obj.startVertices, [], 1), reshape(obj.endVertices, [], 1)];
        end
        
        function coords = coords(obj, varargin)
            % CONJUGATE calculates the pixel positions each dbond in this array goes through
            % At the moment, this does not rotate them to match the
            % direction, but this is a good future implementation.
            % Parameters:
            %   varargin: additional MATLAB builtin operations to apply on
            %   the result.
            % Return type: BONDPIXELLIST[]
            coords = obj.bonds.coords(varargin{:});
        end
    end
end
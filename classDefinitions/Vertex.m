classdef Vertex < PhysicalEntity
    % VERTEX A point on the graph that represents one of the edges of a bond.
    % Vertices acts as the oundray both between 3 cells or more, or between 3
    % bonds (or dbonds) or more.
    % At the end of the day, this is just a physical point.
    properties
        % the ID of the frame this Vertex exists in
        % type: int
        frame
        % the unique identifier of this entity
        % type: int
        vertex_id
        % the pixel X coordinate of the vertex in the image
        x_pos
        % the pixel Y coordinate of the vertex in the image
        y_pos
        % the pixel Z coordinate of the vertex in the image
        z_pos
        % An internal vairblae listing the cells this bond is a border of.
        % you can access this using VERTEX#CELLS
        % type: CELL[]
        cells_ = Null.null;
    end
    
    methods
        
        function obj = Vertex(varargin)
            % VERTEX construct an array of Vertexes. Nothing special.
            obj@PhysicalEntity(varargin)
        end

        function id = uniqueID(~)
            id = "vertex_id";
        end
        
        function logger = logger(~)
            logger = Logger('Vertex');
        end
        
        function vertices = vertices(obj, varargin)
            % VERTICES the identity function
            % Parameters:
            %   varargin: additional MATLAB builtin operations to apply on
            %   the result.
            % Return type: VERTEX[]
            vertices = obj(varargin{:});
        end
        
        function bonds = bonds(obj, varargin)
            % BONDS calculates the bonds each vertex in this array touches.
            % Parameters:
            %   varargin: additional MATLAB builtin operations to apply on
            %   the result.
            % Return type: BOND[]
            
            % the relevant DBonds here are both those that start from here
            % and those that point to it.
            dbonds = [obj.dBonds, obj.lookupMany(class(DBond), "vertex_id", "vertex2_id")];
            bonds = dbonds.bonds;
            % unique value filtering
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
        
        function cells = calculateCells(obj, varargin)
            % CELLS calculates the cells each vertex in this array touches.
            % Parameters:
            %   varargin: additional MATLAB builtin operations to apply on
            %   the result.
            % Return type: CELL[]
            
            % the relevant DBonds here are both those that start from here
            % and those that point to it.
            dbonds = [obj.dBonds, obj.lookupMany(class(DBond), "vertex_id", "vertex2_id")];
            cells = dbonds.cells;
            % unique value filtering
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

         function cells = cells(obj, varargin)
            % CELLS calculates the cells each vertex in this array touches.
            % Parameters:
            %   varargin: additional MATLAB builtin operations to apply on
            %   the result.
            % Return type: CELL[]
            cells = obj.getOrCalculate(class(Cell), "cells_", @(vertices) vertices.calculateCells, varargin{:});

         end
        
        function is_edge = is_edge(obj)
            % Find whether the bond is on the edge of the image by checking
            % that all cells that involve this bond are on the edge.
            obj = flatten(obj);
            obj.cells;
            is_edge = arrayfun(@(arr) prod([arr.cells.is_edge],'all',"omitnan"),obj);
        end

        
        function plot_pixels = plot_pixels(obj)
            plot_pixels = {};
            obj = flatten(obj);
            for i=1:length(obj)
                plot_pixels{i} = [obj(i).x_pos,obj(i).y_pos];
            end
        end
        
        function list_pixels = list_pixels(obj)
            list_pixels = [];
            obj = flatten(obj);
            list_pixels(:,1) = [obj.x_pos];
            list_pixels(:,2) = [obj.y_pos];
          %  list_pixels(:,3) = [obj.z_pos];

        end
        
    end
    
end
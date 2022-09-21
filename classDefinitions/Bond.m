classdef Bond < PhysicalEntity
    % BOND Defines a border between two cells. Has 2 edges, which are
    % vertices.
    % Various physical phenomena happen on these bonds, making them
    % intresting to study.
    % Bonds are the only gateway to the physical pixels of the frame, and
    % all other functions go through it.
    properties
        % the ID of the frame this BOND exists in
        % type: int
        frame
        % the unique identifier of this BOND
        % type: int
        bond_id
        % the geometrically corrected and smoothened length of the bond 
        % type: double
        bond_length
        % the list of pixels this bond resides in, under any projection.
        % type: BondPixelList
        pixel_list
        % an internal value defining how sure we are this bond really exists.
        % you can access this using BOND#CONFIDENCE
        % values over 0.5 yield confidence the bond exists, while lower
        % values indicate uncertainty for the bond.
        % type: double (0.0-1.0)
        confidence_
        % An internal vairblae listing the cells this bond is a border of.
        % you can access this using BOND#CELLS
        % type: CELL[]
        cells_
    end
    
    methods
        
        
        function obj = Bond(varargin)
            % BOND Constructs an array of bonds.
            % This includes NaNs for any calculated value so things don't
            % mess up in array calculations.
            obj@PhysicalEntity([varargin(:)', {'bond_length'}, {nan}])
        end

        function id = uniqueID(~)
            id = "bond_id";
        end
        
        function conf = confidence(obj, varargin)
            % CONFIDENCE for automatically segmented images, this value estimates how sure we are this bond really exists.
            % values over 0.5 yield confidence the bond exists, while lower
            % values indicate uncertainty for the bond.
            % Parameters:
            %   varargin: additional MATLAB builtin operations to apply on
            %   the result.
            % Return type: double[]
            conf = obj.getOrCalculate('double', "confidence_", @calcConfidence, varargin{:});
        end
        
        function bonds = bonds(obj, varargin)
            % BONDS the identity function
            % Parameters:
            %   varargin: additional MATLAB builtin operations to apply on
            %   the result.
            % Return type: BOND[]
            bonds = obj(varargin{:});
        end
        
        function vertices = vertices(obj, varargin)
            % VERTICES calculates the vertices each bond in this array touches.
            % Parameters:
            %   varargin: additional MATLAB builtin operations to apply on
            %   the result.
            % Return type: VERTEX[]
        	vertices = obj.dBonds.vertices(varargin{:});
        end

        function cells = cells(obj, varargin)
            % CELLS calculates the cells each bond in this array borders.
            % This can be either 1 or 2 cells per bond.
            % Parameters:
            %   varargin: additional MATLAB builtin operations to apply on
            %   the result.
            % Return type: CELL[]
            cells = obj.getOrCalculate(class(Cell), "cells_", @(bonds) bonds.dBonds.cells, varargin{:});
        end

        function coords = coords(obj, varargin)
            % COORDS gets the pixel list each bond in this array resides in.
            % Parameters:
            %   varargin: additional MATLAB builtin operations to apply on
            %   the result.
            % Return type: BONDPIXELLIST[]
            clazz = class(BondPixelList);
            coords = obj.getOrCalculate(clazz, "pixel_list", ...
                @(bond_arr) bond_arr.lookup1(clazz, "bond_id", "pixel_bondID"), varargin{:});
        end
        
        function plot_pixels = plot_pixels(obj)
            plot_pixels = {};
            obj = flatten(obj);
            coords = obj.coords;
            for i=1:length(coords)
                plot_pixels{i} = [coords(i).orig_x_coord,coords(i).orig_y_coord];
            end
        end
        
        function list_pixels = list_pixels(obj)
            list_pixels = [];
            obj = flatten(obj);
            coords = obj.coords;
            for i=1:length(obj)
                x_pixels = [coords(i).orig_x_coord];
                y_pixels = [coords(i).orig_y_coord];
                if (~isempty(x_pixels)&& ~isempty(y_pixels))
                    list_pixels(i,1) = x_pixels(round(length(x_pixels)/2));
                    list_pixels(i,2) = y_pixels(round(length(y_pixels)/2));
                else
                    list_pixels(i,1) = NaN;
                    list_pixels(i,2) = NaN;
                end
            end
        end
        
    end
    
    methods (Access = private)
        function conf = calcConfidence(obj)
            c = obj.flatten.cells;
            conf = geomean(reshape([c.confidence], size(c)), 2, 'omitnan');
            conf = reshape(conf, size(obj));
        end
    end
    
end
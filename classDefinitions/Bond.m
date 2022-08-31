classdef Bond < PhysicalEntity
    properties
        frame
        bond_id
        bond_length
        pixel_list
        confidence_
    end
    
    methods
        
        
        function obj = Bond(varargin)
            obj@PhysicalEntity(varargin)
            % no need to set pixel list since it is [] by default
        end

        function id = uniqueID(~)
            id = "bond_id";
        end
        
        function conf = confidence(obj, varargin)
            conf = obj.getOrCalculate('double', "confidence_", @calcConfidence, varargin{:});
        end
        
        function bonds = bonds(obj, varargin)
            bonds = obj(varargin{:});
        end
        
        function vertices = vertices(obj, varargin)
        	vertices = obj.dBonds.vertices(varargin{:});
        end

        function cells = cells(obj, varargin)
            cells = obj.dBonds.cells(varargin{:});
        end

        function coords = coords(obj, varargin)
            clazz = class(BondPixelList);
            coords = obj.getOrCalculate(clazz, "pixel_list", ...
                @(bond_arr) bond_arr.lookup1(clazz, "bond_id", "pixel_bondID"), varargin{:});
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
classdef Frame < PhysicalEntity
    properties
        frame
        frame_name
        time_sec
        mask_
    end
    
    methods

        function obj = Frame(varargin)
            obj@PhysicalEntity(varargin)
        end

        function id = uniqueID(~)
            id = "frame";
        end
        
        function masks = mask(obj)
            % load masks for frames that did not load them
            frames_to_load = obj(cellfun(@isempty, {obj.mask_}));
            for entity = frames_to_load
                entity.mask_ = entity.experiment.imread(['..\Display\Masks\', entity.frame_name, '.tiff']) > 0;
            end
            masks = [obj.mask_];
        end
        
        function cells = cells(obj, varargin)
            cells = obj.lookupByFrame(class(Cell), varargin);
        end
        
        function bonds = bonds(obj, varargin)
            bonds = obj.lookupByFrame(class(Bond), varargin);
        end
        
        function vertices = vertices(obj, varargin)
            vertices = obj.lookupByFrame(class(Vertex), varargin);
        end
    end
    
    methods(Access = protected)
        function phys_arr = lookupByFrame(obj, clazz, varargin)
            if length(obj) ~= numel(obj)
                disp("multi-value lookup applied on a 2D matrix. This is illegal. Please flatten and re-apply.");
            end
            index = containers.Map;
            lookup_result = cell(size(obj));
            for lookup_idx = 1:numel(obj)
                entity = obj(lookup_idx);
                if isnan(entity)
                    continue;
                end
                map_key = entity.experiment.folder_;
                if ~index.isKey(map_key)
                    full_phys = entity.experiment.lookup(clazz);
                    index(map_key) = full_phys;
                end
                lookup_result{lookup_idx} = full_phys([full_phys.(full_phys.frameID)] == entity.frame);
            end
            sizes = cellfun(@(result) (length(result)), lookup_result);
            phys_arr(length(obj), max(sizes)) = feval(clazz);
            for i=1:length(obj)
                phys_arr(i, 1:sizes(i)) = lookup_result{i};
            end
            % filter result and put it into result_arr
            if nargin > 4
                phys_arr = phys_arr(varargin{:});
            end
        end
    end
    
end
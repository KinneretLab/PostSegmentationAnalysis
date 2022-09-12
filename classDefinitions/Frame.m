classdef Frame < PhysicalEntity
    % FRAME A physical representation of a picture in its entirety
    % the frame is the big container unit which physically holds all other
    % other physical things, like cells, bonds, defects, etc.
    properties
        % the identifier of the frame. This is unique per experiment.
        % type: int
        frame
        % the filesystem name of the frame. 
        % To be used when looking for files related to this frame.
        % type: char[]
        frame_name
        % the time since the start of the experiment the frame was captured.
        % type: double
        time_sec
        % internal parameter holding the mask image.
        % type: boolean[]
        mask_
    end
    
    methods

        function obj = Frame(varargin)
            % FRAME Constructs a frame. Nothing special here.
            obj@PhysicalEntity(varargin)
        end

        function id = uniqueID(~)
            id = "frame";
        end
        
        function masks = mask(obj, varargin)
            % MASKS load the mask images per frame in the array.
            % A mask is a binary matrix such that 1 indicated the HYDRA
            % occupies this pixel, and 0 if nothing is there.
            % Parameters:
            %   varargin: additional MATLAB builtin operations to apply on
            %   the result.
            % Return type: boolean[][]
            frames_to_load = obj(cellfun(@isempty, {obj.mask_}));
            for entity = frames_to_load
                % use the experiment object to get the image files, and
                % save them in the frame.
                entity.mask_ = entity.experiment.imread(['..\Display\Masks\', entity.frame_name, '.tiff']) > 0;
            end
            masks = [obj.mask_];
            if nargin > 1
                masks = masks(varargin{:});
            end
        end
        
        function cells = cells(obj, varargin)
            % CELLS searches for the cells contained in each frame in this array.
            % Parameters:
            %   varargin: additional MATLAB builtin operations to apply on
            %   the result.
            % Return type: CELL[]
            cells = obj.lookupByFrame(class(Cell), varargin);
        end
        
        function bonds = bonds(obj, varargin)
            % BONDS searches for the bonds contained in each frame in this array.
            % Parameters:
            %   varargin: additional MATLAB builtin operations to apply on
            %   the result.
            % Return type: BOND[]
            bonds = obj.lookupByFrame(class(Bond), varargin);
        end
        
        function vertices = vertices(obj, varargin)
            % VERTICES searches for the vertices contained in each frame in this array.
            % Parameters:
            %   varargin: additional MATLAB builtin operations to apply on
            %   the result.
            % Return type: VERTEX[]
            vertices = obj.lookupByFrame(class(Vertex), varargin);
        end
    end
    
    methods(Access = protected)
        function phys_arr = lookupByFrame(obj, clazz, varargin)
            % LOOKUPBYFRAME A utility function that searches for the entities contained in each frame in this array.
            % Its basically just LOOKUPMANY but with parts trimmed off for
            % efficiency because the index is the same as the requester
            % object.
            % Parameters:
            %   obj (caller):
            %      the frame array which requests the search.
            %   clazz: string
            %      the class name of the object type you are looking for
            %   varargin: additional MATLAB builtin operations to apply on
            %   the result.
            % Return type: clazz[]
            if length(obj) ~= numel(obj)
                disp("multi-value lookup applied on a 2D matrix. This is illegal. Please flatten and re-apply.");
            end
            index = containers.Map;
            lookup_result = cell(size(obj));
            for lookup_idx = 1:numel(obj)
                entity = obj(lookup_idx);
                % skip NaNs
                if isnan(entity)
                    continue;
                end
                % to increase efficiency, we sort the search targets by
                % experiment (for some reason this is more efficient, MATLAB is weird).
                map_key = entity.experiment.folder_;
                if ~index.isKey(map_key)
                    % if the map is not aware of the frame, index the
                    % experiment
                    full_phys = entity.experiment.lookup(clazz);
                    index(map_key) = full_phys;
                end
                % run actual search on the relevant experiment
                lookup_result{lookup_idx} = full_phys([full_phys.(full_phys.frameID)] == entity.frame);
            end
            % since the lookup was placed into a cell array, we need to
            % reshape it into a matrix.
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
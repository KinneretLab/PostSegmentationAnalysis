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
        % was the cell segmentation verified by a qualified reviewer? true
        % if it was validated, false otherwise.
        verified_segmentation
        % internal parameter holding the mask image.
        % type: boolean[]
        mask_
        % An internal vairblae listing the cells this frame contains.
        % you can access this using FRAME#CELLS
        % type: CELL[]
        cells_ = Null.null;
        % An internal vairblae listing the bonds this frame contains.
        % you can access this using FRAME#BONDS
        % type: BOND[]
        bonds_ = Null.null;
        % An internal vairblae listing the vertices this frame contains.
        % you can access this using FRAME#VERTICES
        % type: VERTEX[]
        vertices_ = Null.null;
        % An internal vairblae listing the true vertices this frame contains.
        % you can access this using FRAME#TVERTICES
        % type: TRUEVERTEX[]
        t_vertices_ = Null.null;
        % An internal vairblae listing the regions this frame contains.
        % you can access this using FRAME#REGIONS
        % type: MARKEDREGION[]
        regions_ = Null.null;
        % An internal vairblae listing the defects this frame contains.
        % you can access this using FRAME#DEFECTS
        % type: DEFECT[]
        defects_ = Null.null;
        % An internal vairblae listing the defects this frame contains.
        % you can access this using FRAME#CELLPAIRS
        % type: CELLPAIRS[]
        cell_pairs_ = Null.null;

    end
    
    methods

        function obj = Frame(varargin)
            % FRAME Constructs a frame. Nothing special here.
            obj@PhysicalEntity(varargin)
        end

        function id = uniqueID(~)
            id = "frame";
        end
        
        function logger = logger(~)
            logger = Logger('Frame');
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
            cells = obj.getOrCalculate(class(Cell), "cells_", @(frames) frames.lookupByFrame(class(Cell)), varargin{:});
        end
        
        function bonds = bonds(obj, varargin)
            % BONDS searches for the bonds contained in each frame in this array.
            % Parameters:
            %   varargin: additional MATLAB builtin operations to apply on
            %   the result.
            % Return type: BOND[]
            bonds = obj.getOrCalculate(class(Bond), "bonds_", @(frames) frames.lookupByFrame(class(Bond)), varargin{:});
        end
        
        function vertices = vertices(obj, varargin)
            % VERTICES searches for the vertices contained in each frame in this array.
            % Parameters:
            %   varargin: additional MATLAB builtin operations to apply on
            %   the result.
            % Return type: VERTEX[]
            vertices = obj.getOrCalculate(class(Vertex), "vertices_", @(frames) frames.lookupByFrame(class(Vertex)), varargin{:});
        end

        function vertices = tVertices(obj, varargin)
            % TVERTICES searches for the true vertices contained in each frame in this array.
            % Parameters:
            %   varargin: additional MATLAB builtin operations to apply on
            %   the result.
            % Return type: TVERTEX[]
            vertices = obj.getOrCalculate(class(TrueVertex), "t_vertices_", @(frames) frames.lookupByFrame(class(TrueVertex)), varargin{:});
        end

        function vertices = regions(obj, varargin)
            % REGIONS searches for the marked regions (including mask) contained in each frame in this array.
            % Parameters:
            %   varargin: additional MATLAB builtin operations to apply on
            %   the result.
            % Return type: MARKEDREGION[]
            vertices = obj.getOrCalculate(class(MarkedRegion), "regions_", @(frames) frames.lookupByFrame(class(MarkedRegion)), varargin{:});
        end

        function defects = defects(obj, varargin)
            % DEFECTS searches for the defects contained in each frame in this array.
            % Parameters:
            %   varargin: additional MATLAB builtin operations to apply on
            %   the result.
            % Return type: DEFECT[]
            defects = obj.getOrCalculate(class(Defect), "defects_", @(frames) frames.lookupByFrame(class(Defect)), varargin{:});
        end

        function obj = cellPairsFrame(obj)
            % Run over frames individually:
            for i=1:length(obj)
                cells = obj(i).cells;
                obj(i).cell_pairs_ = cells.createNeihgborPairs;
            end
        end
        
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
                obj.logger.error("multi-value lookup applied on a 2D matrix. This is illegal. Please flatten and re-apply.");
            end
            index = containers.Map;
            lookup_result = cell(size(obj));
            for lookup_idx = 1:numel(obj)
                obj.logger.progress("Searching for %ss contained in the given Frames", lookup_idx, numel(obj), clazz);
                entity = obj(lookup_idx);
                % skip NaNs
                if isnan(entity)
                    continue;
                end
                % to increase efficiency, we sort the search targets by
                % frame.
                map_key = entity.experiment.uniqueName;
                full_map_key = map_key + ':' + entity.frame;
                if ~index.isKey(full_map_key)
                    % if the map is not aware of the frame, index the
                    % frame (and other frames in the experiment)
                    full_phys = entity.experiment.lookup(clazz);
                    frame_num = [full_phys.(full_phys.frameID)];
                    for frame_id=unique(frame_num)
                        index(map_key + ':' + frame_id) = full_phys(frame_num == frame_id);
                    end
                end
                % no need to actually look up anything, the index already
                % took care of that.
                if index.isKey(full_map_key)
                    lookup_result{lookup_idx} = index(full_map_key);
                else
                    lookup_result{lookup_idx} = [];
                end
            end
            % since the lookup was placed into a cell array, we need to
            % reshape it into a matrix.
            sizes = cellfun(@(result) (length(result)), lookup_result);
            if max(sizes) > 0
                phys_arr(length(obj), max(sizes)) = feval(clazz);
                for i=1:length(obj)
                    if sizes(i) > 0
                        phys_arr(i, 1:sizes(i)) = lookup_result{i};
                    end
                end
            else
                phys_arr = eval([clazz, '.empty(', num2str(length(obj)), ',0)']);
            end
            % filter result and put it into result_arr
            if nargin > 4
                phys_arr = phys_arr(varargin{:});
            end
        end
    end
    
end
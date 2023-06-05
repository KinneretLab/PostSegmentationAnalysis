classdef MarkedRegion < PhysicalEntity
    % MARKEDREGION is a region of tissue marked marked manually. Since we
    % solely detect them from the microscope, their raw form in on the 2D
    % (projected) plane.
    % Marked regions have two things that need to be considered:
    % 1. While marked regions ascosiate with a unique frame, nothing
    %    guarantees their existence, and these can be multiple regions
    %    within one frame as well.
    % 2. Since marked regions are baked on the tissue surface but detected
    %    in their projected form, it is possible for one marked region to
    %    be disjointed - that is, one MarkedRegion will contain multiple
    %    polygons.
    %
    % To get a MARKEDREGION:
    % - From Frame: frame.regions
    % - From Experiment: e.regions
    % Note how both of these do not contain path arguments. This is because
    % the region creationlooks up all of the region files in the experiment
    % folder automatically and indexes them for you. That way, you do not
    % need to worry about the filesystem.

    properties
        % the ID of the frame this TrueVertex exists in
        % type: int
        frame
        % the unique identifier of this entity
        % type: int
        region_id
        % the raw image itself, containing flags on which pixels within the
        % projected 2D space belong to the region or not.
        % type: logical[][]
        raw
        % the type, or uniquely designated name, of the marked region.
        % This will be the name of the folder that directly contains the
        % region images
        % type: string (NOT char[]!)
        type
        % the total area, in pixels, of the region.
        % type: int
        area

        % List of all pixels within the area of the 2D projected region
        % type: int[][2]
        plot_pixels_
        % List of all pixels within the circumference of the 2D projected region
        % type: int[][2]
        list_pixels_

        % a map from the class name of the physical entity to a list of % coverages
        % of the corresponing physical entity with the order indiced by FRAME#LOOKUPBYFRAME
        % this list is used to filter out cells based on their coverage
        % criterion.
        % type: Map(string -> float[])
        coverages_
    end

    methods(Static, Access=protected)
        function out = criterion_(num)
            persistent filter_criterion_;
            if nargin
                filter_criterion_ = num;
            end
            if isempty(filter_criterion_)
                filter_criterion_ = 0.5;
            end
            out = filter_criterion_;
        end

        function out = lookup_folder_(path)
            persistent filter_criterion_;
            if nargin
                filter_criterion_ = path;
            end
            if isempty(filter_criterion_)
                filter_criterion_ = "regionMasks";
            end
            out = filter_criterion_;
        end
    end

    methods(Static)
        function setCoverageCriterion(num)
            if nargin == 0
                MarkedRegion.criterion_(0.5);
            else
                if 0 <= num && num <= 1
                    MarkedRegion.criterion_(num);
                end
            end
        end

        function setLookupDirectory(path)
            if nargin == 0
                MarkedRegion.lookup_folder_("regionMasks");
            else
                MarkedRegion.lookup_folder_(path);
            end
        end
    end

    methods
        function obj = MarkedRegion(experiment, varargin)
            obj@PhysicalEntity({});
            if nargin > 0
                % prepare iteration, and get size of array.
                frames = experiment.frames;
                directories = experiment.dir(MarkedRegion.lookup_folder_);
                % special case - prepend the mask directory for iteration
                mask_directory = experiment.dir("..\Display");
                mask_directory = mask_directory(string({mask_directory.name}) == "Masks");
                directories = [mask_directory, directories];

                obj(1, length(frames) * length(directories)) = MarkedRegion;
                % set experiment
                [obj.experiment] = deal(experiment);
                % iterate over files and load files in
                i = 1;
                for frame = frames
                    j = 1;
                    for directory = directories
                        obj(i).type = string(directory.name);
                        obj(i).raw = imread([directory.folder, '\', directory.name]) > 0;
                        obj(i).frame = frame.frame; % if Frame is ever directly stored, you can do `.frame_ = frame` to do the job.
                        obj(i).area = sum(obj(i).raw, 'all');
                        obj(i).region_id = uniqueID(frame.frame, j);

                        [frame_x, frame_y] = meshgrid(1:size(obj(i).raw, 1), 1:size(obj(i).raw));
                        obj(i).plot_pixels(:, 1) = frame_x(obj(i).raw);
                        obj(i).plot_pixels(:, 2) = frame_y(obj(i).raw);
                        outline = img - imerode(img, strel("disk",1));
                        obj(i).list_pixels(:, 1) = frame_x(outline);
                        obj(i).list_pixels(:, 2) = frame_y(outline);
                        j = j + 1;
                        i = i + 1;
                    end
                end
            end
        end

        function id = uniqueID(~)
            id = "region_id";
        end

        function logger = logger(~)
            logger = Logger('MarkedRegion');
        end
        
        function n = nargs(~)
            n = 0;
        end

        function phys_arr = lookup(obj, clazz, varargin)
            index_flag = arrayfun(@(entity) ~isnan(entity) & Null.isNull(entity.coverages_(clazz)), obj);
            obj_to_index = obj(index_flag);
            if ~isempty(obj_to_index)
                obj.logger.info("Calculating %s coverages for %d marked regions", clazz, length(obj_to_index))
                % this retrieves a cell array, with each entry containing the 
                % coordinates of the pixels. 
                % Cell degrees of freedom: region,cell_in_frame (1D)
                % Array degrees of freedom D1:pixel,D2:dimension
                phys_candidates = obj_to_index.frames.lookupByFrame(clazz);
                phys_pixels = reshape(phys_candidates.plot_pixels, size(phys_candidates));
                % as a result of the cellfun, the cell array turns into an
                % array with 2D containing the coverages:
                % D1:region, D2: entity in frame
                obj_mat = repmat(obj_to_index', [1, size(phys_pixels, 2)]);
                coverages = cellfun(@getCoverage, obj_mat, phys_pixels);
                obj.logger.debug("All coverages calculated, saving as properties...")
                for region_idx=1:length(obj_to_index)
                    % save the found coverages in the corresponding place.
                    % implementation note: this trims trailing NaNs, so
                    % this might end up shorter than the #entities in the
                    % frame
                    coverages_row = coverages(region_idx, :);
                    obj_to_index(region_idx).coverages_(clazz) = coverages_row(1:find(~isnan(coverages_row, 1, 'last')));
                end
            else
                phys_arr = eval([clazz, '.empty(', num2str(length(obj)), ',0)']);
            end
            candidates = obj.flatten.frames.lookupByFrame(clazz);
             % collect all the properties of the object into a tight matrix.
            sizes = arrayfun(@(entity) sum(entity.coverages_(clazz) >= entity.criterion_), obj);
            phys_arr(numel(obj), max(sizes, [], 'all')) = feval(clazz);
            for i=1:numel(obj)
                if sizes(i) > 0
                    phys_arr(i, 1:sizes(i)) = candidates(i,obj(i).coverages_(clazz) >= obj(i).criterion_);
                end
            end
            
            % filter result and put it into result_arr
            if ~isempty(varargin)
                phys_arr = phys_arr(varargin{:});
            end
            % Remove dimensions of size 1
            phys_arr = squeeze(phys_arr); 
        end

        function cells = cells(obj, varargin)
            cells = obj.lookup(class(Cell), varargin{:});
        end

        function bonds = bonds(obj, varargin)
            bonds = obj.lookup(class(Bond), varargin{:});
        end

        function vertices = vertices(obj, varargin)
            vertices = obj.lookup(class(Vertex), varargin{:});
        end

        function defects = defects(obj, varargin)
            defects = obj.lookup(class(Defect), varargin{:});
        end

        function tVertices = tVertices(obj, varargin)
            tVertices = obj.lookup(class(TrueVertex), varargin{:});
        end

        function plot_pixels = plot_pixels(obj)
            plot_pixels = {obj.plot_pixels_};
        end

        function list_pixels = list_pixels(obj)
            list_pixels = {obj.list_pixels_};
        end
    end

    methods(Access=private, Static)
        function result = getCoverage(obj, phys_pixels)
            % get the pixel count occupied by the physical entity
            phys_area = sum(~isnan(phys_pixels),1);
            if phys_area > 0 % just a slightly faster methodology to reach the same conclusion.
                % examine the pixels of each entity to check how many are
                % within the region, then count them.
                covered_area = sum(ismember(phys_pixels, obj.plot_pixels, 'rows'));
                result = covered_area/phys_area;
            else
                result = nan;
            end
        end
    end
end


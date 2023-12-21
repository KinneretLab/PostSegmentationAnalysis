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
    % What can you do with a MARKEDREGION?
    % - draw it using imshow(MARKEDREGION#raw)
    % - obtain cells,bonds,etc. contained within the region using
    %   MARKEDREGION#CELLS, MARKEDREGION#BONDS, etc.
    % Useful properties:
    % - the first region in each frame is the frame mask, that is,
    %   frame.regions(1) will give you the entire frame mask.
    %   You can also get it without indices using frame.regions([frame.regions.type] == "Mask")
    % - to obtain a particular type of marked regions, you can use the
    %   "type" property, which stores the name of the directory containing
    %   the original region image. For example, if this directory is called
    %   "pink", then you can obtain all of its regions using
    %   experiment.regions([experiment.regions.type] == "pink")
    % - when running a lookup function like MARKEDREGION#CELLS, the object
    %   stored the result, so the next lookup is much more efficient, even
    %   when changing the criterion (for into on this criterion read MARKEDREGION#LOOKUP)

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
                filter_criterion_ = "RegionMasks";
            end
            out = filter_criterion_;
        end

        function result = getCoverage(obj, phys_pixels)
            phys_pixels = phys_pixels{1};
            if ~isempty(phys_pixels)
                % get the pixel count occupied by the physical entity
                phys_area = sum(~isnan(phys_pixels(:,1)));
                % examine the pixels of each entity to check how many are
                % within the region, then count them.
                covered_area = sum(ismember(phys_pixels, obj.plot_pixels{1}, 'rows'));
                result = covered_area/phys_area;
            else
                result = nan;
            end
        end
    end

    methods(Static)
        function setCoverageCriterion(num)
            % SETCOVERAGECRITERION sets the minimum coverage needed for the
            % physical entity to be considered "in the region". Coverage is
            % the % pixels within the physical entity that are on or in the
            % marked region.
            % Parameters:
            %     num: float
            %         Default: 0.5
            %         allowed: 0-1 (inclusive)
            %         the criterion to set
            if nargin == 0
                MarkedRegion.criterion_(0.5);
            else
                if 0 <= num && num <= 1
                    MarkedRegion.criterion_(num);
                end
            end
        end

        function setLookupDirectory(path)
            % SETLOOKUPDIRECTORY change the location relative to the cell
            % directory where region masks should be searched for. This
            % will not alter the default location to search for the frame
            % masks.
            % Note that changing this has a permanent effect on the
            % loaded experiment (as the loaded regions are saved), which
            % can only be altered by deleting the experiment and starting
            % over.
            % it is advised not to change this.
            % Parameters:
            %     path: string|char[]
            %         Default: RegionMasks
            %         the relative path from the experiment root to the
            %         folder containing the region masks.
            if nargin == 0
                MarkedRegion.lookup_folder_("RegionMasks");
            else
                MarkedRegion.lookup_folder_(string(path));
            end
        end
    end

    methods
        function obj = MarkedRegion(experiment, varargin)
            % MARKEDREGION construct an array of marked regions for the entire experiment.
            % Since this is a calculated physical entity, it manually
            % calculates the neccesary properties.
            % Global Parameters:
            %   lookup directory (MarkedRegion.lookupDirectory):
            %   string (path)
            %      the location relative to the cell
            %      directory where region masks should be searched for.
            %      This will not alter the default location to search for
            %      the frame masks. This paramter CANNOT be dynamically
            %      changed, that is
            %      ```
            %      MarkedRegion.setLookupPath("mySpecialPath");
            %      a = experiment.regions;
            %      MarkedRegion.setLookupPath;
            %      b = experiment.regions;
            %      ```
            %      will have different values for a,b depending on order.
            %      Only a's results are reliable in this scenario.
            %      default: "RegionMasks"
            % Return type: CELL[]
            obj@PhysicalEntity({});
            if nargin > 0
                % prepare iteration, and get size of array.
                frames = experiment.frames;
                directories = experiment.dir(MarkedRegion.lookup_folder_);
                % special case - prepend the mask directory for iteration
                mask_directory = experiment.dir("..\Display");
                mask_directory = mask_directory(string({mask_directory.name}) == "Masks");
                directories = [mask_directory, directories'];

                obj(1, length(frames) * length(directories)) = MarkedRegion;
                % set experiment
                [obj.experiment] = deal(experiment);
                % iterate over files and load files in
                i = 1;
                for frame = frames
                    j = 1;
                    for directory = directories
                        full_path = [directory.folder, '\', directory.name ,'\', frame.frame_name, '.tiff'];
                        if isfile(full_path)
                            obj(i).type = string(directory.name);
                            obj(i).raw = imread(full_path) > 0;
                            obj(i).frame = frame.frame; % if Frame is ever directly stored, you can do `.frame_ = frame` to do the job.
                            obj(i).area = sum(obj(i).raw, 'all');
                            obj(i).region_id = uniqueID(frame.frame, j);
                            obj(i).coverages_ = containers.Map;
    
                            [frame_x, frame_y] = meshgrid(1:size(obj(i).raw, 1), 1:size(obj(i).raw));
                            obj(i).plot_pixels_(:, 1) = frame_x(obj(i).raw);
                            obj(i).plot_pixels_(:, 2) = frame_y(obj(i).raw);
                            % by default this sorts the pixels by conectivity. Note that discontinuous boundaries are atill an issue.
                            outline = bwboundaries(obj(i).raw);
                            obj(i).list_pixels_ = vertcat(fliplr(outline{:}));
                        end
                        j = j + 1;
                        i = i + 1;
                    end
                end
                obj(isnan(obj)) = [];
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
            % LOOKUP Searches for all physical entities of a particular
            % type that can be found within (either partially or
            % completely) within the marked region. The specifics are
            % determined by a user configurable parameter, the coverage
            % criterion.
            % Parameters:
            %   obj (caller):
            %      the object which requests the search.
            %   clazz: string
            %      the class name of the object type you are looking for
            %   varargin: additional MATLAB builtin operations to apply on
            %   the result.
            % Global Parameters:
            %   coverage criterion (MarkedRegion.setCoverageCriterion):
            %   float
            %      the minimum % pixels of the physical entity that are
            %      either in or on (so edge inclusive) the marked region in
            %      question. Physical entities that do not satisfy this
            %      will be filtered out and not returned in the list. This
            %      paramter can be dynamically changed, that is
            %      ```
            %      MarkedRegion.setCoverageCriterion(1);
            %      a = region.lookup(...);
            %      MarkedRegion.setCoverageCriterion(0.5);
            %      b = region.lookup(...);
            %      ```
            %      will have a,b remain the same regardless of order.
            %      default: 0.5
            % Return type: clazz[]
            index_flag = arrayfun(@(entity) ~isnan(entity) & ~entity.coverages_.isKey(clazz), obj);
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
                coverages = arrayfun(@MarkedRegion.getCoverage, obj_mat, phys_pixels);
                obj.logger.debug("All coverages calculated, saving as properties...")
                for region_idx=1:length(obj_to_index)
                    % save the found coverages in the corresponding place.
                    % implementation note: this trims trailing NaNs, so
                    % this might end up shorter than the #entities in the
                    % frame
                    coverages_row = coverages(region_idx, :);
                    obj_to_index(region_idx).coverages_(clazz) = coverages_row(1:find(~isnan(coverages_row), 1, 'last'));
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
            % CELLS Searches for all cells
            % that can be found within (either partially or
            % completely) within the marked region. The specifics are
            % determined by a user configurable parameter, the coverage
            % criterion.
            % Parameters:
            %   obj (caller):
            %      the object which requests the search.
            %   varargin: additional MATLAB builtin operations to apply on
            %   the result.
            % Global Parameters:
            %   coverage criterion (MarkedRegion.setCoverageCriterion):
            %   float
            %      the minimum % pixels of the physical entity that are
            %      either in or on (so edge inclusive) the marked region in
            %      question. Physical entities that do not satisfy this
            %      will be filtered out and not returned in the list. This
            %      paramter can be dynamically changed, that is
            %      ```
            %      MarkedRegion.setCoverageCriterion(1);
            %      a = region.lookup(...);
            %      MarkedRegion.setCoverageCriterion(0.5);
            %      b = region.lookup(...);
            %      ```
            %      will have a,b remain the same regardless of order.
            %      default: 0.5
            % Return type: CELL[]
            cells = obj.lookup(class(Cell), varargin{:});
        end

        function bonds = bonds(obj, varargin)
            % BONDS Searches for all bonds
            % that can be found within (either partially or
            % completely) within the marked region. The specifics are
            % determined by a user configurable parameter, the coverage
            % criterion.
            % Parameters:
            %   obj (caller):
            %      the object which requests the search.
            %   varargin: additional MATLAB builtin operations to apply on
            %   the result.
            % Global Parameters:
            %   coverage criterion (MarkedRegion.setCoverageCriterion):
            %   float
            %      the minimum % pixels of the physical entity that are
            %      either in or on (so edge inclusive) the marked region in
            %      question. Physical entities that do not satisfy this
            %      will be filtered out and not returned in the list. This
            %      paramter can be dynamically changed, that is
            %      ```
            %      MarkedRegion.setCoverageCriterion(1);
            %      a = region.lookup(...);
            %      MarkedRegion.setCoverageCriterion(0.5);
            %      b = region.lookup(...);
            %      ```
            %      will have a,b remain the same regardless of order.
            %      default: 0.5
            % Return type: CELL[]
            bonds = obj.lookup(class(Bond), varargin{:});
        end

        function vertices = vertices(obj, varargin)
            % VERTICES Searches for all vertices
            % that can be found within (either partially or
            % completely) within the marked region. The specifics are
            % determined by a user configurable parameter, the coverage
            % criterion.
            % Parameters:
            %   obj (caller):
            %      the object which requests the search.
            %   varargin: additional MATLAB builtin operations to apply on
            %   the result.
            % Global Parameters:
            %   coverage criterion (MarkedRegion.setCoverageCriterion):
            %   float
            %      the minimum % pixels of the physical entity that are
            %      either in or on (so edge inclusive) the marked region in
            %      question. Physical entities that do not satisfy this
            %      will be filtered out and not returned in the list. This
            %      paramter can be dynamically changed, that is
            %      ```
            %      MarkedRegion.setCoverageCriterion(1);
            %      a = region.lookup(...);
            %      MarkedRegion.setCoverageCriterion(0.5);
            %      b = region.lookup(...);
            %      ```
            %      will have a,b remain the same regardless of order.
            %      default: 0.5
            % Return type: CELL[]
            vertices = obj.lookup(class(Vertex), varargin{:});
        end

        function defects = defects(obj, varargin)
            % DEFECTS Searches for all defects
            % that can be found within (either partially or
            % completely) within the marked region. The specifics are
            % determined by a user configurable parameter, the coverage
            % criterion.
            % Parameters:
            %   obj (caller):
            %      the object which requests the search.
            %   varargin: additional MATLAB builtin operations to apply on
            %   the result.
            % Global Parameters:
            %   coverage criterion (MarkedRegion.setCoverageCriterion):
            %   float
            %      the minimum % pixels of the physical entity that are
            %      either in or on (so edge inclusive) the marked region in
            %      question. Physical entities that do not satisfy this
            %      will be filtered out and not returned in the list. This
            %      paramter can be dynamically changed, that is
            %      ```
            %      MarkedRegion.setCoverageCriterion(1);
            %      a = region.lookup(...);
            %      MarkedRegion.setCoverageCriterion(0.5);
            %      b = region.lookup(...);
            %      ```
            %      will have a,b remain the same regardless of order.
            %      default: 0.5
            % Return type: CELL[]
            defects = obj.lookup(class(Defect), varargin{:});
        end

        function tVertices = tVertices(obj, varargin)
            % TVERTICES Searches for all true vertices
            % that can be found within (either partially or
            % completely) within the marked region. The specifics are
            % determined by a user configurable parameter, the coverage
            % criterion.
            % Parameters:
            %   obj (caller):
            %      the object which requests the search.
            %   varargin: additional MATLAB builtin operations to apply on
            %   the result.
            % Global Parameters:
            %   coverage criterion (MarkedRegion.setCoverageCriterion):
            %   float
            %      the minimum % pixels of the physical entity that are
            %      either in or on (so edge inclusive) the marked region in
            %      question. Physical entities that do not satisfy this
            %      will be filtered out and not returned in the list. This
            %      paramter can be dynamically changed, that is
            %      ```
            %      MarkedRegion.setCoverageCriterion(1);
            %      a = region.lookup(...);
            %      MarkedRegion.setCoverageCriterion(0.5);
            %      b = region.lookup(...);
            %      ```
            %      will have a,b remain the same regardless of order.
            %      default: 0.5
            % Return type: CELL[]
            tVertices = obj.lookup(class(TrueVertex), varargin{:});
        end

        function plot_pixels = plot_pixels(obj)
            plot_pixels = {obj.plot_pixels_};
        end

        function list_pixels = list_pixels(obj)
            list_pixels = {obj.list_pixels_};
        end
    end
end


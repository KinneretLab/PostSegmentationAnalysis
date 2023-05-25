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
        plot_pixels
        % List of all pixels within the circumference of the 2D projected region
        % type: int[][2]
        list_pixels
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
        function setCriterion(num)
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
    end
end


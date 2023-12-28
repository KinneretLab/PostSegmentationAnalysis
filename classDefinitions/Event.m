classdef Event < PhysicalEntity
    % Event ???
    % write something about how event are non-positional
    properties
        % the unique identifier of this event, tracked through the movie
        % type: int
        event_id
        % the ID of the first frame this event is observed
        % type: int
        start_frame
        % the ID of the last frame this event is observed
        % type: int
        end_frame
        % the ID of the frame this event is observed at its highest intensity
        % type: int
        peak_frame
        % the type of event observed. The number is arbitrarily defined
        type
        % comment - basically free text on intresting remarks on the event
        comment

    end
    
    methods
        
        function obj = Event(varargin)
            % Event construct an array of Events. Nothing special.
            obj@PhysicalEntity(varargin)
        end

        function id = uniqueID(~)
            id = "event_id";
        end

        function frames = frame(obj)
            frames = reshape([obj.peak_frame], size(obj));
        end
        
        function logger = logger(~)
            logger = Logger('Event');
        end
        
        function frames = allFrames(obj, varargin)
            % allFrames calculates all the frames that contain this event
            % Parameters:
            %   varargin: additional MATLAB builtin operations to apply on
            %   the result.
            % Return type: FRAME[]
            if length(obj) ~= numel(obj)
                if length(size(obj)) > 3
                    obj.logger.error("multi-value lookup applied on a 3D matrix, when the max possible dimension is 3D.");
                else
                    obj.logger.warn("multi-value lookup applied on a 2D matrix. This might be an error. Consider flattening the matrix before.");
                end
            end
            lookup_result = cell(size(obj));
            if numel(obj) > 2
                index = containers.Map;
                for lookup_idx = 1:numel(obj)
                    obj.logger.progress("Searching for Frames contained in the Events", lookup_idx, numel(obj));
                    entity = obj(lookup_idx);
                    % skip NaNs
                    if isnan(entity)
                        continue;
                    end
                    % to increase efficiency, we sort the search targets by
                    % frame.
                    map_key = entity.experiment.uniqueName;
                    if ~index.isKey(map_key)
                        % if the map is not aware of the frame, index the
                        % frame (and other frames in the experiment)
                        index(map_key) = entity.experiment.frames;
                    end
                    % get all candidate results
                    if index.isKey(map_key)
                        target_frames = index(map_key);
                    else
                        target_frames = [];
                    end
                    % run actual search on them
                    lookup_result{lookup_idx} = target_frames(entity.start_frame <= [target_frames.frame] &...
                        [target_frames.frame] <= entity.end_frame);
                end
            else
                for lookup_idx = 1:numel(obj)
                    % if there arent many elements, use the implicit
                    % algorithm which just looks up stuff.
                    if isnan(obj(lookup_idx))
                        continue;
                    end
                    target_frames = obj(lookup_idx).experiment.frames;
                    lookup_result{lookup_idx} = target_frames([obj(lookup_idx).start_frame] <= [target_frames.frame] &...
                        [target_frames.frame] <= [obj(lookup_idx).start_frame]);
                end
            end
            % since the lookup was placed into a cell array, we need to
            % reshape it into a matrix.
            sizes = cellfun(@(result) (length(result)), lookup_result);
            if max(sizes) > 0
                frames(numel(obj), max(sizes)) = Frame;
                for i=1:numel(obj)
                    if sizes(i) > 0
                        frames(i, 1:sizes(i)) = lookup_result{i};
                    end
                end
            else
                frames = Frame.empty(length(obj),0);
            end
            if length(obj) ~= numel(obj)
                % reorganize the 2D array into a 3D array
                size_obj = num2cell(size(obj));
                frames = reshape(frames, size_obj{:}, []);
            end
            % filter result and put it into the result frame list
            if nargin > 1
                frames = frames(varargin{:});
            end
        end
        
    end
    
end
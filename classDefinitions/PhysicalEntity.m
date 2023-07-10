classdef (Abstract) PhysicalEntity < handle
    % PHYSICALENTITY An abstract representation of objects that can be looked up.
    % If a class is an instance if a physical entity, this gauarantees:
    % 1. It has a parent EXPERIMENT that is directly responsible for
    %    managing it.
    % 2. It can be directly pointed to, that is, it uniquely identifies a
    %    group of pixels in one image.
    % 3. The object only exists in one single image, called a FRAME.
    % 4. This object is indexible, that is, it has a unique identitifier
    %    that differentiates it from other entities of the same type.
    % As a result, physical entities have several built-in features that
    % make it easy easy to work with them. Classes of this type are the
    % base unit to be used with the derivatives of FIGUREBUILDER.
    
    properties
        % the parent experiment, or daatabase, this entity was created by.
        % type: EXPERIMENT
        experiment
    end

    methods (Abstract)
        % UNIQUEID The name of the property of the class that represents the unique identifier of the entity
        % this method must be implemented by derivative classes. Very
        % useful for buildin implementations of lookups, comparisons, etc.
        % Parameters: none.
        % Returns: string
        %   the name of the unique identifier property. You can get the
        %   unique ID of a particular entity using the code
        %   <code>physical_entity.(physical_entity.uniqueID)</code>
        uniqueID(obj)
        
        logger(obj)

    end
    
    methods
        function obj = PhysicalEntity(args)
            % PHYSICALENTITY Construct an array of physical entities.
            % You should not use this method. only the derivaed classes
            % should use this method using
            % <code>obj@PhysicalEntity(varargin)</code>
            % Parameters: varargin
            %   1: experiment (required). This is the parent experiment
            %   that created this object.
            %   2: table (required). This is the source table used to write
            %   data into the result entities. The entire table should be
            %   fed in as this method specializes in bulk operations.
            %   3+: key-value pairs. You can set custom defaults for
            %   properties using the other input args. For example,
            %   <code>obj@PhysicalEntity(experiment, table, 'confidence', nan)</code>
            %   sets entity.confidence = nan for each entry.
            if length(args) > 1 && isa(args{1}, 'Experiment')
                table = args{2};
                % create an object array with the size corresponding to the
                % number of rows in the data table.
                obj(1, size(table, 1)) = feval(class(obj));
                % set experiment
                [obj.experiment] = deal(args{1});
                % if there additional default values, this loop sets them.
                for i=3:2:length(args)
                    [obj.(args{i})] = deal(args{i+1});
                end
                names = table(1,:).Properties.VariableNames;
                values = table2cell(table);
                % shallow copy of table named values into the entity array.
                for i = 1:size(table, 2)
                     %%% be extremely careful with variable refactoring.
                     %%% Any name change in the table or in the class
                     %%% definitions can lead to code breaks. Make sure to
                     %%% rename both table variables and the class variable
                     %%% if you want to refactor things.
                    [obj.(names{i})] = values{:, i};
                end
            else
                % in there are no args, then only one object should be
                % created, the empty NaN object. You can check for this
                % object using EXPERIMENT#ISNAN
                obj.(obj.uniqueID) = nan;
                obj.experiment = nan;
                % if there additional default values, this loop sets them.
                for i=1:2:length(args)
                    obj.(args{i}) = args{i+1};
                end
            end
        end

        function tf = isnan(obj)
            % ISNAN Determine if the imput object is the default no-value object.
            % Parameters: none.
            % Returns: boolean[]
            %   an array of 1 and 0, where true indicates the object is
            %   nan, and false otherwise, corresponding to the index of the
            %   original object in the array.
            tf = reshape(isnan([obj.(obj.uniqueID)]), size(obj));
        end

        function tf = eq(lhs, rhs)
            if class(lhs) ~= class(rhs)
                tf = zeros(size(lhs)) | zeros(size(rhs));
            else
                tf = ~(isnan(lhs) | isnan(rhs));
                if length(lhs) == 1
                    lhs = repmat(lhs, size(tf(tf)));
                else
                    lhs = lhs(tf);
                end
                if length(rhs) == 1
                    rhs = repmat(rhs, size(tf(tf)));
                else
                    rhs = rhs(tf);
                end
                tf(tf) = (reshape([lhs.(lhs.uniqueID)], size(lhs)) == reshape([rhs.(rhs.uniqueID)], size(rhs)) & ...
                 reshape([lhs.experiment], size(lhs)) == reshape([rhs.experiment], size(rhs)));
            end
        end
        
        function tf = ne(lhs, rhs)
            tf = ~(lhs == rhs);
        end
        
        function id = frameID(~)
            % FRAMEID The name of the property of the class that represents the identifier of the frame this entity belongs to.
            % this method can be overriden by derivative classes. Very
            % useful for getting the frame of any class.
            % Parameters: none.
            % Returns: string
            %   the name of the frame identifier property. You can get the
            %   frame ID of a particular entity using the code
            %   <code>physical_entity.(physical_entity.frameID)</code>
            id = "frame";
        end
        
        function obj = flatten(obj)
            % FLATTEN reshape the matrix into a flat array, removing nans.
            % Parameters: none.
            % Returns: the same matrix of objects, but with size (1, len)
            % and without any NaNs.
            obj = reshape(obj, 1, []);
            obj = obj(~isnan(obj));
        end
        
        function ret_arr = siblings(obj_arr, prequisite)
            % SIBILINGS search for all entities of the same type that share a property.
            % The shared property can be an actual property of the object
            % (for example, frame) or something more complex (like shape
            % parameter or that they are close enough in distance)
            %   t_prequisite: char[], string, boolean(PhysicalEntity[], PhysicalEntity)
            %      the function to use to find the sibilings of the given
            %      object.
            %      The choice of function can be very important, as this
            %      decides how efficient this program will be.
            %      char[], string (and BulkFunc once that's implemented) yield the fastest methods
            %      double(PhysicalEntity) is fast, but not optimal
            %      boolean(PhysicalEntity[], PhysicalEntity) significantly
            %      slower than the rest.
            
            % property is either a bool_arr(obj_arr, obj) or string.
            % convert strign to bool arr
            if isa(prequisite, 'char') || isa(prequisite, 'string')
                prequisite = @(exp_lookup, ref_obj) ...
                    ([exp_lookup.(prequisite)] == ref_obj.(prequisite));
            end
            % get relevant databases
            exp_arr = {obj_arr.experiment};
            clazz = class(obj_arr(1));
            % turn obj array to cell array for non-uniform result
            obj_cell = num2cell(obj_arr);
            lookup_result = cellfun(@(obj, exp) (exp.lookup(clazz, ...
                prequisite(exp.lookup(clazz), obj))), obj_cell, exp_arr, ...
                'UniformOutput', false);
            sizes = cellfun(@(result) (length(result)), lookup_result);
            ret_arr = repmat(feval(clazz), length(obj_cell), max(sizes));
            for i=1:length(obj_cell)
                ret_arr(i, 1:sizes(i)) = lookup_result{i};
            end
        end
        
        function frames = frames(obj, varargin)
            % FRAMES calculates the frames each entity in this array belongs to.
            % Parameters:
            %   varargin: additional MATLAB builtin operations to apply on
            %   the result.
            % Return type: FRAME[]
            clazz = class(Frame);
            if strcmp(class(obj(1)),clazz)
                % identity function
                frames = obj(varargin{:});
            else
                frames = obj.lookup1(clazz, obj.frameID, Frame().frameID, varargin{:});
            end
        end
        
        function dbonds = dBonds(obj, varargin)
            % DBONDS calculates the DBonds each entity in this array contains.
            % Some classes disable this functino as they are unrelated
            % to directed bonds.
            % Parameters:
            %   varargin: additional MATLAB builtin operations to apply on
            %   the result.
            % Return type: DBOND[]
            clazz = class(DBond);
            if strcmp(class(obj(1)),clazz)
                % identity function
                dbonds = obj(varargin{:});
            else
                dbonds = obj.lookupMany(clazz, obj.uniqueID, obj.uniqueID, varargin{:});
            end
        end
        
        function pair_list = pair(obj, dist_func, varargin)
            [mesh_x, mesh_y] = meshgrid(obj);
            full_pair_list = reshape(cat(3, mesh_x, mesh_y), [], 2);
            distance_list = BulkFunc.apply(dist_func, full_pair_list(:, 1), full_pair_list(:, 2));
            pair_list = Pair(full_pair_list, distance_list);
            pair_list = pair_list(distance_list > 0);
            % filter result and put it into result_arr
            if nargin > 2
                pair_list = pair_list(varargin{:});
            end
        end

        function dist = pixelDist2d(obj,obj2)
           % This function calculates the distance between a physical
           % entity (relevant for cells, bonds, pixels and defects) or
           % array of these, and another (single) physical entity. The
           % distance is given in 2d pixels.
            pos1 = obj.list_pixels;
            pos2 = obj2.list_pixels;
            dist = sqrt((pos1(:,1)-pos2(:,1)).^2+(pos1(:,2)-pos2(:,2)).^2);
        end

    
    end

    methods (Static)

        function [triangle_Q,two_phi,tri_area] = calculateTriangleQ(verts)
            % verts needs to be a list of triangle vertices in counter-clockwise
            % order, as a 3x2 matrix with rows being different vertices,
            % and columns being x,y coordinates
            % Returns Q elongation tensor, 2*phi the orientation angle, and
            % area for the triangle. 
            tri_area =  0.5*(-verts(2,1)* verts(1,2)+verts(3,1)*verts(1,2)+verts(1,1)*verts(2,2)-verts(3,1)*verts(2,2)- verts(1,1)*verts(3,2)+ verts(2,1)*verts(3,2));
            xx= verts(2,1) - verts(1,1);
            xy= verts(3,1) - verts(1,1);
            yx= verts(2,2) - verts(1,2);
            yy= verts(3,2) - verts(1,2);
            scaling_factor= 1/(2*3^(1/4));
            S_xx = scaling_factor*(-1*(xx + xy));
            S_xy = scaling_factor*sqrt(3)*(xx - xy);
            S_yx = scaling_factor*(-1*(yx + yy));
            S_yy = scaling_factor*sqrt(3)*(yx - yy);
            Q_kk = log(S_xx*S_yy - S_xy*S_yx);
            theta = mod2pi(atan2(S_yx - S_xy, S_xx + S_yy));
            two_phi = (theta + atan2( S_xy + S_yx, S_xx - S_yy));
            triangle_Q = asinh(0.5*sqrt((S_xx-S_yy)^2.+( S_xy+S_yx)^2.)/exp(0.5*Q_kk));

        end

        function Q_rr = projectQonAxis(Q_xx,Q_xy,axis)
            % This function takes the elements of the shape tensor Q,
            % and finds the element along the direction defined by "axis"
            Q_rr = [];
            for i=1:length(Q_xx)
                Q = [Q_xx(i), Q_xy(i); Q_xy(i), -Q_xx(i)];
                Q_rr(i) = axis(i,:)*Q*axis(i,:)';
            end
        end
    end
    
    methods(Access = protected)
        
        function phys_arr = lookup1(obj, clazz, requester_prop, target_prop, varargin)
            % LOOKUP1 A utility seach function that yields 1 result per entry.
            % In basis, it compares a specified property of the requester entity
            % to the specified property of the entity you want to look for,
            % and if they are equal, then the request is satisfied.
            % LOOKUP1 should be used in implementations when each entity
            % yields 1 result exactly (that can be NaN). This can be useful
            % for expanded matrix support and increased efficiency.
            % Parameters:
            %   obj (caller):
            %      the object which requests the search.
            %   clazz: string
            %      the class name of the object type you are looking for
            %   requester_prop: string
            %      the name of the property of obj to be searched against
            %   target_prop: string
            %      the name of the property of the looked up entities to be
            %      compare with requester_prop
            %   varargin: additional MATLAB builtin operations to apply on
            %   the result.
            % Return type: clazz[]
            size_obj = num2cell(size(obj));
            phys_arr(size_obj{:}) = feval(clazz);
            if numel(obj) > 2
                index = containers.Map;
                for lookup_idx = 1:numel(obj)
                    obj.logger.progress("Searching for %ss matching ID %s.%s", lookup_idx, numel(obj), clazz, class(obj(1)), requester_prop);
                    entity = obj(lookup_idx);
                    % skip NaNs
                    if isnan(entity) || isnan(entity.(requester_prop))
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
                    % get all candidate results
                    frame_filtered_phys = index(full_map_key);
                    % run actual search on them
                    lookup_result = frame_filtered_phys([frame_filtered_phys.(target_prop)] == entity.(requester_prop));
                    if ~isempty(lookup_result)
                        phys_arr(lookup_idx) = lookup_result;
                    end
                end
            else
                for lookup_idx = 1:numel(obj)
                    % if there arent many elements, use the implicit
                    % algorithm which just looks up stuff.
                    if isnan(obj(lookup_idx)) || isnan(obj(lookup_idx).(requester_prop))
                        continue;
                    end
                    target_phys = obj(lookup_idx).experiment.lookup(clazz);
                    lookup_result = target_phys([target_phys.(target_prop)] == obj(lookup_idx).(requester_prop));
                    if ~isempty(lookup_result)
                        phys_arr(lookup_idx) = lookup_result;
                    end
                end
            end
            % filter result and put it into result_arr
            if nargin > 4
                phys_arr = phys_arr(varargin{:});
            end
        end
        
        function phys_arr = lookupMany(obj, clazz, requester_prop, target_prop, varargin)
            % LOOKUPMANY A utility search function that yields multiple results per entry.
            % In basis, it compares a specified property of the requester entity
            % to the specified property of the entity you want to look for,
            % and if they are equal, then the request is satisfied.
            % LOOKUPMANY should be used in implementations when each entity
            % can potenially yield more than 1 result, whihc is impossible
            % with LOOKUP1.
            % Parameters:
            %   obj (caller):
            %      the object which requests the search.
            %   clazz: string
            %      the class name of the object type you are looking for
            %   requester_prop: string
            %      the name of the property of obj to be searched against
            %   target_prop: string
            %      the name of the property of the looked up entities to be
            %      compare with requester_prop
            %   varargin: additional MATLAB builtin operations to apply on
            %   the result.
            % Return type: clazz[]
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
                    obj.logger.progress("Searching for %ss matching ID %s.%s", lookup_idx, numel(obj), clazz, class(obj(1)), requester_prop);
                    entity = obj(lookup_idx);
                    % skip NaNs
                    if isnan(entity) || isnan(entity.(requester_prop))
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
                    % get all candidate results
                    if index.isKey(full_map_key)
                        frame_filtered_phys = index(full_map_key);
                    else
                        frame_filtered_phys = [];
                    end
                    % run actual search on them
                    lookup_result{lookup_idx} = frame_filtered_phys([frame_filtered_phys.(target_prop)] == entity.(requester_prop));
                end
            else
                for lookup_idx = 1:numel(obj)
                    % if there arent many elements, use the implicit
                    % algorithm which just looks up stuff.
                    if isnan(obj(lookup_idx)) || isnan(obj(lookup_idx).(requester_prop))
                        continue;
                    end
                    target_phys = obj(lookup_idx).experiment.lookup(clazz);
                    lookup_result{lookup_idx} = target_phys([target_phys.(target_prop)] == obj(lookup_idx).(requester_prop));
                end
            end
            % since the lookup was placed into a cell array, we need to
            % reshape it into a matrix.
            sizes = cellfun(@(result) (length(result)), lookup_result);
            if max(sizes) > 0
                phys_arr(numel(obj), max(sizes)) = feval(clazz);
                for i=1:numel(obj)
                    if sizes(i) > 0
                        phys_arr(i, 1:sizes(i)) = lookup_result{i};
                    end
                end
            else
                phys_arr = eval(clazz, '.empty(', num2str(length(obj)), ',0)');
            end
            if length(obj) ~= numel(obj)
                % reorganize the 2D array into a 3D array
                size_obj = num2cell(size(obj));
                phys_arr = reshape(phys_arr, size_obj{:}, []);
            end
            % filter result and put it into result_arr
            if nargin > 4
                phys_arr = phys_arr(varargin{:});
            end
        end
        
        function phys_arr = getOrCalculate(obj, clazz, prop, lookup_func, varargin)
            % GETORCALCULATE A utility function that gets a property or calculates and saves the result.
            % In basis, it checks which entities in the list do not have the
            % result stored in the property, puts them in a list and runs
            % the calculation, storing the result. This can be used in
            % tandem with the lookup functions.
            % GETORCALCULATE should be used in implementations of
            % frequently used values or hard to calculate values
            % Parameters:
            %   obj (caller):
            %      the object which requests the search.
            %   clazz: string
            %      the class name of the object type you are looking for
            %   prop: string
            %      the name of the property of obj where the result should
            %      be stored and looked for.
            %   lookup_func: clazz(PhysicalEntity)
            %      The function used to calculate the property in question.
            %      This can yield multiple results or a single result.
            %   varargin: additional MATLAB builtin operations to apply on
            %      the result.
            % Return type: clazz[]
            
            % check which objects needs to calculate stuff
            if ismember(clazz, {'logical', 'double', 'single', 'uint8', ...
                    'uint16', 'uint32', 'uint64', 'int8', 'int16', 'int32', 'int64'})
                index_flag = arrayfun(@(entity) ~isnan(entity) & isempty(entity.(prop(1))), obj);

            else
                index_flag = arrayfun(@(entity) ~isnan(entity) & Null.isNull(entity.(prop(1))), obj);
            end
            obj_to_index = obj(index_flag);
            if ~isempty(obj_to_index)
                obj.logger.info("Indexing %s for %d %ss",  strjoin(prop, ","), length(obj_to_index), class(obj_to_index(1)));
                % apply calculation on the neccesary objects
                index_result = lookup_func(obj_to_index);
                if size(index_result, 1) ~= length(obj_to_index)
                    index_result = index_result';
                end

                for i=1:size(index_result, 1)
                    % store non NaN unique results in the respective object
                    result_row = index_result(i, :);
                    if length(prop) == 1
                        if ismember(clazz, {'logical', 'double', 'single', 'uint8', ...
                                'uint16', 'uint32', 'uint64', 'int8', 'int16', 'int32', 'int64'})
                            obj_to_index(i).(prop) = unique(result_row);
                        else
                            obj_to_index(i).(prop) = unique(result_row(~isnan(result_row)));
                        end
                    else
                        for j = 1:length(prop)
                            obj_to_index(i).(prop(j)) = result_row(j);
                        end
                    end

                end
            else
                phys_arr = eval([clazz, '.empty(', num2str(length(obj)), ',0)']);
            end
            % collect all the properties of the object into a tight matrix.
            if ismember(clazz, {'logical', 'double', 'single', 'uint8', ...
                    'uint16', 'uint32', 'uint64', 'int8', 'int16', 'int32', 'int64'})
                sizes = arrayfun(@(entity) length(entity.(prop(1))), obj);

            else
                sizes = arrayfun(@(entity) ~Null.isNull(entity.(prop(1))) * length(entity.(prop(1))), obj);
            end
            if max(sizes) > 0
                if ismember(clazz, {'logical', 'double', 'single', 'uint8', ...
                        'uint16', 'uint32', 'uint64', 'int8', 'int16', 'int32', 'int64'})
                    phys_arr(numel(obj), max(sizes, [], 'all'),length(prop)) = feval(clazz, nan);
                else
                    phys_arr(numel(obj), max(sizes, [], 'all'),length(prop)) = feval(clazz);
                end
                for i=1:numel(obj)
                    if sizes(i) > 0
                        for j = 1:length(prop)
                           phys_arr(i, 1:sizes(i),j) = obj(i).(prop(j));
                        end
                    end
                end
            else
                phys_arr = eval([clazz, '.empty(', num2str(length(obj)), ',0)']);
            end
            % a reshape in case of a 1:1 function
            if numel(phys_arr) == numel(obj)
                phys_arr = reshape(phys_arr, size(obj));
            end
            % filter result and put it into result_arr
            if nargin > 4
                phys_arr = phys_arr(varargin{:});
            end
            % Remove dimensions of size 1
            phys_arr = squeeze(phys_arr);
        end
    end
end


classdef (Abstract) PhysicalEntity < handle
    %Entity the general object representing an indexed entity in the database
    %   Detailed explanation goes here
    
    properties
        experiment
    end

    methods (Abstract)
        uniqueID(obj) % returns the name of the property that represents the unique identifier of the entity
    end
    
    methods
        function obj = PhysicalEntity(args)
            %ENTITY Construct an entity. This method can convert entire
            % tables to object arrays.
            if length(args) > 1
                table = args{2};
                obj(1, size(table, 1)) = feval(class(obj)); % create obj array
                [obj.experiment] = deal(args{1});
                for i=3:2:length(args) % custom default values
                    [obj.(args{i})] = deal(args{i+1});
                end
                names = table(1,:).Properties.VariableNames;
                values = table2cell(table);
                for i = 1:size(table, 2)
                    [obj.(names{i})] = values{:, i}; %% be careful with variable refactoring
                end
            else
                obj.(obj.uniqueID) = nan;
                obj.experiment = nan;
            end
        end

        function tf = isnan(obj)
            tf = reshape(isnan([obj.(obj.uniqueID)]), size(obj));
        end

        function tf = eq(lhs, rhs)
            if class(lhs) ~= class(rhs)
                tf = zeros(size(lhs)) | zeros(size(rhs));
            else
                tf = isnan(lhs) | isnan(rhs);
                lhs = lhs(~tf);
                rhs = rhs(~tf);
                tf(~tf) = (reshape([lhs.(lhs.uniqueID)], size(lhs)) == reshape([rhs.(rhs.uniqueID)], size(rhs)) & ...
                 reshape([lhs.experiment], size(lhs)) == reshape([rhs.experiment], size(rhs)));
            end
        end
        
        function tf = ne(lhs, rhs)
            tf = ~(lhs == rhs);
        end
        
        function id = frameID(~)
            id = "frame";
        end
        
        function obj = flatten(obj)
            obj = reshape(obj, 1, []);
            obj = obj(~isnan(obj));
        end
        
        function ret_arr = siblings(obj_arr, prequisite)
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
            clazz = class(Frame);
            if strcmp(class(obj(1)),clazz)
                frames = obj(varargin{:});
            else
                frames = obj.lookup1(clazz, obj.frameID, Frame().frameID, varargin{:});
            end
        end
        
        function dbonds = dBonds(obj, varargin)
            clazz = class(DBond);
            if strcmp(class(obj(1)),clazz)
                dbonds = obj(varargin{:});
            else
                dbonds = obj.lookupMany(clazz, obj.uniqueID, obj.uniqueID, varargin{:});
            end
        end
    end
    
    methods(Access = protected)
        
        function phys_arr = lookup1(obj, clazz, requester_prop, target_prop, varargin)
            phys_arr(size(obj, 1), size(obj, 2)) = feval(clazz);
            if numel(obj) > 6
                index = containers.Map;
                for lookup_idx = 1:numel(obj)
                    entity = obj(lookup_idx);
                    if isnan(entity) || isnan(entity.(requester_prop))
                        continue;
                    end
                    map_key = entity.experiment.folder_;
                    full_map_key = [map_key, '_', entity.frame];
                    if ~index.isKey(full_map_key)
                        full_phys = entity.experiment.lookup(clazz);
                        frame_num = [full_phys.(full_phys.frameID)];
                        for frame_id=unique(frame_num)
                            index([map_key, '_', frame_id]) = full_phys(frame_num == frame_id);
                        end
                    end
                    frame_filtered_phys = index(full_map_key);
                    phys_arr(lookup_idx) = frame_filtered_phys([frame_filtered_phys.(target_prop)] == entity.(requester_prop));
                end
            else
                for lookup_idx = 1:numel(obj)
                    target_phys = obj(lookup_index).experiment.lookup(clazz);
                    phys_arr(lookup_idx) = target_phys([target_phys.(target_prop)] == obj(lookup_index).(requester_prop));
                end
            end
            % filter result and put it into result_arr
            if nargin > 4
                phys_arr = phys_arr(varargin{:});
            end
        end
        
        function phys_arr = lookupMany(obj, clazz, requester_prop, target_prop, varargin)
            if length(obj) ~= numel(obj)
                disp("multi-value lookup applied on a 2D matrix. This is illegal. Please flatten and re-apply.");
            end
            lookup_result = cell(size(obj));
            if numel(obj) > 6
                index = containers.Map;
                for lookup_idx = 1:numel(obj)
                    entity = obj(lookup_idx);
                    if isnan(entity) || isnan(entity.(requester_prop))
                        continue;
                    end
                    map_key = entity.experiment.folder_;
                    full_map_key = [map_key, '_', entity.frame];
                    if ~index.isKey(full_map_key)
                        full_phys = entity.experiment.lookup(clazz);
                        frame_num = [full_phys.(full_phys.frameID)];
                        for frame_id=unique(frame_num)
                            index([map_key, '_', frame_id]) = full_phys(frame_num == frame_id);
                        end
                    end
                    frame_filtered_phys = index(full_map_key);
                    lookup_result{lookup_idx} = frame_filtered_phys([frame_filtered_phys.(target_prop)] == entity.(requester_prop));
                end
            else
                for lookup_idx = 1:numel(obj)
                    target_phys = obj(lookup_index).experiment.lookup(clazz);
                    lookup_result{lookup_idx} = target_phys([target_phys.(target_prop)] == obj(lookup_index).(requester_prop));
                end
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
        
        function phys_arr = getOrCalculate(obj, clazz, prop, lookup_func, varargin)
            index_flag = arrayfun(@(entity) isempty(entity.(prop)), obj);
            obj_to_index = obj(index_flag);
            if ~isempty(obj_to_index)
                fprintf("Indexing %s for %d %ss\n", prop, length(obj_to_index), class(obj_to_index(1)));
                index_result = lookup_func(obj(index_flag)');
                for i=1:size(index_result, 1)
                    result_row = index_result(i, :);
                    obj_to_index(i).(prop) = unique(result_row(~isnan(result_row)));
                end
            end
            sizes = arrayfun(@(entity) length(entity.(prop)), obj);
            phys_arr(length(obj), max(sizes)) = feval(clazz);
            for i=1:length(obj)
                phys_arr(i, 1:sizes(i)) = obj(i).(prop);
            end
            if numel(phys_arr) == numel(obj)
                phys_arr = reshape(phys_arr, size(obj));
            end
            % filter result and put it into result_arr
            if nargin > 4
                phys_arr = phys_arr(varargin{:});
            end
        end
    end
end


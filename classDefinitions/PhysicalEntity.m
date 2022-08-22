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

        function tf = nan(obj)
            tf = isnan([obj.(obj.uniqueID)]);
        end

        function tf = eq(lhs, rhs)
            if class(lhs) ~= class(rhs)
                tf = zeros(size(lhs));
            else
                tf = (nan(lhs) & nan(rhs)) | ...
                 ([lhs.(lhs.uniqueID)] == [rhs.(rhs.uniqueID)] & ...
                 [lhs.experiment] == [rhs.experiment]);
                if length(lhs) == length(tf)
                    tf = reshape(tf, size(lhs));
                else
                    tf = reshape(tf, size(rhs));
                end
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
            obj = obj(~nan(obj));
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
    end
end


classdef (Abstract) Entity < handle
    %Entity the general object representing an indexed entity in the database
    %   Detailed explanation goes here
    
    properties
        experiment
    end

    methods (Abstract)
        uniqueID(obj) % returns the name of the property that represents the unique identifier of the entity
    end
    
    methods
        function obj = Entity(args)
            %ENTITY Construct an entity
            %   note that this can work well with a single row as well
            if length(args) > 1
                table_rows = args{2};
                for name = table_rows(1,:).Properties.VariableNames
                    obj.(name{1}) = table_rows{1:end, name}; %% be careful with variable refactoring
                end
                obj.experiment = args{1};
            else
                obj.(obj.uniqueID) = nan;
                obj.experiment = nan;
            end
        end

        function tf = isempty(obj)
            tf = isnan([obj.(obj.uniqueID)]);
        end

        function tf = eq(lhs, rhs)
            if class(lhs) ~= class(rhs)
                tf = zeros(size(lhs));
            else
                tf = (isempty(lhs) & isempty(rhs)) | ...
                 ([lhs.(lhs.uniqueID)] == [rhs.(rhs.uniqueID)] & ...
                 [lhs.experiment] == [rhs.experiment]);
            end
        end
        
        function tf = ne(lhs, rhs)
            tf = ~(lhs == rhs);
        end
    end
end


classdef Pair < handle
    %PAIR Represents a combination of two of the same entity
    
    properties
        elements
        distance
    end
    
    methods
        function obj = Pair(pair_mat, dist_list)
            if nargin > 0
                obj(length(dist_list)) = Pair;
                dist_cell = num2cell(dist_list);
                [obj.distance] = dist_cell{:};
                pair_cell = num2cell(pair_mat, 2);
                [obj.elements] = pair_cell{:};
            end
        end
        
        function frames = frame(obj)
            if length(obj) > 1
                frames = [obj.elements];
                frames = reshape([frames(1:2:end).frame], size(obj));
            else
                frames = obj.elements(1).frame;
            end
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
                tf(tf) = (reshape([arrayfun(@(arr) arr.elements(1).(arr.elements(1).uniqueID), lhs)], size(lhs)) == reshape([arrayfun(@(arr) arr.elements(1).(arr.elements(1).uniqueID), rhs)], size(rhs)) & ...
                    reshape([arrayfun(@(arr) arr.elements(2).(arr.elements(2).uniqueID), lhs)], size(lhs)) == reshape([arrayfun(@(arr) arr.elements(2).(arr.elements(2).uniqueID), rhs)], size(rhs)));
            end
        end
        
        function tf = ne(lhs, rhs)
            tf = ~eq(lhs,rhs);
        end

        function tf = isnan(obj)
            % ISNAN Determine if the imput object is the default no-value object.
            % Parameters: none.
            % Returns: boolean[]
            %   an array of 1 and 0, where true indicates the object is
            %   nan, and false otherwise, corresponding to the index of the
            %   original object in the array.
                   tf = reshape(isnan([arrayfun(@(arr) arr.elements(1).(arr.elements(1).uniqueID), obj)]), size(obj));
        end

        function sorted = sort(obj)
            
            is_column = iscolumn(obj);
            if ~is_column
                % Convert to column
                arr = obj(:);
            else
                arr = obj;
            end
           
            id_1 = [arrayfun(@(arr) arr.elements(1).(arr.elements(1).uniqueID), arr)];
            id_2 = [arrayfun(@(arr) arr.elements(2).(arr.elements(2).uniqueID), arr)];
            to_sort = [id_1,id_2];
            [~,ind] = sortrows(to_sort);
            sorted = arr(ind);
            if ~is_column
                % Convert to column
                sorted = sorted';
            end

        end

    end
end


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
                frames = reshape([cellfun(@(elem) elem(1), obj.elements).frame], size(obj));
            else
                frames = obj.elements(1).frame;
            end
        end
    end
end


classdef Null < handle
    properties(Constant)
        obj_ = Null;
    end
    
    methods (Access = private)
        function obj = Null
        end
    end
    
    methods (Static)
        function logic = isNull(arr)
            logic = isequal(Null.obj_, arr);
        end
        
        function null = null
            null = Null.obj_;
        end
    end
end


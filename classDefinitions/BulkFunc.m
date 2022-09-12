classdef BulkFunc
    % BULKFUNC An object oriented representation of efficient functions
    % - functions that apply on entire arrays. Useful as xFunction.
    
    properties
        f
    end
    
    methods
        function obj = BulkFunc(f)
            obj.f = f;
        end
        
        function result = subsref(obj, args)
            result = obj.f(args.subs{:});
        end
        
        function n = nargin(obj)
            n = nargin(obj.f);
        end
    end
end


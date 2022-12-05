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
    
    methods (Static)
        function result = apply(func_or_bulk, varargin)
            if isa(func_or_bulk, 'BulkFunc')
                result = func_or_bulk.f(varargin{1:nargin(func_or_bulk)});
            else 
                if isempty(varargin)  
                    result = func_or_bulk();
                else
                    result = arrayfun(@(obj) func_or_bulk(obj, varargin{2:nargin(func_or_bulk)}), varargin{1});
                end
            end
        end
    end
end


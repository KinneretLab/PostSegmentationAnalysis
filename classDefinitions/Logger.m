classdef Logger < handle
    %LOGGER Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        clazz
    end
    
    methods
        function obj = Logger(clazz)
            obj.clazz = clazz;
        end
        
        function info(obj, format, varargin)
            obj.log(@disp, 'INFO', format, varargin{:});
        end
        
        function warn(obj, format, varargin)
            obj.log(@warning, 'WARN', format, varargin{:});
        end
        
        function error(obj, format, varargin)
            obj.log(@(msg) fprintf(2, msg + '\n'), 'ERROR', format, varargin{:});
        end
        
        function log(obj, log_func, level, format, varargin)
            time_str = datestr(now, 'yyyy-mm-dd HH:MM:SS');
            message = sprintf("[%s %s] [%s] " + format, time_str, obj.clazz, level, varargin{:});
            log_func(message);
        end
    end
end


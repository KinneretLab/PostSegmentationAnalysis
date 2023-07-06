classdef Logger < handle
    %LOGGER A utility class useful for informing the user of relevant
    % information. Incorporates time, class, and color to make useful
    % indications.
    
    properties
        clazz
    end

    methods(Static)
        function out = level(level)
            persistent level_;
            if nargin
                level_ = level;
            end
            if isempty(level_)
                level_ = 1;
            end
            out = level_;
        end
    end
    
    methods
        function obj = Logger(clazz)
            obj.clazz = clazz;
        end
        
        function debug(obj, format, varargin)
            obj.log(@(msg) cprintf('[0,0.4,0]', msg + '\n'), 'DEBUG', 0, format, varargin{:});
        end
        
        function info(obj, format, varargin)
            obj.log(@disp, 'INFO', 1, format, varargin{:});
        end
        
        function warn(obj, format, varargin)
            obj.log(@(msg) cprintf('[1,0.4,0]', msg + '\n') , 'WARN', 2, format, varargin{:});
        end
        
        function error(obj, format, varargin)
            obj.log(@(msg) cprintf('[0.9,0,0]', msg + '\n'), 'ERROR', 3, format, varargin{:});
        end
        
        function log(obj, log_func, level_name, level, format, varargin)
            if Logger.level <= level
                time_str = datestr(now, 'yyyy-mm-dd HH:MM:SS');
                message = sprintf("[%s %s] [%s] " + format, time_str, obj.clazz, level_name, varargin{:});
                log_func(message);
            end
        end
    end
end


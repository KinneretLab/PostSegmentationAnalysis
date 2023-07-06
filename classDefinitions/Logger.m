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
        function out = lastLineLength(last_line_length)
            persistent line_length_;
            if nargin
                line_length_ = last_line_length;
            end
            if isempty(line_length_)
                line_length_ = 0;
            end
            out = line_length_;
        end
        function out = lastLog(last_log)
            persistent last_log_;
            if nargin
                last_log_ = last_log;
            end
            if isempty(last_log_)
                last_log_ = datetime('now');
            end
            out = last_log_;
        end
        function out = logRateSeconds(rate)
            persistent rate_;
            if nargin
                rate_ = seconds(rate);
            end
            if isempty(rate_)
                rate_ = seconds(30);
            end
            out = rate_;
        end
    end
    
    methods
        function obj = Logger(clazz)
            obj.clazz = clazz;
        end
        
        function debug(obj, format, varargin)
            obj.log('[0,0.4,0]', "DEBUG", 0, format, varargin{:});
        end
        
        function info(obj, format, varargin)
            obj.log('[0,0,0]', "INFO", 1, format, varargin{:});
        end
        
        function warn(obj, format, varargin)
            obj.log('[1,0.4,0]' , "WARN", 2, format, varargin{:});
        end
        
        function error(obj, format, varargin)
            obj.log('[0.9,0,0]', "ERROR", 3, format, varargin{:});
        end

        function progress(obj, format, current, total, varargin)
            if current == 1 || current == total || datetime('now') - Logger.lastLog > Logger.logRateSeconds
                if current == 1
                    Logger.lastLineLength(0);
                end
                % generate progress string
                prog_frac = current / total;
                bar_size = 40;
                num_done = floor(prog_frac * bar_size);
                num_left = bar_size - num_done;
                prog_str = sprintf(" [%s%s] (%d/%d)", repmat('#', 1, num_done), repmat('.', 1, num_left), current, total);
                % do the printing
                obj.log('[0,0,0.7]', "PROG", 1, format + prog_str, varargin{:});
            end
        end
        
        function log(obj, color, level_name, level, format, varargin)
            if Logger.level <= level
                time_str = datetime('now');
                time_str.Format =  'yyyy-MM-dd HH:mm:SS';
                backspace = "";
                if level_name == "PROG"
                    fprintf(repmat('\b', 1, Logger.lastLineLength))
                end
                message = sprintf("[%s %s] [%s] " + format + "\n", time_str, obj.clazz, level_name, varargin{:});
                line_length = cprintf(color,message);
                if level_name == "PROG"
                    Logger.lastLineLength(line_length);
                    Logger.lastLog(time_str);
                else
                    Logger.lastLineLength(0);
                end
            end
        end
    end
end


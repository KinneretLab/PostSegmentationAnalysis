classdef PlotBuilder < FigureBuilder
    % PlotBuilder a tool used to draw 2D or 1D plots
    %   draws the relationship between two variables, like an evolution graph, or a distribution.
    %   This is not meant to be put in an array.
    properties (Access = protected)
        x_function_       % double(object)
        x_err_function_   % double(object array)
        x_log_scale_      % bool
        x_label_          % string
        x_label_size_     % int
        x_label_bold_     % bool
        x_label_italic_   % bool
        x_calibration_    % double
        y_function_       % double(object array)
        y_err_function_   % double(object array)
        y_log_scale_      % bool
        y_label_          % string
        y_label_size_     % int
        y_label_bold_     % bool
        y_label_italic_   % bool
        y_calibration_    % double
        grid_             % chararr
        data_             % {obj array...}
        mode_             % string
        cumulative_       % bool
        reference_slopes_ % double array
    end

    methods(Static)
        function func = property(prop_name)
            func = @(obj) (obj.(prop_name));
        end

        function func = count()
            func = @(obj_arr) (length(obj_arr));
        end

        function func = mean(prop_name)
            func = @(obj_arr) (mean([obj_arr.(prop_name)]));
        end

        function func = std(prop_name)
            func = @(obj_arr) (std([obj_arr.(prop_name)]));
        end
    end
    
    methods
        function obj = PlotBuilder()
            obj@FigureBuilder()
            obj.x_function_       = PlotBuilder.property("frame");
            obj.x_err_function_   = @(obj_arr) (0);
            obj.x_log_scale_      = false;
            obj.x_label_          = "";
            obj.x_label_size_     = 12;
            obj.x_label_bold_     = 'normal';
            obj.x_label_italic_   = 'normal';
            obj.x_calibration_    = 1;
            obj.y_function_       = PlotBuilder.count;
            obj.y_err_function_   = @(obj_arr) (0);
            obj.y_log_scale_      = false;
            obj.y_label_          = "";
            obj.y_label_size_     = 12;
            obj.y_label_bold_     = 'normal';
            obj.y_label_italic_   = 'normal';
            obj.y_calibration_    = 1;
            obj.title_            = "plot figure";
            obj.grid_             = "off";
            obj.data_             = {};
            obj.mode_             = "line";
            obj.cumulative_       = false;
            obj.reference_slopes_ = [];
        end

        function [data_arrays, err_arrays] = calculate(obj)
            data_arrays = {};
            err_arrays = {};
            for list = obj.data_
                data_sorted = containers.Map('KeyType','double','ValueType','any');
                x_err_sorted = containers.Map('KeyType','double','ValueType','any');
                y_err_sorted = containers.Map('KeyType','double','ValueType','any');
                for entity = list{1}
                    x_value = obj.x_function_(entity);
                    if data_sorted.isKey(x_value)
                        data_sorted(x_value) = [data_sorted(x_value), entity];
                    else
                        data_sorted(x_value) = entity;
                    end
                end
                for key = data_sorted.keys
                    x_err_sorted(key{1}) = obj.x_err_function_(data_sorted(key{1}));
                    y_err_sorted(key{1}) = obj.y_err_function_(data_sorted(key{1}));
                    data_sorted(key{1}) = obj.y_function_(data_sorted(key{1}));
                end
                x_result = data_sorted.keys;
                y_result = data_sorted.values;
                x_err_result = x_err_sorted.values;
                y_err_result = y_err_sorted.values;
                data_arrays{end+1} = [x_result{:}] .* obj.x_calibration_;
                data_arrays{end+1} = [y_result{:}] .* obj.y_calibration_;
                err_arrays{end+1} = [x_err_result{:}] .* obj.x_calibration_;
                err_arrays{end+1} = [y_err_result{:}] .* obj.y_calibration_;
            end
        end

        function fig_handle = draw(obj)
            fig_handle = figure;
            hold on;
            [raw_data, err_data] = obj.calculate;
            if obj.cumulative_ % cumulative mode
                for i=2:2:length(raw_data)
                    raw_data{i} = cumsum(raw_data{i});
                end
            end
            switch obj.mode_
                case "line" % graphing mode
                    plot(raw_data{:});
                case "scatter"
                    plot(raw_data{:},'LineStyle','none','Marker','.');
                case "bar"
                    bar(vertcat(raw_data{1:2:end}),vertcat(raw_data{2:2:end}));
                case "distribution"
                    y_data = vertcat(raw_data{2:2:end});
                    if obj.cumulative_
                        y_data = y_data ./ y_data(:,end);
                    else
                        y_data = y_data ./ sum(y_data, 2);
                    end
                    bar(vertcat(raw_data{1:2:end}), y_data);
            end
            if any([err_data{1:2:end}])
                for i=1:2:length(raw_data)
                    errorbar(raw_data{i:i+1},err_data{i},'horizontal','.');
                end
            end
            if any([err_data{2:2:end}])
                for i=2:2:length(raw_data)
                    errorbar(raw_data{i-1:i},err_data{i},'.');
                end
            end
            x_min = min([raw_data{1:2:end}]); % add reference slopes
            x_max = max([raw_data{1:2:end}]);
            x_range = x_min:(x_max-x_min)/100:x_max;
            for i=1:size(obj.reference_slopes_)
                plot(x_range, obj.reference_slopes_(i) * x_range);
            end
            title(obj.title_, 'FontSize', obj.title_size_, 'FontWeight', obj.title_bold_, 'FontAngle', obj.title_italic_); % title stuff
            if "" ~= obj.x_label_
                xlabel(obj.x_label_, 'FontSize', obj.x_label_size_, 'FontWeight', obj.x_label_bold_, 'FontAngle', obj.x_label_italic_); % x axis stuff
            end
            if "" ~= obj.y_label_
                ylabel(obj.y_label_, 'FontSize', obj.y_label_size_, 'FontWeight', obj.y_label_bold_, 'FontAngle', obj.y_label_italic_); % y axis stuff
            end
            if obj.x_log_scale_ % x log scale
                set(gca, 'xscale','log')
            end
            if obj.y_log_scale_ % y log scale
                set(gca, 'yscale','log')
            end
            grid (obj.grid_); % grid mode    
            hold off;
        end
        
        function obj = addData(obj, entity_arr)
            obj.data_{end+1} = entity_arr;
        end
        
        function obj = clearData(obj)
            obj.data_ = {};
        end
        
        function obj = grid(obj, grid_type)
            if ismember(grid_type, ["off", "on", "minor"])
                obj.grid_ = grid_type;
            end
        end

        function obj = mode(obj, mode_name)
            if ismember(mode_name, ["distribution", "scatter", "bar", "line"])
                obj.mode_ = mode_name;
            end
        end
        
        function obj = referenceSlopes(obj, slope_arr)
            obj.reference_slopes_ = slope_arr;
        end

        function obj = xCalibration(obj, calib)
            obj.x_calibration_ = calib;
        end
        
        function obj = yCalibration(obj, calib)
            obj.y_calibration_ = calib;
        end

        function obj = xSize(obj, size)
            obj.x_label_size_ = size;
        end

        function obj = xBold(obj, varargin)
            obj.x_label_bold_ = FigureBuilder.optional('bold', 'normal', varargin);
        end

        function obj = xItalic(obj, varargin)
            obj.x_label_talic_ = FigureBuilder.optional('italic', 'normal', varargin);
        end

        function obj = xAxis(obj, text)
            obj.x_label_ = text;
        end

        function obj = ySize(obj, size)
            obj.y_label_size_ = size;
        end

        function obj = yBold(obj, varargin)
            obj.y_label_bold_ = FigureBuilder.optional('bold', 'normal', varargin);
        end

        function obj = yItalic(obj, varargin)
            obj.y_label_talic_ = FigureBuilder.optional('italic', 'normal', varargin);
        end

        function obj = yAxis(obj, text)
            obj.y_label_ = text;
        end

        function obj = xLogScale(obj, state)
            if nargin == 0
                obj.x_log_scale_ = true;
            else
                obj.x_log_scale_ = state;
            end
        end

        function obj = yLogScale(obj, state)
            if nargin == 0
                obj.y_log_scale_ = true;
            else
                obj.y_log_scale_ = state;
            end
        end

        function obj = cumulative(obj, state)
            if nargin == 0
                obj.cumulative_ = true;
            else
                obj.cumulative_ = state;
            end
        end
        
        function obj = xFunction(obj, func)
            if isa(func, 'char') || isa(func, 'string')
                obj.x_function_ = PlotBuilder.property(func);
            end
            if isa(func, 'double')
                obj.x_function_ = @(obj) (func);
            end 
            if isa(func, 'function_handle')
                obj.x_function_ = func;
            end
        end
        
        function obj = yFunction(obj, func)
            if isa(func, 'char') || isa(func, 'string')
                obj.y_function_ = PlotBuilder.mean(func);
            end
            if isa(func, 'double')
                obj.y_function_ = @(obj) (func);
            end 
            if isa(func, 'function_handle')
                obj.y_function_ = func;
            end
        end
        
        function obj = xErrFunction(obj, func)
            if isa(func, 'char') || isa(func, 'string')
                obj.x_err_function_ = PlotBuilder.std(func);
            end
            if isa(func, 'double')
                obj.x_err_function_ = @(obj) (func);
            end 
            if isa(func, 'function_handle')
                obj.x_err_function_ = func;
            end
        end
        
        function obj = yErrFunction(obj, func)
            if isa(func, 'char') || isa(func, 'string')
                obj.y_err_function_ = PlotBuilder.std(func);
            end
            if isa(func, 'double')
                obj.y_err_function_ = @(obj) (func);
            end 
            if isa(func, 'function_handle')
                obj.y_err_function_ = func;
            end
        end
    end
end
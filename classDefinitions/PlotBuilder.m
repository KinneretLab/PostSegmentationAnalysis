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
        normalize_       % bool
        bins_         % int - 0 means no binning, -1 means automatic binning
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
            obj.normalize_        = false;
            obj.bins_             = 0;
        end

        function [data_arrays, err_arrays] = calculate(obj)
            data_arrays = {};
            err_arrays = {};
            for list = obj.data_
                data_sorted = containers.Map('KeyType','double','ValueType','any');
                x_err_sorted = containers.Map('KeyType','double','ValueType','any');
                y_err_sorted = containers.Map('KeyType','double','ValueType','any');
                if obj.bins_ == 0
                    x_result = arrayfun(obj.x_function_, list{1});
                    x_values = unique(x_result);
                    for i=1:length(x_values)
                        x_value = x_values(i);
                        data_sorted(x_value) = list{1}(x_result == x_value);
                    end
                else
                    x_result = arrayfun(obj.x_function_, list{1});
                    if obj.bins_ == -1
                        [~, edges] = histcounts(x_result);
                    else
                        [~, edges] = histcounts(x_result, obj.bins_);
                    end
                    bin_indices = discretize(x_result, edges);
                    x_values = movmean(edges, 2);
                    for i=1:length(x_values)-1
                        x_value = x_values(i + 1);
                        data_sorted(x_value) = list{1}(bin_indices == i);
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
            if obj.normalize_
                if obj.cumulative_
                    raw_data(2:2:end) = cellfun(@(obj_arr) (obj_arr / obj_arr(end)),raw_data(2:2:end),'UniformOutput',false);
                else
                    raw_data(2:2:end) = cellfun(@(obj_arr) (obj_arr / sum(obj_arr)),raw_data(2:2:end),'UniformOutput',false);
                end
            end
            switch obj.mode_
                case "line" % graphing mode
                    plot(raw_data{:});
                case "scatter"
                    plot(raw_data{:},'LineStyle','none','Marker','.');
                case "bar"
                    sizes = cellfun(@(obj_arr) (length(obj_arr)), raw_data);
                    if max(sizes(1:2:end)) ~= min(sizes(1:2:end))
                        disp("[ERROR] bar graphs can only be drawn if the data is uniform in size.");
                    end
                    bar(vertcat(raw_data{1:2:end})',vertcat(raw_data{2:2:end})');
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
            for i=1:length(obj.reference_slopes_)
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
            if nargin == 1
                obj.grid_ = "on";
            else
                if ismember(grid_type, ["off", "on", "minor"])
                    obj.grid_ = grid_type;
                end
            end
        end

        function obj = mode(obj, mode_name)
            if ismember(mode_name, ["scatter", "bar", "line"])
                obj.mode_ = mode_name;
            end
        end
        
        function obj = distribution(obj, varargin)
            obj = obj.normalize.binning(varargin{:});
        end
        
        function obj = binning(obj, varargin)
            if isempty(varargin)
                obj.bins_ = -1;
            else
                if varargin{1} < 0
                    obj.bins_ = -1;
                else
                    obj.bins_ = varargin{1};
                end
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

        function obj = xLogScale(obj, varargin)
            obj.x_log_scale_ = FigureBuilder.optional(true, false, varargin);
        end

        function obj = yLogScale(obj, varargin)
            obj.y_log_scale_ = FigureBuilder.optional(true, false, varargin);
        end

        function obj = cumulative(obj, varargin)
            obj.cumulative_ = FigureBuilder.optional(true, false, varargin);
        end

        function obj = normalize(obj, varargin)
            obj.normalize_ = FigureBuilder.optional(true, false, varargin);
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
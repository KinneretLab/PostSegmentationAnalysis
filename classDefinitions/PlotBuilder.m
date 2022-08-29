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
        normalize_        % bool
        bins_             % int - 0 means no binning, -1 means automatic binning
        outliers_         % string
        x_lim_            % [double,double]
        y_lim_            % [double,double]
        sequence_         % bool
        legend_           % {chararr...}
    end

    methods(Static)
        function func = property(prop_name)
            func = BulkFunc(@(obj) ([obj.(prop_name)]));
        end

        function func = count(include_nan)
            if nargin == 1 && include_nan
                func = BulkFunc(@(obj_arr) (length(obj_arr)));
            else
                func = BulkFunc(@(obj_arr) (nnz(~isnan(obj_arr))));
            end
        end

        function func = mean(prop_name)
            func = BulkFunc(@(obj_arr, plotter) (nanmean(plotter.filter([obj_arr.(prop_name)]))));
        end

        function func = std(prop_name)
            func = BulkFunc(@(obj_arr, plotter) (nanstd(plotter.filter([obj_arr.(prop_name)]))));
        end
        
        function ret = smart_apply(func, varargin)
            ret = func(varargin{1:nargin(func)});
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
            obj.outliers_         = "none";
            obj.x_lim_            = [];
            obj.y_lim_            = [];
            obj.sequence_         = false;
            obj.legend_           = {};
        end
        
        function filtered_arr = filter(obj, raw_arr)
            if obj.outliers_ ~= "none"
                filtered_arr = raw_arr(~isoutlier(raw_arr, obj.outliers_));
            else
                filtered_arr = raw_arr;
            end
        end

        function [data_arrays, err_arrays, frame_data] = calculate(obj)
            if isa(obj.x_function_, 'BulkFunc')
                x_data = cellfun(@(obj_arr) obj.smart_apply(obj.x_function_, obj_arr, obj, obj_arr), obj.data_, 'UniformOutput', false);
            else
                x_data = cellfun(@(obj_arr) (arrayfun(@(o) obj.smart_apply(obj.x_function_, o, obj, obj_arr), obj_arr)), obj.data_, 'UniformOutput', false);
            end
            full_data = obj.data_;
            if obj.outliers_ ~= "none"
                out_filter = cellfun(@(obj_arr) (~isoutlier(obj_arr, obj.outliers_)), x_data, 'UniformOutput', false);
                x_data = cellfun(@(obj_arr, filter) (obj_arr(filter)), x_data, out_filter, 'UniformOutput', false);
                full_data = cellfun(@(obj_arr, filter) (obj_arr(filter)), full_data, out_filter, 'UniformOutput', false);
            end
            if obj.sequence_
                % get all frames in the data
                frame_data = unique(arrayfun(@(obj) ([obj.(obj.frameID)]), [full_data{:}]));
            else
                frame_data = -1;
            end
            data_arrays = cell(length(frame_data), 2 * length(full_data));
            err_arrays = cell(length(frame_data), 2 * length(full_data));
            for frame_idx = 1:length(frame_data)
                if obj.sequence_
                    f_filter = cellfun(@(obj_arr) ([obj_arr.(obj_arr.frameID)] == frame_data(frame_idx)), full_data, 'UniformOutput', false);
                end
                if obj.bins_ ~= 0 && obj.mode_ == "bar"
                    if obj.sequence_
                        hist_data = cellfun(@(x, filter) (x(filter)), x_data, filter);
                    else
                        hist_data = x_data;
                    end
                    if obj.bins_ == -1
                        [~, edges] = histcounts([hist_data{:}]);
                    else
                        [~, edges] = histcounts([hist_data{:}], obj.bins_);
                    end
                end
                for data_idx = 1:length(full_data)
                    data_sorted = containers.Map('KeyType','double','ValueType','any');
                    x_err_sorted = containers.Map('KeyType','double','ValueType','any');
                    y_err_sorted = containers.Map('KeyType','double','ValueType','any');
                    x_entry = x_data{data_idx};
                    data_entry = full_data{data_idx};
                    if obj.sequence_
                        x_entry = x_entry(f_filter{data_idx});
                        data_entry = data_entry(f_filter{data_idx});
                    end
                    if isempty(x_entry)
                        continue
                    end
                    if obj.bins_ == 0
                        x_values = unique(x_entry);
                        for bin_idx=1:length(x_values)
                            x_value = x_values(bin_idx);
                            if isnan(x_value) % don't analyze NaNs
                                continue
                            end
                            data_sorted(x_value) = data_entry(x_entry == x_value);
                        end
                    else
                        if obj.mode_ ~= "bar"
                            if obj.bins_ == -1
                                [~, edges] = histcounts(x_entry);
                            else
                                [~, edges] = histcounts(x_entry, obj.bins_);
                            end
                        end
                        bin_indices = discretize(x_entry, edges);
                        x_values = movmean(edges, 2);
                        for bin_idx=1:length(x_values)-1
                            x_value = x_values(bin_idx + 1);
                            data_sorted(x_value) = data_entry(bin_indices == bin_idx);
                        end
                    end
                    for key = data_sorted.keys
                        x_err_sorted(key{1}) = obj.smart_apply(obj.x_err_function_, data_sorted(key{1}), obj, data_entry);
                        y_err_sorted(key{1}) = obj.smart_apply(obj.y_err_function_, data_sorted(key{1}), obj, data_entry);
                        data_sorted(key{1}) = obj.smart_apply(obj.y_function_, data_sorted(key{1}), obj, data_entry);
                    end
                    x_result = data_sorted.keys;
                    y_result = data_sorted.values;
                    x_err_result = x_err_sorted.values;
                    y_err_result = y_err_sorted.values;
                    data_arrays{frame_idx, 2 * data_idx - 1} = [x_result{:}] .* obj.x_calibration_;
                    data_arrays{frame_idx, 2 * data_idx} = [y_result{:}] .* obj.y_calibration_;
                    err_arrays{frame_idx, 2 * data_idx - 1} = [x_err_result{:}] .* obj.x_calibration_;
                    err_arrays{frame_idx, 2 * data_idx} = [y_err_result{:}] .* obj.y_calibration_;
                end
            end
        end

        function fig_handle = draw(obj)
            [raw_data, err_data, frame_data] = obj.calculate;
            fig_handle = gobjects(1, size(raw_data, 1));
            x_limits = [];
            y_limits = [];
            for figure_idx = 1:size(raw_data, 1)
                fig_handle(figure_idx) = figure;
                hold on;
                if obj.cumulative_ % cumulative mode
                    for i=2:2:size(raw_data, 2)
                        raw_data{figure_idx, i} = cumsum(raw_data{figure_idx, i});
                    end
                end
                if obj.normalize_
                    if obj.cumulative_
                        raw_data(figure_idx, 2:2:end) = cellfun(@(obj_arr) (PlotBuilder.c_div(obj_arr)),raw_data(figure_idx, 2:2:end), 'UniformOutput', false);
                    else
                        if obj.bins_ ~= 0
                            bin_cell = cellfun(@(data_arr) mean(diff(data_arr)), raw_data(figure_idx, 1:2:end), 'UniformOutput', false);
                        else
                            bin_cell = num2cell(ones(size(raw_data(figure_idx, 1:2:end)))); % arbitrary
                        end
                        raw_data(figure_idx, 2:2:end) = cellfun(@(obj_arr, bin_size) (PlotBuilder.p_div(obj_arr,bin_size)),raw_data(figure_idx, 2:2:end),bin_cell, 'UniformOutput', false);
                    end
                end
                switch obj.mode_
                    case "line" % graphing mode
                        plot(raw_data{figure_idx, :});
                    case "scatter"
                        plot(raw_data{figure_idx, :},'LineStyle','none','Marker','.');
                    case "bar"
                        sizes = cellfun(@(obj_arr) (length(obj_arr)), raw_data(figure_idx, :));
                        if max(sizes(1:2:end)) ~= min(sizes(1:2:end))
                            disp("[ERROR] bar graphs can only be drawn if the data is uniform in size.");
                        end
                        bar(vertcat(raw_data{figure_idx, 1:2:end})',vertcat(raw_data{figure_idx, 2:2:end})');
                end
                if any([err_data{1:2:end}])
                    for i=1:2:size(raw_data, 2)
                        errorbar(raw_data{figure_idx, i:i+1},err_data{i},'horizontal','.');
                    end
                end
                if any([err_data{2:2:end}])
                    for i=2:2:size(raw_data, 2)
                        errorbar(raw_data{figure_idx, i-1:i},err_data{i},'.');
                    end
                end
                x_min = min([raw_data{figure_idx, 1:2:end}]); % add reference slopes
                x_max = max([raw_data{figure_idx, 1:2:end}]);
                x_range = x_min:(x_max-x_min)/100:x_max;
                for i=1:length(obj.reference_slopes_)
                    x_scaled = obj.reference_slopes_(i) * FigureBuilder.optional(log(x_range), x_range, {obj.x_log_scale_});
                    plot(x_range, FigureBuilder.optional(exp(x_scaled), x_scaled, {obj.y_log_scale_}),'--');
                end
                if any(frame_data == -1)
                    plot_title = obj.title_;
                else
                    plot_title = sprintf(obj.title_, frame_data(figure_idx));
                end
                title(plot_title, 'FontSize', obj.title_size_, 'FontWeight', obj.title_bold_, 'FontAngle', obj.title_italic_); % title stuff
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
                for line_idx = 1:length(obj.legend_) % ignore empty legend entries
                    if isempty(obj.legend_{line_idx})
                        % I have no idea why the line order is flipped...
                        fig_handle(figure_idx).Children.Children(1 + length(obj.legend_) - line_idx)...
                            .Annotation.LegendInformation.IconDisplayStyle = 'off';
                    end
                end
                if ~all(cellfun(@isempty, obj.legend_))
                    legend(obj.legend_{~cellfun(@isempty, obj.legend_)}, 'Location', 'best');
                end
                % get automatic limits
                if isempty(x_limits)
                    x_limits = xlim;
                else
                    cur_x_limits = xlim;
                    x_limits(1) = min([x_limits(1), cur_x_limits(1)]);
                    x_limits(2) = max([x_limits(2), cur_x_limits(2)]);
                end
                if isempty(y_limits)
                    y_limits = ylim;
                else
                    cur_y_limits = ylim;
                    y_limits(1) = min([y_limits(1), cur_y_limits(1)]);
                    y_limits(2) = max([y_limits(2), cur_y_limits(2)]);
                end
                hold off;
            end
            for fig = fig_handle
                figure(fig)
                if length(obj.x_lim_) == 2
                    xlim(obj.x_lim_)
                else
                    xlim(x_limits)
                end
                if length(obj.y_lim_) == 2
                    ylim(obj.y_lim_)
                else
                    ylim(y_limits)
                end
            end
        end
        
        function obj = addData(obj, entity_arr, name)
            obj.data_{end+1} = entity_arr;
            if nargin > 2
                obj.legend_{end+1} = name;
            else
                obj.legend_{end+1} = '';
            end
        end
        
        function obj = clearData(obj)
            obj.data_ = {};
            obj.legend_ = {};
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
                if length(varargin{1}) == 1 && varargin{1} < 0
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

        function obj = sequence(obj, varargin)
            obj.sequence_ = FigureBuilder.optional(true, false, varargin);
        end
        
        function obj = xFunction(obj, func)
            if isa(func, 'char') || isa(func, 'string')
                obj.x_function_ = PlotBuilder.property(func);
            end
            if isa(func, 'double')
                obj.x_function_ = @(obj) (func);
            end 
            if isa(func, 'function_handle') || isa(func, 'BulkFunc')
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
            if isa(func, 'function_handle') || isa(func, 'BulkFunc')
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
            if isa(func, 'function_handle') || isa(func, 'BulkFunc')
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
            if isa(func, 'function_handle') || isa(func, 'BulkFunc')
                obj.y_err_function_ = func;
            end
        end
        
        function obj = outliers(obj, algorithm)
            if nargin == 1
                obj.outliers_ = "median";
            else
                obj.outliers_ = algorithm;
            end
        end
        
        function obj = xLim(obj, limits)
            if nargin == 1
                obj.x_lim_ = [];
            else
                obj.x_lim_ = limits;
            end
        end
        
        function obj = yLim(obj, limits)
            if nargin == 1
                obj.y_lim_ = [];
            else
                obj.y_lim_ = limits;
            end
        end
    end
    
    methods (Static, Access = private)
        function arr = c_div(arr)
            if ~isempty(arr)
                arr = arr / arr(end);
            end
        end
        
        function arr = p_div(arr, binning)
            if ~isempty(arr)
                arr = arr / sum(arr) / binning;
            end
        end
    end
end
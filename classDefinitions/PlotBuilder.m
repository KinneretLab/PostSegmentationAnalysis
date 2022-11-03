  classdef PlotBuilder < FigureBuilder
    % PLOTBUILDER A tool used to draw the relationship between one of two
    % variables.
    %   In particular, the plot builder compares two aspects of a set of
    %   physical entities, and plots them on a graph.
    properties (Access = protected)
        % Decides what aspect will be used for the X coordinate.
        % type: double(PhysicalEntity) or its BulkFunc variant
        x_function_
        % Decides what aspect will be used for the error bars of the X coordinate.
        % type: double(PhysicalEntity[])
        x_err_function_
        % Controls the scaling on the X axis - lograithmic or linear.
        % type: boolean
        x_log_scale_
        % Controls the label for the X axis. Can be empty or filled.
        % type: string
        x_label_
        % Controls the size of the text put on the X axis.
        % type: int (>0)
        x_label_size_
        % Controls whether the X axis label should be bold.
        % type: boolean
        x_label_bold_
        % Controls whether the X axis label should be italicised.
        % type: boolean
        x_label_italic_
        % Controls the linear scale factor, or calibration of the X axis.
        % type: double
        x_calibration_
        % Controls the positions of the horizontal graph edges.
        % type: double[2]
        x_lim_
        % Decides what aspect will be used for the Y coordinate.
        % note that this is not the same as x_function_!
        % type: double(PhysicalEntity[])
        y_function_
        % Decides what aspect will be used for the error bars of the Y coordinate.
        % type: double(PhysicalEntity[])
        y_err_function_
        % Controls the scaling on the Y axis - lograithmic or linear.
        % type: boolean
        y_log_scale_
        % Controls the label for the Y axis. Can be empty or filled.
        % type: string
        y_label_
        % Controls the size of the text put on the Y axis.
        % type: int (>0)
        y_label_size_
        % Controls whether the Y axis label should be bold.
        % type: boolean
        y_label_bold_
        % Controls whether the Y axis label should be italicised.
        % type: boolean
        y_label_italic_
        % Controls the linear scale factor, or calibration of the Y axis.
        % type: double
        y_calibration_
        % Controls the positions of the vertical graph edges.
        % type: double[2]
        y_lim_
        % An additional filter to apply on the data before starting the calculation at all.
        % This is not neccesary (you can apply this beforehand in ADDDATA,
        % but is a very useful utility.
        % type: boolean[](PhysicalEntity[])
        filter_function_
        % Controls the type of grid displayed on the graph.
        % type: string
        grid_
        % The physical entities to draw in this plot.
        % The first layer is used to differentiate plots in the
        % graph (i.e different colors), and the second layer is used to lit
        % seperate entities within the same line.
        % type: PhysicalEntity[]{}
        data_             % {obj array...}
        % The type of graph to draw, i.e line, bar, scatter, etc.
        % type: string
        mode_
        % Controls whether each entry in the graph should sum previous entries.
        % type: boolean
        cumulative_
        % A list of additional, user-defined lines to draw in the graph.
        % As of now, you can only really control the slopes of the lines,
        % and it passes through 0.
        % type: double[]
        reference_slopes_
        % Controls whether all entries should sum up to 1 after summation.
        % type: boolean
        normalize_
        % Controls whether binning should be used in the plot, and which type.
        % type: usually int (-1 or 0), but can also be double[]
        bins_
        % Controls the algorithm used to filter out outliers.
        % type: string
        outliers_
        % Controls whether the builder should draw a graph per frame instead of a graph for all frames.
        % type: boolean
        sequence_
        % A list of names to display on an entry legend.
        % type: string[]
        legend_
        % Controls whether the graph should be invisible to users for efficiency.
        % type: string
        visibility_
    end
    
    properties (Constant)
        logger = Logger('PlotBuilder');
    end

    methods(Static)
        function func = property(prop_name)
            % PROPERTY a function that gets the corresponding property from the entity.
            %   This is a BULKFUNC, meaning it is extra fast as an X
            %   function.
            % by default, the X function is set to be
            % PLOTBUILDER.PROPERTY("frame")
            % returns: double[](PhysicalEntity[])
            func = BulkFunc(@(obj) (reshape([obj.(prop_name)], size(obj))));
        end

        function func = count(include_nan)
            % COUNT a function that counts the length of the input data.
            %   Its main purpose is to be used as a Y function.
            % COUNT(true) also counts NaN entries.
            % returns: double(PhysicalEntity[])
            if nargin == 1 && include_nan
                func = BulkFunc(@(obj_arr) (length(obj_arr)));
            else
                func = BulkFunc(@(obj_arr) (nnz(~isnan(obj_arr))));
            end
        end

        function func = mean(prop_name)
            % MEAN a function that gets the mean of corresponding property from the entities.
            %   Its main purpose is to be used as a Y function.
            % by default, the Y function is set to be
            % PLOTBUILDER.MEAN("frame")
            % returns: double(PhysicalEntity[])
            func = BulkFunc(@(obj_arr, plotter) (nanmean(plotter.filter([obj_arr.(prop_name)]))));
        end

        function func = std(prop_name)
            % STD a function that gets the standard deviation of corresponding property from the entities.
            %   Its main purpose is to be used as a X/Y error function.
            % returns: double(PhysicalEntity[])
            func = BulkFunc(@(obj_arr, plotter) (nanstd(plotter.filter([obj_arr.(prop_name)]))));
        end
        
        function func = logical(const_value)
            % STD a constant function that gets the standard deviation of corresponding property from the entities.
            %   It can be used for a few things, but it is used for error
            %   functions, and filtering.
            % returns: double[](PhysicalEntity[]) or int[](PhysicalEntity[])
            func = BulkFunc(@(entity_arr) const_value & true(size(entity_arr)));
        end
        
        function ret = smart_apply(func, varargin)
            % SMART_APPLY applies the function with the given arguments,
            % using only as many arguments as it is allowed to use.
            ret = func(varargin{1:nargin(func)});
        end
    end
    
    methods
        function obj = PlotBuilder()
            % Contructs a brand new plot builder with default settings.
            % this does not return an array of builders, nor should it.
            % Every command you run on this class copies a new
            % PLOTBUILDER with the apropriate settings.
            % returns: PlotBuilder
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
            obj.filter_function_  = PlotBuilder.logical(1);
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
            obj.visibility_       = "on";
        end
        
        function filtered_arr = filter(obj, raw_arr)
            % FILTER A utility function used to trigger outlier filtering
            % for user defined functions.
            % returns the same array type as the input.
            if obj.outliers_ ~= "none"
                filtered_arr = raw_arr(~isoutlier(raw_arr, obj.outliers_));
            else
                filtered_arr = raw_arr;
            end
        end

        function [data_arrays, err_arrays, frame_data] = calculate(obj)
            % CALCULATE the main function responsible for calculating the raw data to be drawn.
            % returns:
            %   data_arrays - the main array with the calculated data to
            %   plot. Use plot(data_arrays) to directly plot the data on a
            %   line graph.
            %   err_arrays - an additional cell array containing the error
            %   bars for the graph, with the format {xErr1, yErr1, xErr2, ...}
            %   frame_data - an array containing the frames used in a plot
            %   sequence to plot the data. For a single graph, this yields
            %   -1.
            % This method is used inside the PLOTBUILDER.DRAW method.
            
            % step 0: filter the data using the object filter provided
            % note: full_data is a cell array, where each cell is a list of
            % physical entities to put in the same graph.
            obj.logger.info('Calculate: Applying initial filter');
            if isa(obj.filter_function_, 'BulkFunc')
                % BulkFunc indicate that the data can be calculated using
                % an array function, which is much more efficient than a
                % for loop.
                full_data = cellfun(@(phys_arr) phys_arr(obj.filter_function_(phys_arr)), obj.data_, 'UniformOutput', false);
            else
                % the slow variant for filtering, which
                % does an iteration over all entries. Can take a while.
                full_data = cellfun(@(phys_arr) arrayfun(@(phys) phys_arr(obj.filter_function_(phys))), obj.data_, 'UniformOutput', false);
            end
            % step 1: calculate the x coordinate of all points.
            % this can be used to sort the data out.
            obj.logger.info('Calculate: calculating X values');
            if isa(obj.x_function_, 'BulkFunc')
                % BulkFunc indicate that the data can be calculated using
                % an array function, which is much more efficient than a
                % for loop.
                x_data = cellfun(@(obj_arr) obj.smart_apply(obj.x_function_, obj_arr, obj, obj_arr), full_data, 'UniformOutput', false);
            else
                % the slow variant for calculating x coordinates, which
                % does an iteration over all entries. Can take a while.
                x_data = cellfun(@(obj_arr) (arrayfun(@(o) obj.smart_apply(obj.x_function_, o, obj, obj_arr), obj_arr)), full_data, 'UniformOutput', false);
            end
            % outlier filtering, which depends on the mode.
            if obj.outliers_ ~= "none"
                obj.logger.info('Calculate: Filtering outliers');
                % get the outlier flags for each set of points on the
                % graph, then use it to filter out the points (both the x
                % data and the actual data itself)
                out_filter = cellfun(@(obj_arr) (~isoutlier(obj_arr, obj.outliers_)), x_data, 'UniformOutput', false);
                x_data = cellfun(@(obj_arr, filter) (obj_arr(filter)), x_data, out_filter, 'UniformOutput', false);
                full_data = cellfun(@(obj_arr, filter) (obj_arr(filter)), full_data, out_filter, 'UniformOutput', false);
            end
            % get a list of all the frames available in the data, to be
            % used when we run over a sequence.
            % Otherwise, set to -1.
            if obj.sequence_
                % get all frames in the data
                frame_data = unique(arrayfun(@(obj) ([obj.(obj.frameID)]), [full_data{:}]));
            else
                frame_data = -1;
            end
            data_arrays = cell(length(frame_data), 2 * length(full_data));
            err_arrays = cell(length(frame_data), 2 * length(full_data));
            % since for a sequence we are plotting one graph per frame, we
            % need to iterate over each frame first.
            last_log_time = datetime('now');
            for frame_idx = 1:length(frame_data)
                if obj.sequence_
                    % figure out which entities should be included in this
                    % particular graph - only those with the expected
                    % frame.
                    f_filter = cellfun(@(obj_arr) ([obj_arr.(obj_arr.frameID)] == frame_data(frame_idx)), full_data, 'UniformOutput', false);
                end
                % if we are using a bar graph (with binning, of course), we
                % should descretize the data now to prevent the bar plot
                % from crashing due to mismatches.
                if obj.bins_ ~= 0 && obj.mode_ == "bar"
                    % frame filter the x data for binning
                    if obj.sequence_
                        hist_data = cellfun(@(x, filter) (x(filter)), x_data, filter);
                    else
                        hist_data = x_data;
                    end
                    % get the bin edges. obj.bins_ = -1 indicated an automatic
                    % algorithm, while anything else indicates some user
                    % defined settings.
                    if obj.bins_ == -1
                        [~, edges] = histcounts([hist_data{:}]);
                    else
                        [~, edges] = histcounts([hist_data{:}], obj.bins_);
                    end
                end
                % now we can iterate over each set of entities to form a
                % graph
                for data_idx = 1:length(full_data)
                    % we store the result data in map containers -
                    % efficient data structures with the ability to sort
                    % the data by name instead of index.
                    data_sorted = containers.Map('KeyType','double','ValueType','any');
                    x_err_sorted = containers.Map('KeyType','double','ValueType','any');
                    y_err_sorted = containers.Map('KeyType','double','ValueType','any');
                    % get relevant data via filtering and indexing.
                    x_entry = x_data{data_idx};
                    data_entry = full_data{data_idx};
                    if obj.sequence_
                        x_entry = x_entry(f_filter{data_idx});
                        data_entry = data_entry(f_filter{data_idx});
                    end
                    if isempty(x_entry) % if there is nothing here, move on.
                        continue
                    end
                    if obj.bins_ == 0
                        % if there is no binning, group entities only if
                        % they have the exact same X value.
                        x_values = unique(x_entry);
                        for bin_idx=1:length(x_values)
                            x_value = x_values(bin_idx);
                            if isnan(x_value) % don't analyze NaNs
                                continue
                            end
                            data_sorted(x_value) = data_entry(x_entry == x_value);
                        end
                    else
                        % if we ar not in a bar graph, but we are binning,
                        % we should discretize now to ensure the graph
                        % doesn't have unneccesary fluctuations.
                        if obj.mode_ ~= "bar"
                            % get the bin edges. obj.bins_ = -1 indicated an automatic
                            % algorithm, while anything else indicates some user
                            % defined settings.
                            if obj.bins_ == -1
                                [~, edges] = histcounts(x_entry);
                            else
                                [~, edges] = histcounts(x_entry, obj.bins_);
                            end
                        end
                        % we plot the binned points at the center of their
                        % respective bin (in the X coordinate)
                        x_values = movmean(edges, 2);
                        % iterate over the discretized points and group
                        % them based on the bin they belong to.
                        bin_indices = discretize(x_entry, edges);
                        for bin_idx=1:length(x_values)-1
                            x_value = x_values(bin_idx + 1);
                            data_sorted(x_value) = data_entry(bin_indices == bin_idx);
                        end
                    end
                    % iterate over the available points and calculate the
                    % other stuff for them: Y,X_err,Y_err.
                    % Y is done last because it overrides the list of
                    % entries.
                    if seconds(datetime('now') - last_log_time) > 60 || frame_idx * data_idx == 1 || (frame_idx == length(frame_data) && data_idx == length(full_data))
                        obj.logger.info('Calculate: calculating Y,X_err,Y_err for frame (%d/%d), experiment (%d/%d)', frame_idx, length(frame_data), data_idx, length(full_data));
                        last_log_time = datetime('now');
                    end
                    for key = data_sorted.keys
                        x_err_sorted(key{1}) = obj.smart_apply(obj.x_err_function_, data_sorted(key{1}), obj, data_entry);
                        y_err_sorted(key{1}) = obj.smart_apply(obj.y_err_function_, data_sorted(key{1}), obj, data_entry);
                        data_sorted(key{1}) = obj.smart_apply(obj.y_function_, data_sorted(key{1}), obj, data_entry);
                    end
                    % technical syntax, used to move the data into the
                    % correct cell arrays in the correct position (see main
                    % documentation)
                    x_result = data_sorted.keys;
                    y_result = data_sorted.values;
                    x_result = [x_result{:}];
                    y_result = [y_result{:}];
                    x_err_result = x_err_sorted.values;
                    y_err_result = y_err_sorted.values;
                    data_arrays{frame_idx, 2 * data_idx - 1} = x_result .* obj.x_calibration_;
                    data_arrays{frame_idx, 2 * data_idx} = y_result .* obj.y_calibration_;
                    err_arrays{frame_idx, 2 * data_idx - 1} = [x_err_result{:}] .* obj.x_calibration_;
                    err_arrays{frame_idx, 2 * data_idx} = [y_err_result{:}] .* obj.y_calibration_;
                end
            end
        end

        function fig_handle = draw(obj)
            % DRAW the main function responsible for drawing the data with the user-set configurations.
            % returns: a figure handle (or list of figure handles if this
            % is a sequence) to the figure rawn by this method.
            
            % get the data, and prepare other stuff.
            [raw_data, err_data, frame_data] = obj.calculate;
            fig_handle = gobjects(1, size(raw_data, 1));
            x_limits = [];
            y_limits = [];
            % obviously, we want to itrate over the figures we are about to
            % draw.
            obj.logger.info('Draw: starting to draw figures');
            for figure_idx = 1:size(raw_data, 1)
                % create a new figure, with the visibility set accordingly.
                fig_handle(figure_idx) = figure('visible',obj.visibility_);
                hold on;
                % If we are in cumulative mode, edit the y data so that
                % each entry is the sum of the previous ones (without cumulative).
                if obj.cumulative_
                    % as stated before, the evens are the y data, and the
                    % odds are the x.
                    for i=2:2:size(raw_data, 2)
                        raw_data{figure_idx, i} = cumsum(raw_data{figure_idx, i});
                    end
                end
                if obj.normalize_
                    if obj.cumulative_
                        % normalizing the data in cumlative mode is easy,
                        % just divide the data by the last entry in each
                        % graph.
                        raw_data(figure_idx, 2:2:end) = cellfun(@(obj_arr) (PlotBuilder.c_div(obj_arr)),raw_data(figure_idx, 2:2:end), 'UniformOutput', false);
                    else
                        % in non-cumulative normalization, we need to sum the data up.
                        % If we have binning (obj.bins_~=0), it would make more sense to
                        % normalize the data by the total *area*, which is
                        % the bin size times the sum(Y)
                        % in non-binned mode, we just need to divide by
                        % sum(Y).
                        % this control block just defines the binning.
                        if obj.bins_ ~= 0
                            bin_cell = cellfun(@(data_arr) mean(diff(data_arr)), raw_data(figure_idx, 1:2:end), 'UniformOutput', false);
                        else
                            bin_cell = num2cell(ones(size(raw_data(figure_idx, 1:2:end)))); % arbitrary
                        end
                        % this line simple applies the division.
                        raw_data(figure_idx, 2:2:end) = cellfun(@(obj_arr, bin_size) (PlotBuilder.p_div(obj_arr,bin_size)),raw_data(figure_idx, 2:2:end),bin_cell, 'UniformOutput', false);
                    end
                end
                % actually plot the data, according to the mode.
                switch obj.mode_
                    case "line"
                        plot(raw_data{figure_idx, :});
                    case "scatter"
                        plot(raw_data{figure_idx, :},'LineStyle','none','Marker','.');
                    case "bar"
                        % sanity check - the data should have an equal
                        % amount of x coordinates. Only really guaranteed
                        % with binning enabled.
                        sizes = cellfun(@(obj_arr) (length(obj_arr)), raw_data(figure_idx, :));
                        if max(sizes(1:2:end)) ~= min(sizes(1:2:end))
                            disp("[ERROR] bar graphs can only be drawn if the data is uniform in size.");
                        end
                        % convert cell array to matrix and draw in a bar
                        % graph.
                        bar(vertcat(raw_data{figure_idx, 1:2:end})',vertcat(raw_data{figure_idx, 2:2:end})');
                end
                % add X error bars
                if any([err_data{1:2:end}])
                    for i=1:2:size(raw_data, 2)
                        errorbar(raw_data{figure_idx, i:i+1},err_data{i},'horizontal','.');
                    end
                end
                % add Y error bars
                if any([err_data{2:2:end}])
                    for i=2:2:size(raw_data, 2)
                        errorbar(raw_data{figure_idx, i-1:i},err_data{i},'.');
                    end
                end
                % to draw the reference slopes, we first need to know where
                % to draw them - we do this by finding the maximum range
                % for x
                x_min = min([raw_data{figure_idx, 1:2:end}]); % add reference slopes
                x_max = max([raw_data{figure_idx, 1:2:end}]);
                % get the sampling points: 100 points should do the job.
                x_range = x_min:(x_max-x_min)/100:x_max;
                % iterate over the required slopes and add them to the
                % plot.
                for i=1:length(obj.reference_slopes_)
                    x_scaled = obj.reference_slopes_(i) * FigureBuilder.optional(log(x_range), x_range, {obj.x_log_scale_});
                    plot(x_range, FigureBuilder.optional(exp(x_scaled), x_scaled, {obj.y_log_scale_}),'--');
                end
                % if this is a plot sequence, %d gains a special effect -
                % it will be replaced by the frame number.
                if any(frame_data == -1)
                    plot_title = obj.title_;
                else
                    plot_title = sprintf(obj.title_, frame_data(figure_idx));
                end
                % draw title, x label, y label, according to the set
                % configurations.
                title(plot_title, 'FontSize', obj.title_size_, 'FontWeight', obj.title_bold_, 'FontAngle', obj.title_italic_); % title stuff
                if "" ~= obj.x_label_
                    xlabel(obj.x_label_, 'FontSize', obj.x_label_size_, 'FontWeight', obj.x_label_bold_, 'FontAngle', obj.x_label_italic_); % x axis stuff
                end
                if "" ~= obj.y_label_
                    ylabel(obj.y_label_, 'FontSize', obj.y_label_size_, 'FontWeight', obj.y_label_bold_, 'FontAngle', obj.y_label_italic_); % y axis stuff
                end
                % set logarithmic scaling of X and Y.
                if obj.x_log_scale_ % x log scale
                    set(gca, 'xscale','log')
                end
                if obj.y_log_scale_ % y log scale
                    set(gca, 'yscale','log')
                end
                % add a grid if requested.
                grid (obj.grid_); % grid mode
                % add legend - hide empty entries.
                for line_idx = 1:length(obj.legend_) % ignore empty legend entries
                    if isempty(obj.legend_{line_idx})
                        % I have no idea why the line order is flipped...
                        % this line directs the legend entry for this
                        % particular line to be completely hidden.
                        fig_handle(figure_idx).Children.Children(1 + length(obj.legend_) - line_idx)...
                            .Annotation.LegendInformation.IconDisplayStyle = 'off';
                    end
                end
                % add a legend if data has legend names at all. The
                % previous block did the pre-work.
                if ~all(cellfun(@isempty, obj.legend_))
                    legend(obj.legend_{~cellfun(@isempty, obj.legend_)}, 'Location', 'best');
                end
                % get automatic limits, and save the largest range in a
                % shared parameter.
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
            % re-iterate over the figures now that we know what the XY
            % limits should be, and apply the correct limits.
            obj.logger.info('Draw: adjusting X,Y limits');
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
                % figure(fig) for some reason sets the figure to be visible
                % again, so this re-hides it.
                set(fig, 'visible', obj.visibility_); 
            end
        end
        
        function obj = addData(obj, entity_arr, name)
            % ADDDATA Queue a set of physical entities to be drawn by this plotter.
            % Parameters:
            %   entity_err: PhysicalEntity[]
            %      this is the data queued to get a plot
            %   name (optional): string or char[]
            %      When specified, adds this data to the legend with the
            %      corresponding name. Otherwise, skipped in the legend.
            obj.data_{end+1} = entity_arr;
            if nargin > 2
                obj.legend_{end+1} = name;
            else
                obj.legend_{end+1} = '';
            end
        end
        
        function obj = clearData(obj)
            % CLEARDATA Purge all data (not settings) from this plotter.
            % Useful if you want to use the same configurations on many
            % data entries.
            obj.data_ = {};
            obj.legend_ = {};
        end
        
        function obj = grid(obj, grid_type)
            % GRID Add a grid to the plot.
            % Parameters:
            %   grid_type (Optional): string or char[]
            %      the type of grid to draw.
            %      "off" (default): don't draw a grid.
            %      "on"  (no args): draw the major grid-lines.
            %      "minor"        : draw both major and minor grid-lines.
            if nargin == 1
                obj.grid_ = "on";
            else
                if ismember(grid_type, ["off", "on", "minor"])
                    obj.grid_ = grid_type;
                end
            end
        end

        function obj = mode(obj, mode_name)
            % MODE Set the type of plot to be drawn.
            % Parameters:
            %   mode_name: string or char[]
            %      the type of grid to draw.
            %      "line" (default): draw a connected line plot.
            %      "scatter"       : draw a scatter plot, which is many unconnected points.
            %      "bar"           : draw a bar graph, which is a bunch of side-by-side rectangles with varying heights.
            if ismember(mode_name, ["scatter", "bar", "line"])
                obj.mode_ = mode_name;
            end
        end
        
        function obj = distribution(obj, varargin)
            % DISTRIBUTION Applies both NORMALIZE and BINNING.
            % Parameters:
            %   varargin: int or double[]
            %      Additional configurations for the binning algorithm.
            %      0  (default): don't use binning
            %      -1 (no args): use the automatic binning algorithm
            %      anything else just applies the matlab defined configurations.
            obj = obj.normalize.binning(varargin{:});
        end
        
        function obj = binning(obj, varargin)
            % BINNING Descretizes the data for better visualization.
            % Parameters:
            %   varargin: int or double[]
            %      Additional configurations for the binning algorithm.
            %      0  (default): don't use binning
            %      -1 (no args): use the automatic binning algorithm
            %      anything else just applies the matlab defined configurations.
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
            % REFERENCESLOPES Add additional straight lines to draw in the graph.
            % As of now, you can only really control the slopes of the
            % lines. Each line passes through 0.
            % Parameters:
            %   slope_arr: double[]
            %      a the slopes to use for each reference line. The length
            %      of this array is the number of references to add.
            obj.reference_slopes_ = slope_arr;
        end

        function obj = xCalibration(obj, calib)
            % XCALIBRATION Set the linear scaling factor for the X axis.
            % Mostly useful to convert pixels to SI.
            % Parameters:
            %   calib: double
            %      the scaling value to multiply the pixels by. That is,
            %      final_coord = calib * pixel_coord;
            obj.x_calibration_ = calib;
        end
        
        function obj = yCalibration(obj, calib)
            % YCALIBRATION Set the linear scaling factor for the Y axis.
            % Mostly useful to convert pixels to SI.
            % Parameters:
            %   calib: double
            %      the scaling value to multiply the pixels by. That is,
            %      final_coord = calib * pixel_coord;
            obj.y_calibration_ = calib;
        end

        function obj = xSize(obj, size)
            % XSIZE set the font size of the X axis label.
            % Parameters:
            %   size: int
            %      the new size for the font. Default is 12.
            obj.x_label_size_ = size;
        end

        function obj = xBold(obj, varargin)
            % XBOLD whether the X axis label should be bold.
            % Parameters:
            %   varargin: boolean
            %      false (default): the label has default emphasis.
            %      true  (no args): the label has bold emphasis.
            obj.x_label_bold_ = FigureBuilder.optional('bold', 'normal', varargin);
        end

        function obj = xItalic(obj, varargin)
            % XITALIC whether the X axis label should be italicised.
            % Parameters:
            %   varargin: boolean
            %      false (default): the label is straight.
            %      true  (no args): the label is italicised.
            obj.x_label_talic_ = FigureBuilder.optional('italic', 'normal', varargin);
        end

        function obj = xAxis(obj, text)
            % XAXIS Adds a name (a label) to the X axis.
            % LaTeX formatting is allowed.
            % Parameters:
            %   text: string
            %      the text to use for the axis label. If empty, label is
            %      cleared.
            obj.x_label_ = text;
        end

        function obj = ySize(obj, size)
            % YSIZE set the font size of the Y axis label.
            % Parameters:
            %   size: int
            %      the new size for the font. Default is 12.
            obj.y_label_size_ = size;
        end

        function obj = yBold(obj, varargin)
            % YBOLD whether the Y axis label should be bold.
            % Parameters:
            %   varargin: boolean
            %      false (default): the label has default emphasis.
            %      true  (no args): the label has bold emphasis.
            obj.y_label_bold_ = FigureBuilder.optional('bold', 'normal', varargin);
        end

        function obj = yItalic(obj, varargin)
            % YITALIC whether the Y axis label should be italicised.
            % Parameters:
            %   varargin: boolean
            %      false (default): the label is straight.
            %      true  (no args): the label is italicised.
            obj.y_label_talic_ = FigureBuilder.optional('italic', 'normal', varargin);
        end

        function obj = yAxis(obj, text)
            % YAXIS Adds a name (a label) to the Y axis.
            % LaTeX formatting is allowed.
            % Parameters:
            %   text: string
            %      the text to use for the axis label. If empty, label is
            %      cleared.
            obj.y_label_ = text;
        end

        function obj = xLogScale(obj, varargin)
            % XLOGSCALE Set whether the X axis should be logarithmically scaled.
            % Parameters:
            %   varargin: boolean
            %      false (default): linear scaling.
            %      true  (no args): logairthmic scaling.
            obj.x_log_scale_ = FigureBuilder.optional(true, false, varargin);
        end

        function obj = yLogScale(obj, varargin)
            % YLOGSCALE Set whether the Y axis should be logarithmically scaled.
            % Parameters:
            %   varargin: boolean
            %      false (default): linear scaling.
            %      true  (no args): logairthmic scaling.
            obj.y_log_scale_ = FigureBuilder.optional(true, false, varargin);
        end

        function obj = cumulative(obj, varargin)
            % CUMULATIVE Set whether the data should be cumulative
            % that is, each entry in the plot is the sum of the original
            % elements and the entries before it. This modifies the Y data,
            % but nothing else.
            % Parameters:
            %   varargin: boolean
            %      false (default): no summation applied.
            %      true  (no args): data is summed cumulatively.
            obj.cumulative_ = FigureBuilder.optional(true, false, varargin);
        end

        function obj = normalize(obj, varargin)
            % NORMALIZE Set whether the data should be normalized
            % that is, the Y data should be linearly scaled such that the
            % sum of the data (or the total area in some cases) is exactly
            % 1. Useful for distributions.
            % Parameters:
            %   varargin: boolean
            %      false (default): no normalization applied.
            %      true  (no args): data is normalized, that is, it will sum up to 1.
            obj.normalize_ = FigureBuilder.optional(true, false, varargin);
        end

        function obj = sequence(obj, varargin)
            % SEQUENCE Instead of drawing one graph, partition the data to plot one graph for each available frame in the data.
            % Particularly useful to determine how a graph evolves over
            % time. This also synchronizes things like the boundries and
            % binning for bar graphs so you don't have to.
            % Parameters:
            %   varargin: boolean
            %      false (default): a single graph is drawn.
            %      true  (no args): draw multiple graphs, one per frame.
            obj.sequence_ = FigureBuilder.optional(true, false, varargin);
        end

        function obj = invisible(obj, varargin)
            % INVISIBLE Disable figure visibility to ensure that the user cannot interefere with the drawing.
            % this setting also increases efficiency.
            % Parameters:
            %   varargin: boolean
            %      false (default): all graphs are visible to the viewer
            %      throughout the entire drawing process.
            %      true  (no args): all graphs will remain invisible unless explicitly set to visible afterwards.
            obj.visibility_ = FigureBuilder.optional('off', 'on', varargin);
        end
        
        function obj = xFunction(obj, func)
            % XFUNCTION Choose how to calculate the X coordinate of the data.
            % This function is used to calculate for each set added by
            % PLOTBUILDER.ADDDATA the set of X coordinates for each point,
            % which is used throught the process.
            % Parameters:
            %   func: char[], string, double, function, BulkFunc
            %      The function (or property name) to use to determine the
            %      X coordinate.
            %      All types will be translated into some form of
            %      double(PhysicalEntity).
            %      double: this is translated into the constant function. 
            %      For example, for f = XFUNCTION(1):
            %         f(entity) = 1
            %      char[] or string: this is translated into a function
            %      fetching the corresponding property. 
            %      For example, for f = XFUNCTION("frame"):
            %         f(entity) = 
            %      function: this is simply set. Function must accept a
            %      PhysicalEntity and return a double.
            %      For example, for f = XFUNCTION(myFunction):
            %         f(entity) = myFunction(entity)
            %      BulkFunc: Like a function, this is simply set, but the 
            %      class name indicated the functino is capable of
            %      processing multiple entities. Therefore, it should
            %      accept an array of PhysicalEntity and return a double
            %      array of the same size (double[](PhysicalEntity[])).
            %      For example, for f = XFUNCTION(myBulkFunction):
            %         f(entity_arr) = myFunction(entity_arr)
            %      Default: PLOTBUILDER.PROPERTY("frame")
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
            % YFUNCTION Choose how to calculate the Y coordinate of the data sorted by the X coordinate.
            % Parameters:
            %   func: char[], string, double, function, BulkFunc
            %      The function (or property name) to use to determine the
            %      Y coordinate.
            %      All types will be translated into some form of
            %      double(PhysicalEntity[]).
            %      double: this is translated into the constant function. 
            %      For example, for f = YFUNCTION(1):
            %         f(entity_arr) = 1
            %      char[] or string: this is translated into a function
            %      fetching the mean of the corresponding property. 
            %      For example, for f = YFUNCTION("frame"):
            %         f(entity_arr) = mean([entity_arr.frame])
            %      function or BulkFunc: this is simply set. Function must accept a
            %      PhysicalEntity array and return a double.
            %      For example, for f = YFUNCTION(myFunction):
            %         f(entity_arr) = myFunction(entity_arr)
            %      Default: PLOTBUILDER.COUNT
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
            % XERRFUNCTION Choose how to calculate the X error bar of the data sorted by the X coordinate.
            % Parameters:
            %   func: char[], string, double, function, BulkFunc
            %      The function (or property name) to use to determine the
            %      X error bar.
            %      All types will be translated into some form of
            %      double(PhysicalEntity[]).
            %      double: this is translated into the constant function. 
            %      For example, for f = XERRFUNCTION(1):
            %         f(entity_arr) = 1
            %      char[] or string: this is translated into a function
            %      fetching the standard deviation of the corresponding property. 
            %      For example, for f = XERRFUNCTION("frame"):
            %         f(entity_arr) = std([entity_arr.frame])
            %      function or BulkFunc: this is simply set. Function must accept a
            %      PhysicalEntity array and return a double.
            %      For example, for f = XERRFUNCTION(myFunction):
            %         f(entity_arr) = myFunction(entity_arr)
            %      Default: the zero function: @(entity_arr) 0
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
            % YERRFUNCTION Choose how to calculate the Y error bar of the data sorted by the X coordinate.
            % Parameters:
            %   func: char[], string, double, function, BulkFunc
            %      The function (or property name) to use to determine the
            %      Y error bar.
            %      All types will be translated into some form of
            %      double(PhysicalEntity[]).
            %      double: this is translated into the constant function. 
            %      For example, for f = YERRFUNCTION(1):
            %         f(entity_arr) = 1
            %      char[] or string: this is translated into a function
            %      fetching the standard deviation of the corresponding property. 
            %      For example, for f = YERRFUNCTION("frame"):
            %         f(entity_arr) = std([entity_arr.frame])
            %      function or BulkFunc: this is simply set. Function must accept a
            %      PhysicalEntity array and return a double.
            %      For example, for f = YERRFUNCTION(myFunction):
            %         f(entity_arr) = myFunction(entity_arr)
            %      Default: the zero function: @(entity_arr) 0
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
        
        function obj = filterFunction(obj, func)
            % FILTERFUNCTION Add a filter to apply on the data before starting the calculation at all.
            % This is not neccesary (you can apply this beforehand in ADDDATA,
            % but is a very useful utility.
            % Parameters:
            %   func: char[], string, double, function, BulkFunc
            %      The function (or property name) to use to determine the
            %      data to keep for the calculation (1 is keep, 0 is
            %      ignore).
            %      All types will be translated into some form of
            %      boolean[](PhysicalEntity[]).
            %      no args: the true function: @(entity_arr) ones(size(entity_arr))
            %      logical or double: this is translated into the constant function. 
            %      For example, for f = FILTERFUNCTION(false):
            %         f(entity_arr) = false(size(entity_arr))
            %      char[] or string: this is translated into a function as
            %      if it is literal MATLAB code. You can refer to the input
            %      array using "obj_arr".
            %      For example, for f = FILTERFUNCTION("[obj_arr.confidence] > 0.5"):
            %         f(entity_arr) = [entity_arr.confidence] > 0.5
            %      function or BulkFunc: this is simply set. Function must accept a
            %      PhysicalEntity[] array and return a boolean[].
            %      For example, for f = FILTERFUNCTION(myFunction):
            %         f(entity_arr) = myFunction(entity_arr)
            %      Default: the true function: @(entity_arr) ones(size(entity_arr))
            if nargin == 0
                obj.filter_function_ = PlotBuilder.logical(true);
            else
                if isa(func, 'char') || isa(func, 'string')
                    if ~contains(func, "obj_arr")
                        warning("[WARN] your filter string does not contain obj_arr. This probably will lead to errors.");
                    end
                    obj.filter_function_ = BulkFunc(@(obj_arr) eval(func)); % WARNING: do NOT rename obj_arr!
                end
                if isa(func, 'logical') || isa(func, 'double')
                    obj.filter_function_ = PlotBuilder.logical(logical(func));
                end 
                if isa(func, 'function_handle') || isa(func, 'BulkFunc')
                    obj.filter_function_ = func;
                end
            end
        end
        
        function obj = outliers(obj, algorithm)
            % OUTLIERS Allow the plotter to filter out outliers using existing algorithms.
            % Parameters:
            %   algorithm: string
            %      the algorithm to use out outlier filtering. Default is
            %      "median".
            if nargin == 1
                obj.outliers_ = "median";
            else
                obj.outliers_ = algorithm;
            end
        end
        
        function obj = xLim(obj, limits)
            % XLIM Provide horizontal contraints for the region of intrest of the figure.
            % Parameters:
            %   limits (Optional): [double, double]
            %      If left empty, resets to automatic limits.
            %      Otherwise, sets the boundaries for the figure's X
            %      coordinate to uhose provided.
            if nargin == 1
                obj.x_lim_ = [];
            else
                obj.x_lim_ = limits;
            end
        end
        
        function obj = yLim(obj, limits)
            % YLIM Provide vertical contraints for the region of intrest of the figure.
            % Parameters:
            %   limits (Optional): [double, double]
            %      If left empty, resets to automatic limits.
            %      Otherwise, sets the boundaries for the figure's Y
            %      coordinate to uhose provided.
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
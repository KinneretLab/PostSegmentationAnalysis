classdef PlotUtils
    % PLOTUTILS Additional commonly used functions to be used in the PLOTBUILDER
    %   This is a set of non-base functions that extend the functionality
    %   available on PlotBuilder
    
    methods (Static)
        function func = axify(base, axis)
            % AXIFY automatically shift a function for the X axis to work with other axes (or the default treatment of them)
            % Parameters:
            %   base: char[], string, double, function, BulkFunc
            %      The original function (or property name) to axify
            %      All types will be translated into some form of
            %      double(PhysicalEntity).
            %   axis: string
            %      "x": identity, does nothing
            %      "y": applies a mean on the result of the function
            %      "err": find the standard deviation for the result of the
            %      function.
            if isa(base, 'char') || isa(base, 'string')
                base = PlotBuilder.property(base);
            end
            if nargin == 2
                switch axis
                    case "x"
                        func = base;
                    case "y"
                        func = @(cell_arr, plotter) (nanmean(plotter.filter(base(cell_arr))));
                    case "err"
                        func = @(cell_arr, plotter) (nanstd(plotter.filter(base(cell_arr))));
                end
            else
                func = base;
            end
        end
        
        function func = shape(axis)
            % SHAPE The shape property of the cell
            % Parameters:
            %   axis (Optional): string
            %      "x" (default): gets the function without modifications
            %      "y": applies a mean on the result of the function
            %      "err": find the standard deviation for the result of the
            %      function.
            func = @(cell) reshape([cell.perimeter] ./ sqrt([cell.area]), size(cell));
            if nargin == 1
                func = PlotUtils.axify(func, axis);
            end
            func = BulkFunc(func);
        end
        
        function func = cellFiberAngle(axis)
            % CELLFIBERANGLE The angle between cell elongation and fibers
            % on the tangential plane
            % Parameters:
            %   axis (Optional): string
            %      "x" (default): gets the function without modifications
            %      "y": applies a mean on the result of the function
            %      "err": find the standard deviation for the result of the
            %      function.
            
            orientCellAngle =  @(cell)( mod(atan([cell.elong_yy]./[cell.elong_xx])+pi,pi)); % projected cell orientation from the projected elongation vector
            projDifOrient  =  @(cell)( min(abs([cell.fibre_orientation]-  orientCellAngle(cell) ),pi-abs([cell.fibre_orientation]-orientCellAngle(cell)))); % differnece between fiber angle and cell angle on projected xy plane
            func =  @(cell) reshape(mod(atan(tan (projDifOrient(cell)).*abs([cell.norm_z])),pi), size(cell)); % real angle of cell orientation  vs fiber in tangential plane

            if nargin == 1
                func = PlotUtils.axify(func, axis);
            end
            func = BulkFunc(func);
        end
        
        function func = numNeighbors(axis)
            % NUMNEIGHBORS The number of neighbors the cell has
            % Parameters:
            %   axis (Optional): string
            %      "x" (default): gets the function without modifications
            %      "y": applies a mean on the result of the function
            %      "err": find the standard deviation for the result of the
            %      function.
            func =  @(cell_arr) reshape(sum(~isnan(cell_arr.neighbors), 2)', size(cell_arr));
            if nargin == 1
                func = PlotUtils.axify(func, axis);
            end
            func = BulkFunc(func);
        end

        function func = numBonds(axis)
            % NUMNEIGHBORS The number of bonds the entity (cell, vertex, true vertex, etc.) has
            % Parameters:
            %   axis (Optional): string
            %      "x" (default): gets the function without modifications
            %      "y": applies a mean on the result of the function
            %      "err": find the standard deviation for the result of the
            %      function.
            func =  @(entity_arr) reshape(sum(~isnan(entity_arr.bonds), 2)', size(entity_arr));
            if nargin == 1
                func = PlotUtils.axify(func, axis);
            end
            func = BulkFunc(func);
        end
        
        
        function func = xNormalize(x_function, t_prequisite)
            % normalize the result of x_function by the mean of the entities that share a property (sibilings).
            % This is only really relevant for the xFunction.
            % Parameters:
            %   x_function: char[], string, double(PhysicalEntity), or BulkFunc
            %      this is the aspect of the entity we want to normalize
            %      and display.
            %   t_prequisite: char[], string, boolean(PhysicalEntity[], PhysicalEntity)
            %      the function to use to find the sibilings of the given
            %      object.
            %      The choice of function can be very important, as this
            %      decides how efficient this program will be.
            %      char[], string (and BulkFunc once that's implemented) yield the fastest methods
            %      double(PhysicalEntity) is fast, but not optimal
            %      boolean(PhysicalEntity[], PhysicalEntity) is incredibly
            %      slow and should be avoided.
            if isa(x_function, 'char') || isa(x_function, 'string')
                x_function = PlotBuilder.property(x_function);
            end
            map = containers.Map;
            mean_function = @(obj_arr)(nanmean(x_function(obj_arr)));
            func = @(obj, ~, obj_arr) (x_function(obj) / PlotUtils.getOrStore(obj, obj_arr, map, t_prequisite, mean_function));
        end
        
        function func = divide(arr, idx_function, x_function, axis)
            % DIVIDE upgrades xFunction to also divide by an entry in an array according to some criterion
            % Parameters:
            %   arr: double[]
            %      the array to divide the result of xFunction by.
            %   idx_function: char[], string, or int(PhysicalEntity)
            %      the functino to apply on the entity to find which number
            %      in the array to divide by.
            %   x_function: char[], string, double(PhysicalEntity), or BulkFunc
            %      this is the aspect of the entity we want to normalize
            %      and display.
            %   axis (Optional): string
            %      "x" (default): gets the function without modifications
            %      "y": applies a mean on the result of the function
            %      "err": find the standard deviation for the result of the
            %      function.
            if isa(idx_function, 'char') || isa(idx_function, 'string')
                idx_function = PlotBuilder.property(idx_function);
            end
            if isa(x_function, 'char') || isa(x_function, 'string')
                x_function = PlotBuilder.property(x_function);
            end
            func = @(obj) (x_function(obj) / arr(idx_function(obj)));
            if nargin == 4
                func = axify(func, axis);
            end
        end
        
        function fig_handles = sequenceWithTotal(plotter)
            % SEQUENCEWITHTOTAL Plot a sequence graph, and add to it the general trendline of ALL frames
            % basicaly it glues together the sequence variant and
            % non-sequence variant. The general transline has a dashed
            % form, and the graphs also change limits to accommedate the
            % general trandline.
            % Parameters:
            %   plotter: PlotBuilder
            %      the configurations to use to draw the graphs.
            fig_handles = plotter.sequence.draw;
            total_handle = plotter.sequence(false).draw;
            for i = 1:length(total_handle.CurrentAxes.Children)
                total_handle.CurrentAxes.Children(i).LineStyle = '--';
                total_handle.CurrentAxes.Children(i).DisplayName = [total_handle.CurrentAxes.Children(i).DisplayName, ' (all frames)'];
            end
            for fig = fig_handles
                copyobj(total_handle.CurrentAxes.Children, fig.CurrentAxes);
                fig.CurrentAxes.XLim(1) = min([fig.CurrentAxes.XLim(1), total_handle.CurrentAxes.XLim(1)]);
                fig.CurrentAxes.XLim(2) = max([fig.CurrentAxes.XLim(2), total_handle.CurrentAxes.XLim(2)]);
                fig.CurrentAxes.YLim(1) = min([fig.CurrentAxes.YLim(1), total_handle.CurrentAxes.YLim(1)]);
                fig.CurrentAxes.YLim(2) = max([fig.CurrentAxes.YLim(2), total_handle.CurrentAxes.YLim(2)]);
            end
            close(total_handle)
        end
        
        function y_func = correlation(func, mean_on_pairs, var_on_all_pairs)
            % CORRELATION calculate the autocorrelation for a particular aspect of a physical entity.end
            % this works for any physical entity: cells, bonds, etc.
            % Parameters:
            %   func: char[], string, double(PhysicalEntity), or BulkFunc
            %      this is the aspect of the entity we want to find a correlation for.
            %   mean_on_pairs (optional): boolean
            %      one base aspect of the autocorrelation function is to use a reference mean, that each entry deviates from
            %      true (default): the statistical mean take into account the number of appearences of an entity in all pairs
            %      false: the statisticla mean should ignore the number of appearences of each entity, but intead give any participant a weight of 1.
            %   var_on_all_pairs (optional): boolean
            %      another important aspect of autocorrelation is to normalize by the variance
            %      true (default): the variance should be calculated globally, that is, for all pairs provided
            %      false: the variance should be calculated per distance, that is, each entry uses all the pairs that have the same distance.
            % Return: a yFunction on Pair, which the pair type being the same one used for func.
            if nargin < 2
                mean_on_pairs = true;
            end
            if nargin < 3
                var_on_all_pairs = true;
            end
            if isa(func, 'char') || isa(func, 'string')
                func = PlotBuilder.property(func);
            end
            map = containers.Map;
            y_func = @(obj, plotter, obj_arr) PlotUtils.getCorrelation(obj, plotter, obj_arr, func, map, mean_on_pairs, var_on_all_pairs);
        end
        
        
    end
    
    methods(Static, Access=private)
        function [result, map] = getOrStore(obj, obj_arr, map, t_prequisite, mean_function)
            % GETORSTORE a small utility function that gets the property from a map or calculates it.
            % Parameters:
            %   obj: PhysicalEntity
            %      the object to get the sibilings of
            %   obj_arr: PhysicalEntity[]
            %      the array of objects to lookup for the shared property
            %   map: Map
            %      the map to search for the pre-existing property
            %   t_prequisite: char[], string, boolean(PhysicalEntity[], PhysicalEntity)
            %      the function to use to find the sibilings of the given
            %      object.
            %   mean_function: double(PhysicalArray[])
            %      a function used to calculate the return value after the
            %      sibilings were retrieved. Sometimes stored in map,
            %      depending on t_prequisite.
            map_key = [obj.experiment.uniqueName, ':', class(obj), ':', length(obj_arr)];
            if isa(t_prequisite, 'char') || isa(t_prequisite, 'string')
                % property algorithm - very fast
                if map.isKey(map_key)
                    value_map = map(map_key);
                else
                    t_entry = [obj_arr.(t_prequisite)];
                    t_values = unique(t_entry);
                    value_map = containers.Map('KeyType','double','ValueType','any');
                    for bin_idx=1:length(t_values)
                        t_value = t_values(bin_idx);
                        value_map(t_value) = obj_arr(t_entry == t_value);
                    end
                    for key = value_map.keys
                        value_map(key{1}) = mean_function(value_map(key{1}));
                    end
                    map(map_key) = value_map;
                end
                result = value_map(obj.(t_prequisite));
            else
                % boolean algorithm - slow
                if map.isKey(map_key)
                    candidates = map(map_key);
                    for candidate = candidates
                        if ismember(obj, candidate{1})
                            result = mean_function(candidate{1});
                            return
                        end
                    end
                    result = obj_arr(t_prequisite(obj_arr, obj));
                    map(map_key) = [candidates(:)', {result}];
                else
                    result = obj_arr(t_prequisite(obj_arr, obj));
                    map(map_key) = {result};
                end
            end
        end
        
        function y_value = getCorrelation(x_pairs, plotter, all_pairs, func, map, mean_on_pairs, var_on_all_pairs)
            % get or calculate mean using exp:length:"mean"
            mean_key = [x_pairs(1).elements(1).experiment.uniqueName, ':', class(x_pairs(1)), ':', length(all_pairs), ':mean'];
            if map.isKey(mean_key)
                corr_mean = map(mean_key);
            else
                if mean_on_pairs
                    to_avg = [all_pairs.elements];
                else
                    to_avg = unique([all_pairs.elements]);
                end
                corr_mean = nanmean(BulkFunc.apply(func, to_avg, plotter, [all_pairs.elements]));
                map(mean_key) = corr_mean;
            end
            
            corr_val = BulkFunc.apply(func, [x_pairs.elements], plotter, [all_pairs.elements]);
            corr_val = reshape(corr_val, numel(x_pairs), 2);
            
            if var_on_all_pairs
                % get or calculate var using exp_length:"var"
                var_key = [x_pairs(1).elements(1).experiment.uniqueName, ':', class(x_pairs(1)), ':', length(all_pairs), ':var'];
                if map.isKey(var_key)
                    corr_var = map(var_key);
                else
                    corr_var = BulkFunc.apply(func, [all_pairs.elements], plotter, [all_pairs.elements]);
                    corr_var = reshape(corr_var, numel(all_pairs), 2);
                    
                    corr_var = nansum((corr_var - corr_mean) .^ 2, 'all') / 2;
                    map(var_key) = corr_var;
                end
            else
                    corr_var = nansum((corr_val - corr_mean) .^ 2, 'all') / 2;
            end
            
            corr_val = corr_val - corr_mean;
            corr_prod = dot(corr_val(:,1), corr_val(:, 2));
            
            y_value = corr_prod / corr_var;
        end
    end
end


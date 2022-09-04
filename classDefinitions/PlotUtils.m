classdef PlotUtils
    %PlotUtils a collection of utility functions regarding plotting
    %   Details? what are those?
    
    methods (Static)
        function func = axify(base, axis)
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
        
        function func = pSqrtA(axis)
            func = @(cell) ([cell.perimeter] ./ sqrt([cell.area]));
            if nargin == 1
                func = PlotUtils.axify(func, axis);
            end
            func = BulkFunc(func);
        end
        
        function func = xNormalize(x_function, t_prequisite)
            if isa(x_function, 'char') || isa(x_function, 'string')
                x_function = PlotBuilder.property(x_function);
            end
            map = containers.Map;
            mean_function = @(obj_arr)(nanmean(x_function(obj_arr)));
            func = @(obj, ~, obj_arr) (x_function(obj) / PlotUtils.getOrStore(obj, obj_arr, map, t_prequisite, mean_function));
        end
        
        function [result, map] = getOrStore(obj, obj_arr, map, t_prequisite, mean_function)
            map_key = [obj.experiment.folder_, '_', class(obj), '_', length(obj_arr)];
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
        
        function func = divide(arr, idx_function, x_function, axis)
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
    end
end


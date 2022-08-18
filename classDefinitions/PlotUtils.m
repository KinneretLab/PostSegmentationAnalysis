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
                        func = @(cell_arr, plotter) (mean(plotter.filter(base(cell_arr))));
                    case "err"
                        func = @(cell_arr, plotter) (std(plotter.filter(base(cell_arr))));
                end
            else
                func = base;
            end
        end
        
        function func = pSqrtA(axis)
            func = @(cell) ([cell.perimeter] / sqrt([cell.area]));
            if nargin == 1
                func = PlotUtils.axify(axis);
            end
        end
        
        function func = xNormalize(x_function, t_prequisite)
            if isa(x_function, 'char') || isa(x_function, 'string')
                x_function = PlotBuilder.property(x_function);
            end
            func = @(obj) (x_function(obj) / x_function(obj.siblings(t_prequisite)));
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
            total_handle.Children.Children.LineStyle = '--';
            for fig = fig_handles
                copyobj(total_handle.Children.Children, fig.Children);
                fig.Children.XLim(1) = min([fig.Children.XLim(1), total_handle.Children.XLim(1)]);
                fig.Children.XLim(2) = max([fig.Children.XLim(2), total_handle.Children.XLim(2)]);
                fig.Children.YLim(1) = min([fig.Children.YLim(1), total_handle.Children.YLim(1)]);
                fig.Children.YLim(2) = max([fig.Children.YLim(2), total_handle.Children.YLim(2)]);
            end
            close(total_handle)
        end
    end
end


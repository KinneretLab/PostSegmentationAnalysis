classdef Frame
    properties
        frame
        frame_name
        time_sec
    end
    
    methods
                
        function obj = Frame(frame_table_row)
            if nargin > 0
                for name = frame_table_row.Properties.VariableNames
                    obj.(name{1}) = frame_table_row{1, name}; %% be careful with variable refactoring
                end
            end
        end
    end
    
end
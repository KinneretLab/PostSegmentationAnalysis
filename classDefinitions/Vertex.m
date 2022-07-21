classdef Vertex
    properties
        frame
        vertex_id
        x_pos
        y_pos
        
    end
    
    methods
        
        %         function obj = Vertex(vertices,ID)
        %
        %             vertex_ind = (vertices{:,'vertex_id'} == ID);
        %             obj.frame = vertices{vertex_ind,'frame'};
        %             obj.vertex_id = ID;
        %             obj.x_pos = vertices{vertex_ind,'x_pos'};
        %             obj.y_pos = vertices{vertex_ind,'y_pos'};
        %
        %         end
        
        function obj = Vertex(vertex_table_row)
            if nargin > 0
                for name = vertex_table_row.Properties.VariableNames
                    obj.(name{1}) = vertex_table_row{1, name}; %% be careful with variable refactoring
                end
            end
        end
    end
    
end
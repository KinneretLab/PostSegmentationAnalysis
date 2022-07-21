classdef DBond
    properties
        frame
        dbond_id
        cell_id
        conj_dbond_id
        bond_id
        vertex_id
        vertex2_id
        left_dbond_id
    end
    
    methods
        
        %         function obj = DBond(directed_bonds,ID)
        %
        %             dbond_ind = (directed_bonds{:,'dbond_id'} == ID);
        %             obj.frame = directed_bonds{dbond_ind,'frame'};
        %             obj.dbond_id = directed_bonds{dbond_ind,'dbond_id'};
        %             obj.cell_id = directed_bonds{dbond_ind,'cell_id'};
        %             obj.conj_dbond_id = directed_bonds{dbond_ind,'conj_dbond_id'};
        %             obj.bond_id = directed_bonds{dbond_ind,'bond_id'};
        %             obj.vertex_id = directed_bonds{dbond_ind,'vertex_id'};
        %             obj.vertex2_id = directed_bonds{dbond_ind,'vertex2_id'};
        %             obj.left_dbond_id = directed_bonds{dbond_ind,'left_dbond_id'};
        %
        %         end
        
        
        function obj = DBond(d_bond_table_row)
            if nargin > 0
                for name = d_bond_table_row.Properties.VariableNames
                    obj.(name{1}) = d_bond_table_row{1, name}; %% be careful with variable refactoring
                end
            end
        end
    end
    
end
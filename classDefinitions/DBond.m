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
        DB
    end
    
    methods
        
        function obj = DBond(db,d_bond_table_row)
            if nargin > 0
                for name = d_bond_table_row.Properties.VariableNames
                    obj.(name{1}) = d_bond_table_row{1, name}; %% be careful with variable refactoring
                end
                obj.DB = db;

            end
        end
    end
    
end
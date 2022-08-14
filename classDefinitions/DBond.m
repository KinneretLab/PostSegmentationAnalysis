classdef DBond < Entity
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
        
        function obj = DBond(varargin)
            obj@Entity(varargin)
        end

        function id = uniqueID(~)
            id = "dbond_id";
        end
    end
    
end
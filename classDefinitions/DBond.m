classdef DBond < PhysicalEntity
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
            obj@PhysicalEntity(varargin)
        end

        function id = uniqueID(~)
            id = "dbond_id";
        end
        
        function dbonds = conjugate(obj)
            index = containers.Map;
            clazz = class(DBond);
            dbonds(size(obj, 1), size(obj, 2)) = DBond;
            for lookup_idx = 1:numel(obj)
                entity = obj(lookup_idx);
                if isnan(entity) || isnan(entity.conj_dbond_id)
                    continue;
                end
                map_key = [entity.experiment.folder_, '_', clazz];
                full_map_key = [map_key, '_', entity.frame];
                if ~index.isKey(full_map_key)
                    full_dbonds = entity.experiment.lookup(clazz);
                    frame_num = [full_dbonds.frame];
                    for frame_id=unique(frame_num)
                        index([map_key, '_', frame_id]) = full_dbonds(frame_num == frame_id);
                    end
                end
                all_dbonds = index(full_map_key);
                dbonds(lookup_idx) = all_dbonds([all_dbonds.dbond_id] == entity.conj_dbond_id);
            end
        end
        
        function cells = cells(obj)
            index = containers.Map;
            clazz = class(Cell);
            cells(size(obj, 1), size(obj, 2)) = Cell;
            for lookup_idx = 1:numel(obj)
                entity = obj(lookup_idx);
                if isnan(entity) || isnan(entity.cell_id)
                    continue;
                end
                map_key = [entity.experiment.folder_, '_', clazz];
                full_map_key = [map_key, '_', entity.frame];
                if ~index.isKey(full_map_key)
                    full_cells = entity.experiment.lookup(clazz);
                    frame_num = [full_cells.frame];
                    for frame_id=unique(frame_num)
                        index([map_key, '_', frame_id]) = full_cells(frame_num == frame_id);
                    end
                end
                all_cells = index(full_map_key);
                cells(lookup_idx) = all_cells([all_cells.cell_id] == entity.cell_id);
            end
        end
        
    end
end
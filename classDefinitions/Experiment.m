classdef Experiment < handle
    properties
        folder_
        data_
        files_
    end
    
    methods
        function obj = Experiment(folder)
            obj.folder_ = folder;
            obj.data_ = containers.Map();
            obj.files_ = containers.Map(cellfun(@class,{Cell, Bond, Vertex, DBond, Frame, BondPixelList}, 'UniformOutput', false), ...
                cellfun(@(file) ([folder, '\', file, '.csv']), {'cells', 'bonds', 'vertices', 'directed_bonds', 'frames', 'bond_pixels'}, 'UniformOutput', false));
        end
        
        function tf = eq(lhs, rhs)
            tf = convertCharsToStrings({lhs.folder_}) == convertCharsToStrings({rhs.folder_});
        end
        
        function [phys_arr, obj] = lookup(obj, clazz, flags)
            % return a flat (1,size) array.
            % iterate over experiments
            result_arr = cell(1, length(obj));
            for row = 1:length(obj)
                experiment = obj(row);
                if ~experiment.data_.isKey(clazz)
                    % index the class
                    fprintf("Indexing %ss for Experiment %s\n", clazz, experiment.folder_);
                    lookup_table = readtable(experiment.files_(clazz),'Delimiter',',');
                    result = feval(clazz, experiment, lookup_table);
                    experiment.data_(clazz) = result;
                else
                    result = experiment.data_(clazz);
                end
                % filter result and put it into result_arr
                if nargin == 3
                    result_arr{row} = result(flags);
                else
                    result_arr{row} = result;
                end
            end
            phys_arr = [result_arr{:}];
        end
        
        function [cell_arr, obj] = cells(obj, flags)
            if nargin > 1
                cell_arr = obj.lookup(class(Cell), flags);
            else
                cell_arr = obj.lookup(class(Cell));
            end
        end
        

        function [dbond_arr, obj] = dBonds(obj, flags)
            if nargin > 1
                dbond_arr = obj.lookup(class(DBond), flags);
            else
                dbond_arr = obj.lookup(class(DBond));
            end
        end
        
        function [bond_arr, obj] = bonds(obj, flags)
            if nargin > 1
                bond_arr = obj.lookup(class(Bond), flags);
            else
                bond_arr = obj.lookup(class(Bond));
            end
        end
        
        function [vertex_arr, obj] = vertices(obj, flags)
            if nargin > 1
                vertex_arr = obj.lookup(class(Vertex), flags);
            else
                vertex_arr = obj.lookup(class(Vertex));
            end
        end

        function [frame_arr, obj] = frames(obj, flags)
            if nargin > 1
                frame_arr = obj.lookup(class(Frame), flags);
            else
                frame_arr = obj.lookup(class(Frame));
            end
        end

        
        function [bond_pixels_arr, obj] = bond_pixel_lists(obj, flags) 
            if nargin > 1
                bond_pixels_arr = obj.lookup(class(BondPixelList), flags);
            else
                bond_pixels_arr = obj.lookup(class(BondPixelList));
            end
        end

    end
    
end
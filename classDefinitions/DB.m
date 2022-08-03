classdef DB
    properties
        cell_file_
        vertex_file_
        bond_file_
        d_bond_file_
        bond_pixel_file_
        frame_file_
        defect_file_
        folder_
    end
    
    methods
        function obj = DB(folder)
            obj.cell_file_ = [folder, '\cells.csv'];
            obj.vertex_file_ = [folder, '\vertices.csv'];
            obj.bond_file_ = [folder, '\bonds.csv'];
            obj.d_bond_file_ = [folder, '\directed_bonds.csv'];
            obj.bond_pixel_file_ = [folder, '\bond_pixels.csv'];
            obj.frame_file_ = [folder, '\frames.csv'];
            obj.defect_file_ = [folder, '\defects.csv'];
            obj.folder_ = folder;
        end
        
        function cell_arr = cells(obj)
            cell_table = readtable(obj.cell_file_);
            cell_arr = Cell();
            for row = 1:height(cell_table)
                cell_arr(row) = Cell(obj, cell_table(row,:));
            end
        end
        
%         function dbond_arr = dbonds(obj)
%             dbond_table = readtable(obj.d_bond_file_);
%             dbond_arr = DBond();
%             for row = 1:height(dbond_table)
%                 dbond_arr(row) = DBond(dbond_table(row,:));
%             end
        %         end

        function dbond_arr = dBonds(obj,flags)
            dbond_arr = DBond();
            for row=1:size(obj,2)
                dbond_table = readtable(obj(row).d_bond_file_);
                if nargin < 2
                    flags = logical(ones(size(obj,2),height(dbond_table)));
                end
                columns = find(flags(row,:));
                for column = 1:length(columns)
                    dbond_arr(row,column) = DBond([dbond_table(columns(column),:)]);
                end
            end
        end
        

        function bond_arr = bonds(obj)
            bond_table = readtable(obj.bond_file_);
            bond_arr = Bond();
            for row = 1:height(bond_table)
                bond_arr(row) = Bond(bond_table(row,:));
            end
        end
        
        function vertex_arr = vertices(obj)
            vertex_table = readtable(obj.vertex_file_);
            vertex_arr = Vertex();
            for row = 1:height(vertex_table)
                vertex_arr(row) = Vertex(vertex_table(row,:));
            end
        end
            
        function frame_arr = frames(obj,flags)
            frame_arr = Frame();
            count = 0;
            for row=1:size(obj,2)
                frame_table = readtable(obj(row).frame_file_,'Delimiter',',');
                if nargin < 2
                    flags = logical(ones(size(obj,2),height(frame_table)));
                end
                columns = find(flags(row,:));
                for column = 1:length(columns)
                    count = count+1;
                    frame_arr(count) = Frame(obj(row),frame_table(columns(column),:));
                end
            end
        end

               
        
        
    end
    
end
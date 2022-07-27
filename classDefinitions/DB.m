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
        
        function cell_arr = cells(obj,flags)
            cell_arr = Cell();
            count = 0;
            for row=1:size(obj,2)
                cell_table = readtable(obj(row).cell_file_);
                if nargin < 2
                    flags = logical(ones(size(obj,2),height(cell_table)));
                end
                columns = find(flags(row,:));
                for column = 1:length(columns)
                    count = count+1;
                    cell_arr(count) = Cell(obj(row),cell_table(columns(column),:));
                end
            end
        end
        
        
        function dbond_arr = dBonds(obj,flags)
            dbond_arr = DBond();
            count = 0;
            for row=1:size(obj,2)
                dbond_table = readtable(obj(row).d_bond_file_);
                if nargin < 2
                    flags = logical(ones(size(obj,2),height(dbond_table)));
                end
                columns = find(flags(row,:));
                for column = 1:length(columns)
                    count = count+1;
                    dbond_arr(count) = DBond(obj(row),dbond_table(columns(column),:));
                end
            end
        end
        
        function bond_arr = bonds(obj,flags)
            bond_arr = Bond();
            count = 0;
            for row=1:size(obj,2)
                bond_table = readtable(obj(row).bond_file_);
                if nargin < 2
                    flags = logical(ones(size(obj,2),height(bond_table)));
                end
                columns = find(flags(row,:));
                for column = 1:length(columns)
                    count = count+1;
                    bond_arr(count) = Bond(obj(row),bond_table(columns(column),:));
                end
            end
        end
        
        function vertex_arr = vertices(obj)
            vertex_arr = Vertex();
            count = 0;
            for row=1:size(obj,2)
                vertex_table = readtable(obj(row).vertex_file_);
                if nargin < 2
                    flags = logical(ones(size(obj,2),height(vertex_table)));
                end
                columns = find(flags(row,:));
                for column = 1:length(columns)
                    count = count+1;
                    vertex_arr(count) = Vertex(obj(row),vertex_table(columns(column),:));
                end
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
        
        
        function bond_pixels_arr = bond_pixel_lists(obj) % Here the function sorts the bond pixels by the bond they belong to and collects the row numbers to pass on to the constructor of the bond outline.
            bond_pixels_arr = BondPixelList();
            count = 0;
            for row=1:size(obj,2)
                bond_pixel_table = readtable(obj(row).bond_pixel_file_);
                bondIDList = bond_pixel_table{:,'pixel_bondID'};
                [~,ia,ic] = unique(bondIDList);
                for i=1:length(ia)
                    count = count+1;
                    rowNums = (ic == i);
                    table_rows = bond_pixel_table(rowNums,:);
                    bond_pixels_arr(count) = BondPixelList(obj(row),table_rows);
                end
            end
        end
        
    
    end
    
end
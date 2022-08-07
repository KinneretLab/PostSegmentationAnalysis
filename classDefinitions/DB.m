classdef DB < handle
    properties
        cell_file_
        vertex_file_
        bond_file_
        d_bond_file_
        bond_pixel_file_
        frame_file_
        defect_file_
        folder_
        cells_
        bonds_
        vertices_
        dBonds_
        frames_
        bond_pixel_lists_

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
            obj.cells_ = Cell();
            obj.bonds_ = Bond();
            obj.vertices_ = Vertex();
            obj.dBonds_ = DBond();
            obj.frames_ = Frame();
            obj.bond_pixel_lists_ = BondPixelList();
        end
        
        function [cell_arr,obj] = cells(obj,flags)
            cell_arr = Cell();
            count = 0;
            for row=1:size(obj,2)
                if nargin < 2 && ~isempty(obj(row).cells_(1).cell_id) % If there are no flags specified, and the full array of the database has already been created, return it.
                    cell_arr((count+1):(count+length(obj(row).cells_))) = obj(row).cells_;
                    count = size(cell_arr,2);
                else
                    disp(sprintf(['Indexing cells for DB ',num2str(row),'/',num2str(size(obj,2))]));
                    cell_table = readtable(obj(row).cell_file_);
                    if nargin < 2
                        flags = logical(ones(size(obj,2),height(cell_table)));
                    end
                    columns = find(flags(row,:));
                    row_count = 0;
                    for column = 1:length(columns)
                        row_count = row_count+1;
                        count = count+1;
                        cell_arr(count) = Cell(obj(row),cell_table(columns(column),:));
                        if mod(column,200)==0
                           disp(sprintf(['Indexing cell ',num2str(column),'/',num2str(length(columns)),' of DB ',num2str(row),'/',num2str(size(obj,2))]));
                        end
                    end
                    if nargin < 2 % If no flags were specified in creating this array, save it as a property of DB.
                        obj(row).cells_ = cell_arr((1+count-row_count):count);
                    end
                end
            end
        end
        

        function [dbond_arr,obj] = dBonds(obj,flags)
            dbond_arr = DBond();
            count = 0;
            for row=1:size(obj,2)
                if nargin < 2 && ~isempty(obj(row).dBonds_(1).dbond_id) % If there are no flags specified, and the full array of the database has already been created, return it.
                    dbond_arr((count+1):(count+length(obj(row).dBonds_))) = obj(row).dBonds_;
                    count = size(dbond_arr,2);
                else
                    disp(sprintf(['Indexing directed bonds for DB ',num2str(row),'/',num2str(size(obj,2))]));
                    dbond_table = readtable(obj(row).d_bond_file_);
                    if nargin < 2
                        flags = logical(ones(size(obj,2),height(dbond_table)));
                    end
                    columns = find(flags(row,:));
                    row_count = 0;
                    for column = 1:length(columns)
                        row_count = row_count+1;
                        count = count+1;
                        dbond_arr(count) = DBond(obj(row),dbond_table(columns(column),:));
                        if mod(column,1000)==0
                            disp(sprintf(['Indexing directed bond ',num2str(column),'/',num2str(length(columns)),' of DB ',num2str(row),'/',num2str(size(obj,2))]));
                        end
                    end
                    if nargin < 2 % If no flags were specified in creating this array, save it as a property of DB.
                        obj(row).dBonds_ = dbond_arr((1+count-row_count):count);
                    end
                end
            end
        end
        
        function [bond_arr,obj] = bonds(obj,flags)
            bond_arr = Bond();
            count = 0;
            for row=1:size(obj,2)
                if nargin < 2 && ~isempty(obj(row).bonds_(1).bond_id) % If there are no flags specified, and the full array of the database has already been created, return it.
                    bond_arr((count+1):(count+length(obj(row).bonds_))) = obj(row).bonds_;
                    count = size(bond_arr,2);
                else
                    disp(sprintf(['Indexing bonds for DB ',num2str(row),'/',num2str(size(obj,2))]));
                    bond_table = readtable(obj(row).bond_file_);
                    if nargin < 2
                        flags = logical(ones(size(obj,2),height(bond_table)));
                    end
                    columns = find(flags(row,:));
                    row_count = 0;
                    for column = 1:length(columns)
                        row_count = row_count+1;
                        count = count+1;
                        bond_arr(count) = Bond(obj(row),bond_table(columns(column),:));
                        if mod(column,50)==0
                            disp(sprintf(['Indexing bond ',num2str(column),'/',num2str(length(columns)),' of DB ',num2str(row),'/',num2str(size(obj,2))]));
                        end
                    end
                    if nargin < 2 % If no flags were specified in creating this array, save it as a property of DB.
                        obj(row).bonds_ = bond_arr((1+count-row_count):count);
                    end
                end
            end
        end
        
        function [vertex_arr,obj] = vertices(obj)
            vertex_arr = Vertex();
            count = 0;
            for row=1:size(obj,2)
                if nargin < 2 && ~isempty(obj(row).vertices_(1).vertex_id) % If there are no flags specified, and the full array of the database has already been created, return it.
                    vertex_arr((count+1):(count+length(obj(row).vertices_))) = obj(row).vertices_;
                    count = size(vertex_arr,2);
                else
                    disp(sprintf(['Indexing vertices for DB ',num2str(row),'/',num2str(size(obj,2))]));
                    vertex_table = readtable(obj(row).vertex_file_);
                    if nargin < 2
                        flags = logical(ones(size(obj,2),height(vertex_table)));
                    end
                    columns = find(flags(row,:));
                    row_count = 0;
                    for column = 1:length(columns)
                        row_count = row_count+1;
                        count = count+1;
                        vertex_arr(count) = Vertex(obj(row),vertex_table(columns(column),:));
                        if mod(column,500)==0
                            disp(sprintf(['Indexing vertex ',num2str(column),'/',num2str(length(columns)),' of DB ',num2str(row),'/',num2str(size(obj,2))]));
                        end
                    end
                    if nargin < 2 % If no flags were specified in creating this array, save it as a property of DB.
                        obj(row).vertices_ = vertex_arr((1+count-row_count):count);
                    end
                end
            end
        end

        function [frame_arr,obj] = frames(obj,flags)
            frame_arr = Frame();
            count = 0;
            for row=1:size(obj,2)
                if nargin < 2 && ~isempty(obj(row).frames_(1).frame) % If there are no flags specified, and the full  array of the database has already been created, return it.
                    frame_arr((count+1):(count+length(obj(row).frames_))) = obj(row).frames_;
                    count = size(frame_arr,2);
                else
                    disp(sprintf(['Indexing frames for DB ',num2str(row),'/',num2str(size(obj,2))]));
                    frame_table = readtable(obj(row).frame_file_,'Delimiter',',');
                    if nargin < 2
                        flags = logical(ones(size(obj,2),height(frame_table)));
                    end
                    columns = find(flags(row,:));
                    row_count = 0;
                    for column = 1:length(columns)
                        row_count = row_count+1;
                        count = count+1;
                        frame_arr(count) = Frame(obj(row),frame_table(columns(column),:));
                        if mod(column,50)==0
                            disp(sprintf(['Indexing frame ',num2str(column),'/',num2str(length(columns)),' of DB ',num2str(row),'/',num2str(size(obj,2))]));
                        end
                    end
                    if nargin < 2 % If no flags were specified in creating this array, save it as a property of DB.
                        obj(row).frames_ = frame_arr((1+count-row_count):count);
                    end
                end
            end
        end

        
        function [bond_pixels_arr,obj] = bond_pixel_lists(obj) % Here the function sorts the bond pixels by the bond they belong to and collects the row numbers to pass on to the constructor of the bond outline.
            bond_pixels_arr = BondPixelList();
            count = 0;
            for row=1:size(obj,2)
                if ~isempty(obj(row).bond_pixel_lists_(1).pixel_bondID) % If there are no flags specified, and the full array of the database has already been created, return it.
                    bond_pixels_arr((count+1):(count+length(obj(row).bond_pixel_lists_))) = obj(row).bond_pixel_lists_;
                    count = size(bond_pixels_arr,2);
                else
                    disp(sprintf(['Indexing pixel list for DB ',num2str(row),'/',num2str(size(obj,2))]));
                    bond_pixel_table = readtable(obj(row).bond_pixel_file_);
                    bondIDList = bond_pixel_table{:,'pixel_bondID'};
                    [~,ia,ic] = unique(bondIDList);
                    row_count = 0;
                    for i=1:length(ia)
                        row_count = row_count+1;
                        count = count+1;
                        rowNums = (ic == i);
                        table_rows = bond_pixel_table(rowNums,:);
                        bond_pixels_arr(count) = BondPixelList(obj(row),table_rows);
                        if mod(column,2000)==0
                            disp(sprintf(['Indexing pixel list ',num2str(i),'/',num2str(length(ia)),' of DB ',num2str(row),'/',num2str(size(obj,2))]));
                        end
                    end
                    obj(row).bond_pixel_lists_ = bond_pixels_arr((1+count-row_count):count);
                end
            end
        end

    end
    
end
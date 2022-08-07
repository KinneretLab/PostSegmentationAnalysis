classdef Vertex
    properties
        frame
        vertex_id
        x_pos
        y_pos
        DB
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
        
        function obj = Vertex(db,vertex_table_row)
            if nargin > 0
                for name = vertex_table_row.Properties.VariableNames
                    obj.(name{1}) = vertex_table_row{1, name}; %% be careful with variable refactoring
                end
                obj.DB = db;

            end
        end
      
        function dBonds = dBonds(obj)
            thisID = [obj.vertex_id];
            dbArray = [obj.DB];
            dbFolderArray = {dbArray.folder_};
            [~,ia,ic] = unique(dbFolderArray);
            dBonds = DBond();
            for i=1:length(ia)
                dBondArray{i} = dbArray(ia(i)).dBonds;
            end
            maxLength = 0;
            flags = [];
            for i=1:length(thisID)
                if mod(i,100) ==0
                    sprintf(['Finding directed bonds for vertex # ',num2str(i)])
                end
                vertexIDArray = [dBondArray{ic(i)}.vertex_id];
                flags = (vertexIDArray == thisID(i));
                thisLength = sum(flags);
                if thisLength > maxLength
                    dBonds(:,(maxLength+1):thisLength) = DBond();
                    maxLength = thisLength;
                end
                dBonds(i,1:thisLength) = dBondArray{ic(i)}(flags);
            end
        end
        
        
        function frames = frames(obj)
            frameList = [obj.frame];
            dbArray = [obj.DB];
            dbFolderArray = {dbArray.folder_};
            [~,ia,ic] = unique(dbFolderArray);
            for i=1:length(ia)
                frameArray{i,:} = dbArray(ia(i)).frames;
            end
            flags = [];
            frames = Frame();
            for i=1:length(frameList)
                if mod(i,100) ==0
                    sprintf(['Returning frame for vertex # ',num2str(i)])
                end
                frameNumArray = [frameArray{ic(i),:}.frame];
                flags = (frameNumArray == frameList(i));
                frames(i) = frameArray{ic(i)}(flags);
            end
        end
        
        
        function bonds = bonds(obj)
            theseDBonds = dBonds(obj);
            dbArray = [obj.DB];
            dbFolderArray = {dbArray.folder_};
            [~,ia,ic] = unique(dbFolderArray);
            for i=1:length(ia)
                bondArray{i} = dbArray(ia(i)).bonds;
            end
            flags = [];
            for i=1:size(obj,2)
                if mod(i,100) ==0
                    sprintf(['Finding bonds for vertex # ',num2str(i)])
                end
                for j=1:length(theseDBonds(i,:))
                    bondIDArray = [bondArray{ic(i)}.bond_id];
                    thisID = theseDBonds(i,j).bond_id;
                    if ~isempty(thisID)
                        flag = (bondIDArray == thisID);
                        bonds(i,j) = bondArray{ic(i)}(flag);
                    else
                        bonds(i,j) = Bond();
                    end
                end
            end

        end
        
        function cells = cells(obj)
            theseDBonds = dBonds(obj);
            dbArray = [obj.DB];
            dbFolderArray = {dbArray.folder_};
            [~,ia,ic] = unique(dbFolderArray);
            for i=1:length(ia)
                cellArray{i} = dbArray(ia(i)).cells;
            end
            flags = [];
            for i=1:size(obj,2)
                if mod(i,100) ==0
                    sprintf(['Finding cells for vertex # ',num2str(i)])
                end
                for j=1:length(theseDBonds(i,:))
                    cellIDArray = [cellArray{ic(i)}.cell_id];
                    thisID = theseDBonds(i,j).cell_id;
                    if ~isempty(thisID)
                        flag = (cellIDArray == thisID);
                        cells(i,j) = cellArray{ic(i)}(flag);
                    else
                        cells(i,j) = Cell();
                    end
                end
            end
            
        end
        
    end
    
end
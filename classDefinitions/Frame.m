classdef Frame < Entity
    properties
        frame
        frame_name
        time_sec
    end
    
    methods

        function obj = Frame(varargin)
            obj@Entity(varargin)
        end

        function id = uniqueID(~)
            id = "frame";
        end

        function cells = cells(obj)
            thisFrame = [obj.frame];
            dbArray = [obj.experiment];
            dbFolderArray = {dbArray.folder_};
            [~,ia,ic] = unique(dbFolderArray);
            cells = Cell();
            for i=1:length(ia)
                cellArray{i} = dbArray(ia(i)).cells;
            end
            maxLength = 0;
            flags = [];
            for i=1:length(thisFrame)
                if mod(i,10) ==0
                    disp(sprintf(['Finding cells for frame # ',num2str(i)]));
                end
                frameArray = [cellArray{ic(i)}.frame];
                flags = (frameArray == thisFrame(i));
                thisLength = sum(flags);
                if thisLength > maxLength
                    cells(:,(maxLength+1):thisLength) = Cell();
                    maxLength = thisLength;
                end
                cells(i,1:thisLength) = cellArray{ic(i)}(flags);
            end
        end


        function vertices = vertices(obj)
            thisFrame = [obj.frame];
            dbArray = [obj.experiment];
            dbFolderArray = {dbArray.folder_};
            [~,ia,ic] = unique(dbFolderArray);
            vertices = Vertex();
            for i=1:length(ia)
                vertexArray{i} = dbArray(ia(i)).vertices;
            end
            maxLength = 0;
            flags = [];
            for i=1:length(thisFrame)
                if mod(i,10) ==0
                    disp(sprintf(['Finding vertices for frame # ',num2str(i)]));
                end
                frameArray = [vertexArray{ic(i)}.frame];
                flags = (frameArray == thisFrame(i));
                thisLength = sum(flags);
                if thisLength > maxLength
                    vertices(:,(maxLength+1):thisLength) = Vertex();
                    maxLength = thisLength;
                end
                vertices(i,1:thisLength) = vertexArray{ic(i)}(flags);
            end
        end


        function bonds = bonds(obj)
            thisFrame = [obj.frame];
            dbArray = [obj.experiment];
            dbFolderArray = {dbArray.folder_};
            [~,ia,ic] = unique(dbFolderArray);
            bonds = Bond();
            for i=1:length(ia)
                bondArray{i} = dbArray(ia(i)).bonds;
            end
            maxLength = 0;
            flags = [];
            for i=1:length(thisFrame)
                if mod(i,10) ==0
                    disp(sprintf(['Finding bonds for frame # ',num2str(i)]));
                    frameArray = [bondArray{ic(i)}.frame];
                    flags = (frameArray == thisFrame(i));
                    thisLength = sum(flags);
                    if thisLength > maxLength
                        bonds(:,(maxLength+1):thisLength) = Bond();
                        maxLength = thisLength;
                    end
                    bonds(i,1:thisLength) = bondArray{ic(i)}(flags);
                end
            end
        end

    end
    
end
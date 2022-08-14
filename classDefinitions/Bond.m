classdef Bond < Entity
    properties
        frame
        bond_id
        bond_length
        pixel_list
    end
    
    methods
        
        
        function obj = Bond(varargin)
            obj@Entity(varargin)
            obj.pixel_list = [];
        end

        function id = uniqueID(obj)
            id = "bond_id";
        end
        
          function dBonds = dBonds(obj)
            thisID = [obj.bond_id];
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
                    disp(sprintf(['Finding directed bonds for bond # ',num2str(i)]));
                end
                bondIDArray = [dBondArray{ic(i)}.bond_id];
                flags = (bondIDArray == thisID(i));
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
                      disp(sprintf(['Returning frame for cell # ',num2str(i)]));
                  end
                  frameNumArray = [frameArray{ic(i),:}.frame];
                  flags = (frameNumArray == frameList(i));
                  frames(i) = frameArray{ic(i)}(flags);
              end
          end
          
          
          function vertices = vertices(obj)
              theseDBonds = dBonds(obj);
              dbArray = [obj.DB];
              dbFolderArray = {dbArray.folder_};
              [~,ia,ic] = unique(dbFolderArray);
              for i=1:length(ia)
                  vertexArray{i} = dbArray(ia(i)).vertices;
              end
              flags = [];
              for i=1:size(obj,2)
                  if mod(i,100) ==0
                      disp(sprintf(['Finding vertices for bond # ',num2str(i)]));
                  end
                  for j=1:length(theseDBonds(i,:))
                      vertexIDArray = [vertexArray{ic(i)}.vertex_id];
                      thisID = theseDBonds(i,j).vertex_id;
                      if ~isempty(thisID)
                          flag = (vertexIDArray == thisID);
                          vertices(i,j) = vertexArray{ic(i)}(flag);
                      else
                          vertices(i,j) = Vertex();
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
                      disp(sprintf(['Finding cells for bond # ',num2str(i)]));
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
          
          function coords(obj)
              dbArray = [obj.DB];
              dbFolderArray = {dbArray.folder_};
              [~,ia,ic] = unique(dbFolderArray);
              flags = [];
              for i=1:length(ia)
                  pixelListArray{i} = dbArray(ia(i)).bond_pixel_lists;
              end
              for i=1:size(obj,2)
                  if mod(i,100) ==0
                      disp(sprintf(['Finding coordinates for bond # ',num2str(i)]));
                  end
                  thisID = obj(i).bond_id;
                  bondIDArray = [pixelListArray{ic(i)}.pixel_bondID];
                  flags = (bondIDArray == thisID);
                  obj(i).pixel_list = pixelListArray{ic(i)}(flags);
              end
          end

        
    end
    
end
function [fullCellData,fullVertexData] = extractCellData(segDir, maskDir)
% This function loads final segmentation mask, vertex image, and bond image
% outputs of tissue analyzer, and saves them to two organized structures
% called "fullCellData" and "fullVertexData".

fullCellData = struct();
fullVertexData = struct();

files = dir(segDir);
folders = files([files.isdir]);
sortedFolderNames = natsortfiles({folders.name});
index = cellfun(@(x) x(1)~= '.', sortedFolderNames , 'UniformOutput',1);
sortedFolderNames = sortedFolderNames(index);
lastInd = 0;
lastVInd = 0;
underscores = find(sortedFolderNames{1}=='_');
digits = length(sortedFolderNames{1}((underscores(end)+1):end));
formatSpec = ['%0',num2str(digits),'.f'];

for k = 1:length(sortedFolderNames)
        k
        thisFolder = sortedFolderNames{k};
        cd([segDir,'\',thisFolder]);
        
        thisIm=importdata('handCorrection.tif');
        
        cd(maskDir);
        try 
            thisMaskBW = imbinarize(imread([thisFolder,'.tiff']));
        catch
            thisMaskBW = imbinarize(imread([thisFolder,'.tif']));
        end
        
        thisImGray = rgb2gray(thisIm);
        thisImBW = imbinarize(thisImGray);
        thisImBW = thisImBW.*thisMaskBW;
        thisImWB = imcomplement(thisImBW);
        
        CC = bwconncomp(thisImWB,4);
        B = bwboundaries(thisImWB,4);
        L = labelmatrix(CC);
        stats = regionprops(CC);
        RGB = label2rgb(L,'jet','k','shuffle');
        background = find([stats.Area]==max([stats.Area]));
        for i = 1:length(stats)
            if i~=background
                shift = (i>background);
            % Fill data for this cell into struct
            fullCellData(i+lastInd-shift).frame = num2str(k-1);
            fullCellData(i+lastInd-shift).centre_x = stats(i).Centroid(1);
            fullCellData(i+lastInd-shift).centre_y = stats(i).Centroid(2);
            cellLabel =  L( round(fullCellData(i+lastInd-shift).centre_y),round(fullCellData(i+lastInd-shift).centre_x));
            fullCellData(i+lastInd-shift).outline = B{cellLabel};
            fullCellData(i+lastInd-shift).uniqueID = [num2str(k-1,formatSpec),num2str(cellLabel)];
            fullCellData(i+lastInd-shift).vertices = [];
            end
        end
        lastInd = length(fullCellData);
        
        cd([segDir,'\',thisFolder]);
        vertexIm=importdata('vertices.tif');
        vertexImGray = rgb2gray(vertexIm);
        vertexImBW = imbinarize(vertexImGray);
        

        vertexImBW = vertexImBW.*thisMaskBW;
        [v_y,v_x]=find(vertexImBW);
        
        for j=1:length(v_x)            
            Lvals = unique(L((v_y(j)-1):(v_y(j)+1),(v_x(j)-1):(v_x(j)+1)));
            Lvals = Lvals(Lvals>0);
            fullVertexData(j+lastVInd).isEdge = length(find(Lvals==background));
            Lvals = Lvals(Lvals~=background);
            fullVertexData(j+lastVInd).frame = k-1;
            fullVertexData(j+lastVInd).x_pos = v_x(j);
            fullVertexData(j+lastVInd).y_pos = v_y(j);

            cIndex =[];
            for l = 1:length(Lvals)
                cellID = [num2str(k-1,formatSpec),num2str(Lvals(l))];
                cIndex(l) = find(strcmp({fullCellData.uniqueID}, cellID)==1);
            end
            fullVertexData(j+lastVInd).cells = cIndex;
            for m=1:length(cIndex)
                fullCellData(cIndex(m)).vertices = [fullCellData(cIndex(m)).vertices,j+lastVInd];
                if fullVertexData(j+lastVInd).isEdge == 1
                   fullCellData(cIndex(m)).isEdge = 1;
                end
            end
        end
        
        lastVInd = length(fullVertexData);

end

end

% x-value from DB needs to be second index in matlab, y-value first index.
% When using imshow will show up as correct X,Y as in DB.





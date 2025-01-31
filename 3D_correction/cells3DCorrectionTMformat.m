function [] = cells3DCorrectionTMformat(mainDir,rawDatasetsDir,outlineDir,segDir, calibrationXY, calibrationZ,umCurvWindow,cellHMnum,frameList)
% This function takes the data on cell outlines from "fullCellData",
% applies a geometric correction to the outlines according to the height
% maps to find area, orientation, and aspect ratio, and returns them to the main function to be saved back into
% fullCellData.

%% Define directories:
HMDir = [mainDir,'\Layer_Separation\Output\Smooth_Height_Maps_',num2str(cellHMnum)]; % NOTICE IF NEEDS TO BE "Height_Maps_1" or "Height_Maps_0"
%% Load Data and Height Map lists

files = dir(segDir);
folders = files([files.isdir]);
sortedFolderNames = natsortfiles({folders.name});
index = cellfun(@(x) x(1)~= '.', sortedFolderNames , 'UniformOutput',1);
sortedFolderNames = sortedFolderNames(index);

% Calibration
Z_to_XY = calibrationZ/calibrationXY; % Z to XY calibration
XY_to_Micron = calibrationXY; % XY calibration in um/pixel.
curvWindow = round(umCurvWindow*XY_to_Micron); % Window for averaging curvature around single cell in pixels (equivalent to 32 pixels in 512x512 image at 1.28 um/pixel)

%% Run over all frames, and all cells in each frame. For each cell, take cell outlines from fullCellData, apply geometric correction, and calculate area, perimeter, aspect ration, and orientation.

if isempty(frameList)
    frames = 1:length(sortedFolderNames);
else
    frames = frameList;
end
% Run over all prescribed frames:

for n = frames
    display(['Computing geometric correction for frame ',num2str(n)])
    
    % Load all cell,vertex,bond and directed bond data.
    thisFileName = sortedFolderNames{n};
    cd(rawDatasetsDir);
    if exist([thisFileName,'_CellData.mat'])
        try
        thisCellData = importdata([thisFileName,'_CellData.mat']);
        thisVertexData = importdata([thisFileName,'_VertexData.mat']);
        thisBondData = importdata([thisFileName,'_BondData.mat']);
        thisDBondData = importdata([thisFileName,'_DBondData.mat']);
        
        % Load height maps
        cd(HMDir);
        thisHMfile = dir(['*',thisFileName,'.*']);
        thisHM = importdata (thisHMfile.name);
        thisHM = thisHM * Z_to_XY; % Scaling
        
        imSize = size(thisHM);
        
        [y_planeO,x_planeO] = meshgrid(1:imSize(1),1:imSize(2)); % Making a grid
        x_plane = x_planeO(:);
        y_plane = y_planeO(:);
        
        [Nx,Ny,Nz] = surfnorm(reshape(y_plane,imSize),reshape(x_plane,imSize),thisHM);
        
        % Initialize struct for outlines which will become outline table
        allOutlines = struct();
        
        % Run over cells in the frame:
        for i = 1:length(thisCellData)
            thisCell = i;
            if isempty(thisCellData(thisCell).bonds)
                continue
            end
            % Save bonds into cell array, and create outline out of bond pixels
            % CORRECT OUTLINE DEFINITION WITH THE NEW INCLUSION OF ZERO-LENGTH
            % BONDS AND CORRECT LENGTH DEFINITION TO INCLUDE VERTICES. ALSOframes
            % MAKE SURE X,Y CONFUSION IS CORRECTED.
            [outline,bonds,verts] = findCellOutline(thisCellData,thisVertexData,thisBondData,thisDBondData,thisCell);
            
            xp = outline(:,1);
            yp = outline(:,2);
            
            % Find z-values of edges
            zp = zeros(length(xp),1);
            for k = 1:length(xp)
                zp(k) = thisHM(yp(k),xp(k));
            end
            
            % Set window for calculating normal to plane
            x_cent = round(mean(xp));
            y_cent = round(mean(yp));
            z_cent = thisHM(y_cent,x_cent);
            normXrange = (x_cent-round(curvWindow/2)):(x_cent+round(curvWindow/2));
            % Make sure all points are within the frame boundaries
            minXpoint = max(find(normXrange>0,1),1);
            maxXpoint = find(normXrange>size(thisHM,2),1); if isempty(maxXpoint), maxXpoint = length(normXrange);end
            normYrange = (y_cent-round(curvWindow/2)):(y_cent+round(curvWindow/2));
            minYpoint = max(find(normYrange>0,1),1);
            maxYpoint = find(normYrange>size(thisHM,1),1);if isempty(maxYpoint), maxYpoint = length(normYrange);end
            thisMin = max(minXpoint,minYpoint);
            thisMax = min(maxXpoint-1,maxYpoint-1);
            
            [normYrange,normXrange] = meshgrid(normYrange(thisMin:thisMax),normXrange(thisMin:thisMax));
            ind = sub2ind(size(thisHM),normYrange,normXrange);
            % Calculate normal to plane and project outline onto plane
            Nmat = cat(3,Nx(ind),Ny(ind),Nz(ind));
            N = squeeze(mean(Nmat,[1 2]))';
            N = N*(1/norm(N));
            proj = [xp,yp,zp] - (([xp,yp,zp] - [x_cent,y_cent,z_cent])*(N')) * N;
            RZ = [N(1)/sqrt((N(1)^2)+(N(2)^2)) N(2)/sqrt((N(1)^2)+(N(2)^2))  0 ; -N(2)/sqrt((N(1)^2)+(N(2)^2)) N(1)/sqrt((N(1)^2)+(N(2)^2)) 0; 0 0 1];
            
            Nprime = RZ*N';
            
            RY = [Nprime(3) 0 -Nprime(1); 0 1 0 ; Nprime(1) 0 Nprime(3)];
            
            
            if or(round(N,4) == [0,0,1],round(N,4) == [0,0,-1])
                translatedProj = proj-[x_cent,y_cent,z_cent];
                rotatedProj = translatedProj;
                s = null(N);
                proj2d =double(proj*s);
                
                newOutline = [(rotatedProj(:,1)),(rotatedProj(:,2))];
                smoothOutline = [smooth(newOutline(:,1)),smooth(newOutline(:,2))];
                vertInds = find(verts);
                for l = 1:length(vertInds)
                    smoothOutline(vertInds(l)) = newOutline(vertInds(l)); %Restore vertices to original coordinates after smoothing
                end
                
                newxp = smoothOutline(:,1);
                newyp = smoothOutline(:,2);
                box = minBoundingBox(double([newxp,newyp]'));
                L1 = sqrt((box(:,1)-box(:,2))'*(box(:,1)-box(:,2)));
                L2 = sqrt((box(:,1)-box(:,4))'*(box(:,1)-box(:,4)));
                if L2>L1
                    Aspect_Ratio = L2/L1;
                    Long = box(:,1)-box(:,4);
                else
                    Aspect_Ratio = L1/L2;
                    Long = box(:,1)-box(:,2);
                end
                Long = Long / sqrt(Long'*Long);
                
                Orient_Vec = [Long;0]';
                newxy = [newxp,newyp];
                steps = [newxy(2:end,:);newxy(1,:)]-newxy;
                Perimeter = sum(sqrt(sum(steps.^2,2)));
                
                Area = polyarea(newxp,newyp);
                
                % Rotate smoothed outline back to original x,y,z location:
                backProj = [newxp,newyp,zeros(length(newxp),1)]+[x_cent,y_cent,z_cent];
            else
                % Calculate rotation matrices to rotate cell to xy plane for
                % smoothing of outline
                
                translatedProj = proj-[x_cent,y_cent,z_cent];
                rotatedProj = (RY*(RZ*translatedProj'))';
                s = null(N);
                proj2d =double(proj*s);
                
                newOutline = [(rotatedProj(:,1)),(rotatedProj(:,2))];
                smoothOutline = [smooth(newOutline(:,1)),smooth(newOutline(:,2))];
                vertInds = find(verts);
                for l = 1:length(vertInds)
                    smoothOutline(vertInds(l),:) = newOutline(vertInds(l),:); %Restore vertices to original coordinates after smoothing
                end
                
                newxp = smoothOutline(:,1);
                newyp = smoothOutline(:,2);
                box = minBoundingBox(double([newxp,newyp]'));
                L1 = sqrt((box(:,1)-box(:,2))'*(box(:,1)-box(:,2)));
                L2 = sqrt((box(:,1)-box(:,4))'*(box(:,1)-box(:,4)));
                if L2>L1
                    Aspect_Ratio = L2/L1;
                    Long = box(:,1)-box(:,4);
                else
                    Aspect_Ratio = L1/L2;
                    Long = box(:,1)-box(:,2);
                end
                Long = Long / sqrt(Long'*Long);
                backLong = (RZ'*(RY'*[Long(1);Long(2);0]))';
                Orient_Vec = backLong;
                
                newxy = [newxp,newyp];
                steps = [newxy(2:end,:);newxy(1,:)]-newxy;
                Perimeter = sum(sqrt(sum(steps.^2,2)));
                
                Area = polyarea(newxp,newyp);
                
                % Rotate smoothed outline back to original x,y,z location:
                
                backRotated = (RZ'*(RY'*[newxp,newyp,zeros(length(newxp),1)]'))';
                backProj = backRotated+[x_cent,y_cent,z_cent];
                
            end
            % Save new smoothed outline coordinates and cell properties
            thisCellData(thisCell).outline_3d = backProj;
            thisCellData(thisCell).orientation = Orient_Vec;
            thisCellData(thisCell).area = Area;
            thisCellData(thisCell).aspect_ratio = Aspect_Ratio;
            thisCellData(thisCell).perimeter = Perimeter;
            thisCellData(thisCell).normal = N;
            thisCellData(thisCell).centre_z = z_cent*(1/Z_to_XY);
            thisCellData(thisCell).bb_xStart = min(xp);
            thisCellData(thisCell).bb_xEnd = max(xp);
            thisCellData(thisCell).bb_yStart = min(yp);
            thisCellData(thisCell).bb_yEnd = max(yp);
            
            % Save new smoothed bonds to bond database:
            
            thisBondData = saveCellBonds(thisCellData,thisBondData,thisDBondData,thisCell,backProj,verts);
            
            % Fill z-coordinate for vertices
            if ~isempty(vertInds)
                for vv=1:length(vertInds)
                    vXsearch = ([thisVertexData.x_pos] == xp(vertInds(vv)));%&&[thisVertexData.y_pos] == yp(vertInds(vv)));
                    vYsearch = ([thisVertexData.y_pos] == yp(vertInds(vv)));%&&[thisVertexData.y_pos] == yp(vertInds(vv)));
                    vInd = logical(vXsearch.*vYsearch);
                    thisVertexData(vInd).z_pos = zp(vertInds(vv))*(1/Z_to_XY);
                end
            end
            
            % Save 2d outline to struct for ease of future plotting
            allOutlines(thisCell).x_coord = xp';
            allOutlines(thisCell).y_coord = yp';
            
            len = length(allOutlines(thisCell).x_coord);
            thisID = thisCellData(thisCell).cell_id;
            allOutlines(thisCell).cell_id = [double(thisID).*ones(1,len)];
            
        end
        cd(rawDatasetsDir);
        save([thisFileName,'_CellData'],'thisCellData');
        save([thisFileName,'_BondData'],'thisBondData');
        save([thisFileName,'_VertexData'],'thisVertexData');
        
        x_coord = [allOutlines.x_coord]';
        y_coord = [allOutlines.y_coord]';
        cell_id = [allOutlines.cell_id]';
        
        frame_cell_outlines = table(x_coord,y_coord,cell_id);
        cd(outlineDir); writetable(frame_cell_outlines,[thisFileName,'_cell_outlines.csv']);
        catch
              display(['Skipping frame ',num2str(n)])
              cd(rawDatasetsDir)
              upDir = cd('..\');
              failedDatasetsDir = [upDir,'\failedDatasets\'];
              mkdir(failedDatasetsDir);
              movefile ([rawDatasetsDir,'\',thisFileName,'_CellData.mat'],[failedDatasetsDir,thisFileName,'_CellData.mat']);
              movefile ([rawDatasetsDir,'\',thisFileName,'_BondData.mat'],[failedDatasetsDir,thisFileName,'_BondData.mat']);
              movefile ([rawDatasetsDir,'\',thisFileName,'_VertexData.mat'],[failedDatasetsDir,thisFileName,'_VertexData.mat']);
              movefile ([rawDatasetsDir,'\',thisFileName,'_DBondData.mat'],[failedDatasetsDir,thisFileName,'_DBondData.mat']);

        end
        
    end
end
end


function [fullCellData] = cells3DCorrection(mainDir,fullCellData,calibrationXY, calibrationZ,umCurvWindow,cellHMnum)
% This function takes the data on cell outlines from "fullCellData",
% applies a geometric correction to the outlines according to the height
% maps to find area, orientation, and aspect ratio, and returns them to the main function to be saved back into
% fullCellData.

%% Define directories:
%cellAnalysisDir ='C:\Users\Lital\AppData\Roaming\TissueMiner\2020_09_01_18hr_set1_T';
HMDir = [mainDir,'\Layer_Separation\Output\Smooth_Height_Maps_',num2str(cellHMnum)]; % NOTICE IF NEEDS TO BE "Height_Maps_1" or "Height_Maps_0"
%% Load Data Height Maps
% cd(cellAnalysisDir);
% cellshapes = readtable('cellshapes.csv');
% cellsDB = readtable('cellsDB.csv');
cd(HMDir);
HMfiles = dir ('*.mat*');
sortedHMfiles = natsortfiles({HMfiles.name});

% Calibration
Z_to_XY = calibrationZ/calibrationXY; % Z to XY calibration
XY_to_Micron = calibrationXY; % XY calibration in um/pixel.
curvWindow = round(umCurvWindow*XY_to_Micron); % Window for averaging curvature around single cell in pixels (equivalent to 32 pixels in 512x512 image at 1.28 um/pixel)

%% Define Parameters and Outputs

firstHM = importdata (sortedHMfiles{1});
pix_max = size(firstHM);

[y_planeO,x_planeO] = meshgrid(1:pix_max(1),1:pix_max(2)); % Making a grid
x_plane = x_planeO(:);
y_plane = y_planeO(:);

% All data is saved here
Frame_3D_Data = struct;
Cell_3D_Data = struct;

%% Load all heightmaps into multi-dimensional array
allHM = read3DstackMat (HMDir);
allHM = allHM * Z_to_XY; % Scaling
%% Take cell outlines from fullCellData, for each one apply geometric correction, and calculate area, perimeter, aspect ration, and orientation.
for i = 1:size(fullCellData,2)
    i
    thisFrame = str2double(fullCellData(i).frame)+1;
    thisHM = allHM(:,:,thisFrame);
    [Nx,Ny,Nz] = surfnorm(reshape(x_plane,pix_max),reshape(y_plane,pix_max),thisHM);
    if isempty(fullCellData(i).outline)
        continue
    end
    xp = fullCellData(i).outline(:,1);
    yp = fullCellData(i).outline(:,2);
    
    % Find z-values of edges
    zp = zeros(length(xp),1);
    for k = 1:length(xp)
        zp(k) = thisHM(xp(k),yp(k));
    end
    
    x_cent = round(mean(xp));
    y_cent = round(mean(yp));
    z_cent = thisHM(x_cent,y_cent);
    normXrange = (x_cent-round(curvWindow/2)):(x_cent+round(curvWindow/2));
    % Make sure all points are within the frame boundaries
    minXpoint = max(find(normXrange>0,1),1);
    maxXpoint = find(normXrange>size(thisHM,2),1); if isempty(maxXpoint), maxXpoint = length(normXrange);end
    normYrange = (y_cent-round(curvWindow/2)):(y_cent+round(curvWindow/2));
    minYpoint = max(find(normYrange>0,1),1);
    maxYpoint = find(normYrange>size(thisHM,1),1);if isempty(maxYpoint), maxYpoint = length(normYrange);end
    thisMin = max(minXpoint,minYpoint);
    thisMax = min(maxXpoint-1,maxYpoint-1);
    
    ind = sub2ind(size(thisHM),normXrange(thisMin:thisMax),normYrange(thisMin:thisMax));
    
    Nmat = [Nx(ind'),Ny(ind'),Nz(ind')];
    N = mean(Nmat);
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
        
        % Smooth outline using gaussian blurring with sigma = 1 pixel, and
        % finding isocontour
        [x_fullRange,y_fullRange] = meshgrid(-pix_max(1):pix_max(1),-pix_max(2):pix_max(2)); % Making a grid
        in = inpolygon(x_fullRange,y_fullRange, rotatedProj(:,1),rotatedProj(:,2));
        inInd = find(in==1);
        cellRegion =zeros(2*pix_max+1);
        cellRegion(inInd)=1;
        sigma=[1,1];
        smoothCellRegion = imgaussfilt(cellRegion,sigma);
        [Lines,Vertices,Objects]=isocontour(smoothCellRegion,0.5);
        orderedVertices = Vertices(Objects{1},:);
        newxp = orderedVertices(:,2)-pix_max(2)-1;
        newyp = orderedVertices(:,1)-pix_max(1)-1;
        
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
        
        % Smooth outline using gaussian blurring with sigma = 1 pixel, and
        % finding isocontour
        [x_fullRange,y_fullRange] = meshgrid(-pix_max(1):pix_max(1),-pix_max(2):pix_max(2)); % Making a grid
        in = inpolygon(x_fullRange,y_fullRange, rotatedProj(:,1),rotatedProj(:,2));
        inInd = find(in==1);
        cellRegion =zeros(2*pix_max+1);
        cellRegion(inInd)=1;
        sigma=[1,1];
        smoothCellRegion = imgaussfilt(cellRegion,sigma);
        [Lines,Vertices,Objects]=isocontour(smoothCellRegion,0.5);
        allObjects = cat(1,Objects{:});
        % BorderedVertices = Vertices(Objects{1},:);
        orderedVertices = Vertices(allObjects,:);

        newxp = orderedVertices(:,2)-pix_max(2)-1;
        newyp = orderedVertices(:,1)-pix_max(1)-1;
        
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
    
    fullCellData(i).outline_3d = backProj;
    fullCellData(i).orientation = Orient_Vec;
    fullCellData(i).area = Area;
    fullCellData(i).aspect_ratio = Aspect_Ratio;
    fullCellData(i).perimeter = Perimeter;
end


function [thickness] = calculateCellThickness(mainDir,calibrationXY,calibrationZ,umCurvWindow,thisFrame,outline,cellHMnum)
% This function takes each each cell and calculates the average cell
% thickness by taking the distance between the cell and fibre layer along
% the direction given by the average normal perpendicular to the cell
% layer (averaged over window of size umCurvWindow).

%% Define directories:
HMDirC = [mainDir,'\Layer_Separation\Output\Smooth_Height_Maps_',num2str(cellHMnum)]; % Directories for both height maps.
HMDirF = [mainDir,'\Layer_Separation\Output\Smooth_Height_Maps_',num2str(cellHMnum==0)]; %
%% Load Data from Height Maps
cd(HMDirC);
HMfiles = dir ('*.mat*');
sortedHMfiles = natsortfiles({HMfiles.name});
% Calibration
Z_to_XY = calibrationZ/calibrationXY; % Z to XY calibration
XY_to_Micron = calibrationXY; % XY calibration in um/pixel.
curvWindow = round(umCurvWindow*XY_to_Micron); % Window for averaging curvature around single cell in pixels (equivalent to 32 pixels in 512x512 image at 1.28 um/pixel)

%% Define Parameters and Outputs
% Load relevant heightMaps
cd(HMDirC);
cHM = importdata (sortedHMfiles{thisFrame});
cHM = cHM * Z_to_XY; % Scaling
cd(HMDirF);
fHM = importdata (sortedHMfiles{thisFrame});
fHM = fHM * Z_to_XY; % Scaling

% Prepare grids for normal calculations
pix_max = size(cHM);
[x_planeO,y_planeO] = meshgrid(1:pix_max(1),1:pix_max(2)); % Making a grid
x_plane = x_planeO(:);
y_plane = y_planeO(:);

%% 

[Nx,Ny,Nz] = surfnorm(reshape(x_plane,pix_max),reshape(y_plane,pix_max),cHM);

xp = outline(:,1);
yp = outline(:,2);

% Find z-values of edges
zp = zeros(length(xp),1);
for k = 1:length(xp)
    zp(k) = cHM(yp(k),xp(k));
end

x_cent = round(mean(xp));
y_cent = round(mean(yp));
z_cent = cHM(y_cent,x_cent);
normXrange = (x_cent-round(curvWindow/2)):(x_cent+round(curvWindow/2));
% Make sure all points are within the frame boundaries
minXpoint = max(find(normXrange>0,1),1);
maxXpoint = find(normXrange>size(cHM,2),1); if isempty(maxXpoint), maxXpoint = length(normXrange);end
normYrange = (y_cent-round(curvWindow/2)):(y_cent+round(curvWindow/2));
minYpoint = max(find(normYrange>0,1),1);
maxYpoint = find(normYrange>size(cHM,1),1);if isempty(maxYpoint), maxYpoint = length(normYrange);end
thisMin = max(minXpoint,minYpoint);
thisMax = min(maxXpoint-1,maxYpoint-1);

ind = sub2ind(size(cHM),normYrange(thisMin:thisMax),normXrange(thisMin:thisMax));
normZvals = cHM(ind);% MAKE SURE THIS IS CORRECT! (AND NOT x,y FLIPPED)

Nmat = [Nx(ind'),Ny(ind'),Nz(ind')];
N = mean(Nmat);
N = N*(1/norm(N));

faces = delaunay(x_planeO,y_planeO);        % triangulate it using Delaunay algorithm
z0     = double(fHM);      
vertices = [x_planeO(:) y_planeO(:) z0(:)];  % vertices stored as Nx3 matrix
orig = [xp yp zp];
dir3d = N.*ones(size(orig));
% direction = reshape(dir3d,[pix_max(1)*pix_max(2),3]);
[ all_t, all_xcoor] = calculate_distance(vertices,orig,dir3d,faces);

thickness = mean(all_t);

end
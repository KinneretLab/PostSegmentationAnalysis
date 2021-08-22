function     [meanOrient, meanOP, meanCoh] = extractFibreData(thisCellDataMod,Orientation,LocalOP, Coherence, orientWindow, OPWindow, cohWindow); 

% This function takes the location of each segmented cell in the dataset,
% and finds average fibre orientation, coherence and order parameter
% in the region surrounding the cell. The size of the window for averaging
% is specified by OPWindow and CohWindow.  For orientation, the size of the
% window is currently the full cell area, but can be changed to be
% orientWindwow.
    
    thisCentre_x = round(thisCellDataMod.centre_x);
    thisCentre_y = round(thisCellDataMod.centre_y);
    if or(thisCentre_x<=0,thisCentre_y<=0)
        meanOrient = [];
        meanOP = [];
        meanCoh = [];
        return
    end
    thisOrientation = Orientation.orientation;
    sizeXY = size(thisOrientation);
    [y_fullRange,x_fullRange] = meshgrid(1:sizeXY(1),1:sizeXY(2)); % Making a grid
    in = inpolygon(x_fullRange,y_fullRange, thisCellDataMod.outline(:,1),thisCellDataMod.outline(:,2));% Find pixels inside cell
    % If want averaging to be on constant window size:
%   in = ((x_fullRange-thisCentre_x).^2 + (y_fullRange-thisCentre_y).^2) <= orientWindwo.^2;
    orientations = thisOrientation(in);
    meanOrient = nanmean(orientations);
    
    thisOP = LocalOP.localOP;
    OPmask = ((x_fullRange-thisCentre_x).^2 + (y_fullRange-thisCentre_y).^2) <= OPWindow.^2;
    OPvals = thisOP(OPmask);
    meanOP = nanmean(OPvals);

    thisCoh = Coherence.coherence;
    Cohmask = ((x_fullRange-thisCentre_x).^2 + (y_fullRange-thisCentre_y).^2) <= cohWindow.^2;
    Cohvals = thisCoh(Cohmask);
    meanCoh = nanmean(Cohvals);

end


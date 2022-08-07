function [ID] = uniqueID(frame,numInFrame)
% The function is a pairing function that takes two integers (specifically in our case, frame number
% and an index in each frame) and produces a unique ID number based on
% these two integers to be used as the unique identifier in the cell
% analysis data tables. The algorithm used is Cantor pairing.

a = double(frame);
b = double(numInFrame);
ID = (1/2)*(a+b)*(a+b+1)+a;
ID = int32(ID);
end


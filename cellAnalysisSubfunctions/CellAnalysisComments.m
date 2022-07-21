% Comments on databases:
% 
% 1. Directed bond with no vertices and left_dbond_id = dbond_id is a cell
% that is detached from other cells, so has just one bond and no vertices.
% The vertices field for these bonds is NaN.
% 2. Directed bond with  no conjugate d_bond (bonds on the edge that belong
% to only one cel) have a NaN in the conjugate d_bond field.
% 3. Smoothed bond coordinates are given on the projected plane tangent to
% the surface at the site of the cell. Therefore, they may not meet at the
% original vertex positions. 
% 4. All coordinates are given in pixels, so the um/pixel calibration of
% the xy coordinates and the z coordinates is in general different. All
% lengths, areas, etc. are in xy pixels.

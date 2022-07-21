function [] = createDataTables(rawDatasetsDir,cellDir)
% This function runs over all saved raw dataset files (matlab structures) and creates the
% appropriate TM format tables from all the individual per frame
% structures. NOT SURE YET IF WE WANT TO SAVE FINAL TABLES PER FRAME OR PER
% MOVIE.

cd(rawDatasetsDir);
datasets = dir('*Cell*');
sortedDatasets = natsortfiles({datasets.name});

for i = 1:length(sortedDatasets)
    i
    name_end = find(sortedDatasets{i} == '_');
    thisFileName = [sortedDatasets{i}(1:(name_end(end)-1))];
    display(['Reading data for ',thisFileName])
    cd(rawDatasetsDir);
    thisCellData = importdata([thisFileName,'_CellData.mat']);
    thisVertexData = importdata([thisFileName,'_VertexData.mat']);
    thisBondData = importdata([thisFileName,'_BondData.mat']);
    thisDBondData = importdata([thisFileName,'_DBondData.mat']);

% Save only data required for TM format to tables:

    %Directed bonds table
    dbond_id = {thisDBondData.dbond_id}';
    frame = {thisDBondData.frame}';   
    cell_id = {thisDBondData.cell}'; 
    conj_dbond_id = {thisDBondData.conjugate_dBond}';
    bond_id = {thisDBondData.bond}';
    allVertexPairs = cat(1,thisDBondData.ordered_vertices);
    if length(allVertexPairs)<length(dbond_id)
        allVertexPairs((length(allVertexPairs)+1):length(dbond_id),:)=NaN;
    end
    vertex_id = allVertexPairs(:,1); 
    vertex2_id = allVertexPairs(:,2);
    left_dbond_id = {thisDBondData.next_dBond}';
    frame_directed_bonds = table(dbond_id,frame,cell_id,conj_dbond_id,bond_id,vertex_id,vertex2_id,left_dbond_id);
    clear('dbond_id','frame','cell_id','conj_dbond_id','bond_id','vertex_id','vertex2_id','left_dbond_id');
    
    
    % Bonds table
    bond_id = {thisBondData.bond_id}';
    frame = {thisBondData.frame}';   
    bond_length = {thisBondData.length}';    
    
    frame_bonds = table(bond_id,frame,bond_length);
    clear('bond_id','frame','bond_length');
    
    % Vertices table
    vertex_id = {thisVertexData.vertex_id}';
    frame = {thisVertexData.frame}';   
    x_pos = {thisVertexData.x_pos}';    
    y_pos = {thisVertexData.y_pos}';    

    frame_vertices = table(vertex_id,frame, x_pos, y_pos);
    clear('vertex_id','frame', 'x_pos', 'y_pos');
    
    % Cells table
    cell_id = {thisCellData.cell_id}';
    frame = {thisCellData.frame}';   
    center_x = {thisCellData.centre_x}';    
    center_y = {thisCellData.centre_y}';   
    center_z = {thisCellData.centre_z}';    
    area =  {thisCellData.area}';
    aspect_ratio = {thisCellData.aspect_ratio}';
    perimeter = {thisCellData.perimeter}';
    is_edge = {thisCellData.isEdge}';
    is_convex = {thisCellData.isConvex}';
    allCellOrientation = cat(1,thisCellData.orientation);
    elong_xx = allCellOrientation(:,1);
    elong_yy = allCellOrientation(:,2);
    elong_zz = allCellOrientation(:,3);
    allCellNorms = cat(1,thisCellData.normal);
    norm_x = allCellNorms(:,1);
    norm_y = allCellNorms(:,2);
    norm_z = allCellNorms(:,3);
    fibre_orientation = {thisCellData.fibreOrientation}';
    fibre_localOP = {thisCellData.localOP}';
    fibre_coherence = {thisCellData.fibreCoherence}';
 %   score = {thisCellData.score}';
% 
%     frame_cells = table(cell_id,frame, center_x, center_y, area, aspect_ratio, perimeter, is_edge, is_convex, elong_xx, elong_yy, elong_zz ,fibre_orientation,fibre_localOP,fibre_coherence, score);
%     clear('cell_id','frame', 'center_x', 'center_y', 'area','aspect_ratio', 'perimeter', 'is_edge', 'is_convex', 'elong_xx', 'elong_yy', 'elong_zz', 'fibre_orientation','fibre_localOP','fibre_coherence','score');
    
    frame_cells = table(cell_id,frame, center_x, center_y, center_z, area, aspect_ratio, perimeter, is_edge, is_convex, elong_xx, elong_yy, elong_zz ,norm_x, norm_y, norm_z, fibre_orientation,fibre_localOP,fibre_coherence);
    clear('cell_id','frame', 'center_x', 'center_y', 'center_z','area','aspect_ratio', 'perimeter', 'is_edge', 'is_convex', 'elong_xx', 'elong_yy', 'elong_zz', 'norm_x', 'norm_y', 'norm_z','fibre_orientation','fibre_localOP','fibre_coherence');
   
    % Bond pixel table
    
    [allBondPixels,allBond3DPixels,allBondIDs,allBondFrames] = getBondPixelLists(thisBondData);
    orig_x_coord = allBondPixels(:,1);
    orig_y_coord =  allBondPixels(:,2);
    smooth_x_coord = allBond3DPixels(:,1);
    smooth_y_coord =  allBond3DPixels(:,2);
    smooth_z_coord =  allBond3DPixels(:,3);
    pixel_bondID = allBondIDs;
    pixel_frame = allBondFrames;
    
   frame_bond_pixels = table(orig_x_coord,orig_y_coord,smooth_x_coord,smooth_y_coord,smooth_z_coord,pixel_bondID,pixel_frame);
   clear('orig_x_coord','orig_y_coord','smooth_x_coord','smooth_y_coord','smooth_z_coord','pixel_bondID','pixel_frame');
    
    % CHECK DEFECT TABLE FORMAT AND SEE IF SUITABLE
    
    if i == 1
    bonds = frame_bonds;
    bond_pixels = frame_bond_pixels;
    cells = frame_cells;
    vertices = frame_vertices;
    directed_bonds = frame_directed_bonds;
    
    else
        
        bonds = [ bonds; frame_bonds];
        bond_pixels = [ bond_pixels; frame_bond_pixels];
        cells = [ cells; frame_cells];
        vertices = [ vertices; frame_vertices];
        directed_bonds = [ directed_bonds; frame_directed_bonds];

    end
end

    
     % Save all tables to folder:
    
     cd(cellDir); writetable(cells,'cells.csv'); writetable(vertices,'vertices.csv'); writetable(bonds,'bonds.csv');writetable(directed_bonds,'directed_bonds.csv'); writetable(bond_pixels,'bond_pixels.csv');

end


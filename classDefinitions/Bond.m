classdef Bond
    properties
        frame
        bond_id
        bond_length

    end
    
    methods
        
%         function obj = Bond(dataDir,ID)
%             
%             cd(dataDir);
%             bonds = readtable('bonds.csv');
%             bond_ind = (bonds{:,'bond_id'} == ID);
%             obj.frame = bonds{bond_ind,'frame'};
%             obj.bond_id = ID;
%             obj.bond_length = bonds{bond_ind,'bond_length'};
%             
%         end
        
        function obj = Bond(bond_table_row)
            if nargin > 0
                for name = bond_table_row.Properties.VariableNames
                    obj.(name{1}) = bond_table_row{1, name}; %% be careful with variable refactoring
                end
            end
        end
        
        
        
        function dBonds = getDBonds(obj,dataDir)
            
            cd(dataDir);
            directed_bonds = readtable('directed_bonds.csv');
            thisID = obj.bon   d_id;
            dBondInds = (directed_bonds{:,'bond_id'} == thisID);
            dBonds = table2array(directed_bonds(dBondInds,'dbond_id'));
        end
        
        function these_cells = getCells(obj,dataDir)
            
            these_cells = [];
            dBonds = getDBonds(obj,dataDir);  
            cd(dataDir);
            directed_bonds = readtable('directed_bonds.csv');
            for i=1:height(dBonds)
            dBondInds = (directed_bonds{:,'dbond_id'} == dBonds(i));
            cellID = directed_bonds{dBondInds,'cell_id'};
            these_cells = unique([these_cells;cellID]);
            end
            
        end
        
        function these_vertices = getVertices(obj,dataDir)
            dBonds = getDBonds(obj,dataDir);  
            cd(dataDir);
            directed_bonds = readtable('directed_bonds.csv');
            dBondInds = (directed_bonds{:,'dbond_id'} == dBonds(1));
            these_vertices = [directed_bonds{dBondInds,'vertex_id'};directed_bonds{dBondInds,'vertex2_id'}];
        end
        
        function coords = getXYCoords(obj,dataDir)
            cd(dataDir);
            bond_pixels = readtable('bond_pixels.csv');
            pixelInds = (bond_pixels{:,'pixel_bondID'} == obj.bond_id);
            coords = [bond_pixels{pixelInds,'orig_x_coord'},bond_pixels{pixelInds,'orig_y_coord'}];
        end
        
        function coords3D = get3Coords3D(obj,dataDir)
            cd(dataDir);
            bond_pixels = readtable('bond_pixels.csv');
            pixelInds = (bond_pixels{:,'pixel_bondID'} == obj.bond_id);
            coords3D = [bond_pixels{pixelInds,'smooth_x_coord'},bond_pixels{pixelInds,'smooth_y_coord'},bond_pixels{pixelInds,'smooth_z_coord'}];
        end
        
    end
    
end
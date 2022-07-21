classdef Cell
    properties
        cell_id
        frame
        center_x
        center_y
        center_z
        area
        aspect_ratio
        perimeter
        is_edge
        is_convex
        elong_xx
        elong_yy
        elong_zz
        norm_x
        norm_y
        norm_z
        fibre_orientation
        fibre_localOP
        fibre_coherence
        score
        DB
    end
    
    methods
        
        function obj = Cell(db,cell_table_row)
            if nargin > 0
                for name = cell_table_row.Properties.VariableNames
                    obj.(name{1}) = cell_table_row{1, name}; %% be careful with variable refactoring
                end
                obj.DB = db;
            end
        end
        
        function dBonds = dBonds(obj)
            thisID = [obj.cell_id];
            dbArray = [obj.DB];
            dbFolderArray = {dbArray.folder_};
            [~,ia,ic] = unique(dbFolderArray);
            
            for i=1:length(ia)
                dBondArray(i,:) = dbArray(ia(i)).dBonds;
            end
            maxLength = 0;
            flags = [];
            for i=1:length(thisID)
                if mod(a,100) ==0
                    sprintf(['Finding directed bonds for cell # ',num2str(i)]);
                end
                cellIDArray = [dBondArray(ic(i),:).cell_id];
                flags = (cellIDArray == thisID(i));
                thisLength = sum(flags);
                if thisLength > maxLength
                    dBonds(:,(maxLength+1):thisLength) = DBond();
                    maxLength = thisLength;
                end
                dBonds(i,1:thisLength) = dBondArray(flags);
            end
            
        end
        
        
%         
%         thisID = [cellArray.cell_id];
%
% dbArray = [cellArray(1).DB]; % create d_bonds just once for each DB, readtable needs to happen in creating DB and not just addresses.
% display('made dbArray')
% dBondArray = dbArray.dBonds;
% display('made dBondArray')
% 
% flags = [];
% for i=1:length(thisID)
%     i
%     cellIDArray = [dBondArray.cell_id];
%     flags(i,:) = (cellIDArray == thisID(i));
% end
% dBonds = dbArray.dBonds(flags);
        
%         
%         function these_bonds = getBonds(obj,dataDir)
%             
%             these_bonds = [];
%             dBonds = getDBonds(obj,dataDir);
%             cd(dataDir);
%             directed_bonds = readtable('directed_bonds.csv');
%             for i=1:height(dBonds)
%                 dBondInds = (directed_bonds{:,'dbond_id'} == dBonds(i));
%                 bondID = directed_bonds{dBondInds,'bond_id'};
%                 these_bonds = unique([these_bonds;bondID]);
%             end
%             
%         end
%         
%         function these_vertices = getVertices(obj,dataDir)
%             dBonds = getDBonds(obj,dataDir);  
%             cd(dataDir);
%             directed_bonds = readtable('directed_bonds.csv');
%             dBondInds = (directed_bonds{:,'dbond_id'} == dBonds(1));
%             these_vertices = [directed_bonds{dBondInds,'vertex_id'};directed_bonds{dBondInds,'vertex2_id'}];
%         end

        
    end
end
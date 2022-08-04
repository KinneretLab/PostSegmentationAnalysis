classdef BondPixelList
    properties
        orig_x_coord
        orig_y_coord
        smooth_x_coord
        smooth_y_coord
        smooth_z_coord
        pixel_bondID
        pixel_frame
        DB

    end
    
    methods
        
        function obj = BondPixelList(db,pixel_table_rows)
            if nargin > 0
                for name = pixel_table_rows(1,:).Properties.VariableNames
                    obj.(name{1}) = pixel_table_rows{1:end, name}; %% be careful with variable refactoring
                end
                obj.DB = db;
                obj.pixel_bondID = pixel_table_rows{1, 'pixel_bondID'};
                obj.pixel_frame = pixel_table_rows{1, 'pixel_frame'};

            end
        end
        
        function pixels = orig(obj, idx)
            % gets the full coordinates of a particular pixel
            % input - idx: the indices to fetch
            if all(size(obj) == [1, 1])
                if nargin == 1
                    idx = 1:size(idx);
                end
                pixels = zeros(size(idx), 2);
                pixels(:,1) = obj.orig_x_coord(idx);
                pixels(:,2) = obj.orig_y_coord(idx);
            else
                print('[ERROR] Method unavailable for arrays, please iterate');
            end
        end
        
        function pixels = smooth(obj, idx)
            % gets the full coordinates of a particular pixel, in the
            % recreated space
            % input - idx: the indices to fetch
            if all(size(obj) == [1, 1])
                if nargin == 1
                    idx = 1:size(idx);
                end
                pixels = zeros(size(idx), 3);
                pixels(:,1) = obj.smooth_x_coord(idx);
                pixels(:,2) = obj.smooth_y_coord(idx);
                pixels(:,3) = obj.smooth_z_coord(idx);
            else
                print('[ERROR] Method unavailable for arrays, please iterate');
            end
        end
    end
    
end
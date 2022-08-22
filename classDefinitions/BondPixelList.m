classdef BondPixelList < PhysicalEntity
    properties
        orig_x_coord
        orig_y_coord
        smooth_x_coord
        smooth_y_coord
        smooth_z_coord
        pixel_bondID
        pixel_frame
    end
    
    properties (Access = private)
        names_ % internal, ignore
    end
    
    methods
        
        function obj = BondPixelList(varargin)
            % Construct a BondPixelList. This has slightly different stuff,
            % since it is combining a bunch of rows together, instead of
            % each row being an entry
            % this does not improve speeds significantly from prev. model
            obj@PhysicalEntity({});
            if nargin > 1
                obj.experiment = varargin{1};
                table = varargin{2};
                obj.names_ = table(1,:).Properties.VariableNames;
                obj = splitapply(@obj.init, table, findgroups(table.pixel_bondID))';
            end
        end
        
        function new_obj = init(template_obj, varargin)
            new_obj = BondPixelList;
            new_obj.experiment = template_obj.experiment;
            for i = 1:length(template_obj.names_)
                new_obj.(template_obj.names_{i}) = varargin{:, i}; %% be careful with variable refactoring
            end
            % flatten
            new_obj.pixel_bondID = new_obj.pixel_bondID(1);
            new_obj.pixel_frame = new_obj.pixel_frame(1);
        end

        function id = uniqueID(~)
            id = "pixel_bondID";
        end
        
        function id = frameID(~)
            id = "pixel_frame";
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
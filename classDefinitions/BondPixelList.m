classdef BondPixelList < PhysicalEntity
    % BONDPIXELLIST A list of coordinates that fully describe a BOND 
    % This can be either in the respective physical picture it was derived
    % from, or after a geometric correction to the 3D space.
    % This object can lead to expensive operations, so use sparingly.
    properties
        % a list of uncorrected coordinates (in particular X)
        % type: int[]
        orig_x_coord
        % a list of uncorrected coordinates (in particular Y)
        % type: int[]
        orig_y_coord
        % a list of geometrically corrected coordinates (in particular X)
        % type: double[]
        smooth_x_coord
        % a list of geometrically corrected coordinates (in particular Y)
        % type: double[]
        smooth_y_coord
        % a list of geometrically corrected coordinates (in particular Z)
        % type: double[]
        smooth_z_coord
        % the bond these pixels describe.
        % type: int
        pixel_bondID
        % the frame these pixels reside in.
        % type: int
        pixel_frame
    end
    
    properties (Access = private)
        names_ % internal, ignore
    end
    
    methods
        
        function obj = BondPixelList(varargin)
            % BONDPIXELLIST Construct a BondPixelList.
            % This has slightly different stuff, since it is combining a bunch of rows together, 
            % instead of each row being an entry
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
            % a supplementary function for the constructor which
            % initializes one singular BONDPIXELLIST
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
        
        function logger = logger(~)
            logger = Logger('BondPixelList');
        end
        
        function coords = coords(obj, varargin)
            % COORDS the identity function
            % Parameters:
            %   varargin: additional MATLAB builtin operations to apply on
            %   the result.
            % Return type: BONDPIXELLIST[]
            coords = obj(varargin{:});
        end
        
        function obj = dbonds(obj, varargin)
            % DBONDS unsupported.
            obj.logger.error("method BondPixelList.dbonds is not supported. Did you mean to use .bonds?");
        end
        
        function bonds = bonds(obj, varargin)
            % BONDS calculates the bonds each pixel list in this array describes.
            % Parameters:
            %   varargin: additional MATLAB builtin operations to apply on
            %   the result.
            % Return type: BOND[]
            bonds = obj.lookup1(class(Bond), "pixel_bondID", "bond_id", varargin{:});
        end
        
        function pixels = orig(obj, varargin)
            % ORIG gets the full, uncorrected coordinates of the bond. 
            % You can also tell it to get a paricular coordinate using the
            % additional arguments.
            % note that this does not work on arrays of bond pixel lists,
            % only singular entities.
            % Parameters:
            %   varargin: additional MATLAB builtin operations to apply on
            %   the result.
            % Return type: double[]
            if all(size(obj) == [1, 1])
                pixels = zeros(length(obj.orig_x_coord), 2);
                pixels(:,1) = obj.orig_x_coord;
                pixels(:,2) = obj.orig_y_coord;
                pixels = pixels(varargin{:});
            else
                obj.logger.error('Method unavailable for arrays, please iterate');
            end
        end
        
        function pixels = smooth(obj, varargin)
            % ORIG gets the geometrically corrected coordinates of the bond. 
            % You can also tell it to get a paricular coordinate using the
            % additional arguments.
            % note that this does not work on arrays of bond pixel lists,
            % only singular entities.
            % Parameters:
            %   varargin: additional MATLAB builtin operations to apply on
            %   the result.
            % Return type: double[]
            if all(size(obj) == [1, 1])
                pixels = zeros(length(obj.smooth_x_coord), 2);
                pixels(:,1) = obj.smooth_x_coord;
                pixels(:,2) = obj.smooth_y_coord;
                pixels(:,3) = obj.smooth_y_coord;
                pixels = pixels(varargin{:});
            else
                obj.logger.error('Method unavailable for arrays, please iterate');
            end
        end
    end
    
end
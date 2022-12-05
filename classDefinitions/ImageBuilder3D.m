classdef ImageBuilder3D <ImageBuilder


   properties

    curv_smoothing_window = (32/1.28); % Window for averaging curvature around single cell (in um). Default - 32 pixels in 1.28 um/pixel.
    hm_subfolder_ = "";
    layer_arr_3d_ = {};

   end 
    methods

        function obj = ImageBuilder3D()
            % Construct an ImageBuilder3D using the ImageBuilder
            % constructor
            obj@ImageBuilder()
        end

      function obj = addData(obj, frame_arr)
         addData@ImageBuilder(obj, frame_arr)
           
      end 

      function obj = setHMSubfolder(obj,subfolder)
          obj.hm_subfolder_ = subfolder;
      end

        function [layer_arr_3d,obj]= calculate(obj)

            if isempty(obj.layer_arr_)
                calculate@ImageBuilder(obj);
            end

            [row, col ] = size(obj.layer_arr_);
            layer_arr_3d = {};

            calibration_xy =  obj.data_{1}(1).experiment.calibration_xy_; % Get calibration from experiment
            calibration_z = obj.data_{1}(1).experiment.calibration_z_; % Get calibration from experiment
            curv_window = obj.curv_smoothing_window;

            z_to_xy = calibration_z/calibration_xy; % Z to XY calibration
            xy_to_micron = calibration_xy; % XY calibration in um/pixel.
            curv_window = round(curv_window*xy_to_micron); % Window for averaging curvature around single cell in pixels (equivalent to 32 pixels in 512x512 image at 1.28 um/pixel)

            for j=1:col

                % Get frame name
                frame_name = obj.data_{1}(j).frame_name;

                % Read smooth height map for this frame, need to get it
                % from directory and frame name

                hm_dir =  obj.data_{1}(j).experiment.hm_folder_; % NEED TO IMPLEMENT THIS FOR EXPERIMENT
                cd(strcat(hm_dir,'\',obj.hm_subfolder_));
                thisHMfile = dir(['*',frame_name,'.*']);
                this_HM = importdata (thisHMfile.name);
                this_HM = this_HM * z_to_xy; % Scaling


                imSize = size(this_HM);

                [y_planeO,x_planeO] = meshgrid(1:imSize(1),1:imSize(2)); % Making a grid
                x_plane = x_planeO(:);
                y_plane = y_planeO(:);

                [Nx,Ny,Nz] = surfnorm(reshape(y_plane,imSize),reshape(x_plane,imSize),this_HM);

                for i = 1:row

                    is_marker = obj.layers_data_{i}.getIsMarkerLayer;
                    is_quiver = obj.layers_data_{i}.getIsMarkerQuiver;

                    if is_marker

                        % Get z coordinate from smoothed height map for xy
                        % pixels of marker list
                        this_arr = obj.layer_arr_{i,j};
                        this_x = round(this_arr(:,1));
                        this_y = round(this_arr(:,1));

                        ind = sub2ind(size(this_HM),this_y,this_x);
                        this_z = this_HM(ind);
                        this_arr = cat(this_x,this_y,this_z,this_arr(:,3),2);
                        layer_arr_3d{i,j} = this_arr;

                    end

                    if is_quiver
                        % Get z coordinate from smoothed height map for xy
                        % pixels of marker list.

                        this_arr = obj.layer_arr_{i,j};
                        this_x = round(this_arr(:,1));
                        this_y = round(this_arr(:,2));

                        ind = sub2ind(size(this_HM),this_y,this_x);
                        this_z = this_HM(ind);

                        xv = this_arr(:,4).*cos(this_arr(:,3));
                        yv = this_arr(:,4).*sin(this_arr(:,3));

                        this_vx = [];
                        this_vy = [];
                        this_vz = [];

                        % Get vector elements in 2D:

                        % Next, get plane normal to surface at the specified xy
                        % coordinates. Although we already have this
                        % calculated for cells, we need to repeat
                        % the calculation here for objects of other types,
                        % therefore for simplicity we can just re-calculate
                        % for cells as well (but can change this if we want
                        % to).
                        for k = 1:length(this_x)
                            norm_x_range = (this_x(k)-round(curv_window/2)):(this_x(k)+round(curv_window/2));
                            % Make sure all points are within the frame boundaries
                            min_x_point = max(find(norm_x_range>0,1),1);
                            max_x_point = find(norm_x_range>size(this_HM,2),1); if isempty(max_x_point), max_x_point = length(norm_x_range);end
                            norm_y_range = (this_y(k)-round(curv_window/2)):(this_y(k)+round(curv_window/2));
                            min_y_point = max(find(norm_y_range>0,1),1);
                            max_y_point = find(norm_y_range>size(this_HM,1),1);if isempty(max_y_point), max_y_point = length(norm_y_range);end
                            this_min = max(min_x_point,min_y_point);
                            this_max = min(max_x_point-1,max_y_point-1);

                            [norm_y_range,norm_x_range] = meshgrid(norm_y_range(this_min:this_max),norm_x_range(this_min:this_max));
                            ind = sub2ind(size(this_HM),norm_y_range,norm_x_range);
                            % Calculate averaged normal to plane:
                            Nmat = cat(3,Nx(ind),Ny(ind),Nz(ind));
                            N = squeeze(mean(Nmat,[1 2]))';
                            N = N*(1/norm(N));

                            % Now use the normal to project the 2D vector onto
                            % this plane.


                            % proj = [xp,yp,zp] - (([xp,yp,zp] - [this_x,this_y,this_z])*(N')) * N; % This is how to project a point defined by xp,yp,zp onto the plane, where this_x,this_y,this_z is any point on the plane and N is the normal to the plane.
                            proj = [xv(k),yv(k),0] - (([xv(k),yv(k),0])*(N'))* N; % This is how to project a point defined by xp,yp,0 onto the plane defined by N, with the plane going through the origin.

                            this_vx(k) = proj(:,1);
                            this_vy(k)  = proj(:,2);
                            this_vz(k)  = proj(:,3);
                        end
                        this_arr = cat(2,this_x,this_y,this_z, this_vx', this_vy', this_vz');
                        layer_arr_3d{i,j} = this_arr;

                    end

                end

            end

            
            obj.layer_arr_3d_ = layer_arr_3d;
        end

    end

end
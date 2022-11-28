classdef ImageDrawData < handle
    %IMAGEDRAWDATA Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (Access=private)
        image_builder_
        background_image_
        is_background_per_frame_
        color_for_nan_ %in rgb, if there is a background image this setting is disregarded
        %TODO: add protected way to add properties to this class, so they
        %will be validated
        show_colorbar_ %bool
        colorbar_title_
        colorbar_axis_scale_
        image_title_
        legend_for_markers_
        xy_calibration_         % double
        z_calibration_          % double
        image_size_             % double array
        crop_ %bool %TODO
        crop_size_ %TODO
        crop_center_point_ %TODO
    end
    
    methods
        function obj = ImageDrawData(image_builder)
            obj.color_for_nan_= [0 0 0];
            obj.background_image_=[];
            obj.is_background_per_frame_=false;
            obj.show_colorbar_= true;
            obj.colorbar_axis_scale_ = [];
            obj.image_title_="";
            obj.colorbar_title_="";
            obj.legend_for_markers_=false;
            obj.crop_=false;
            obj.image_builder_=image_builder;
            obj.crop_size_=64; %when crop is enabled: if center point is given will prodice an image of obj.crop_size_Xobj.crop_size_ around it, if not, wwill automatically crop around center point of image, will include all of it, and this will be length outside
        end
        
        function obj=setBackgroundImage(obj, value)
            [row, ~]=size(value);
            if(row==1)
                obj.setIsBackgroundPerFrame(true);
            end
            obj.background_image_ = value;
        end
        
        function value = getBackgroundImage(obj)
            value = obj.background_image_;
        end
        
        function obj=setColorForNaN(obj, value)
            obj.color_for_nan_ = value;
        end
        
        function value = getColorForNaN(obj)
            value = obj.color_for_nan_;
        end
        
        function obj=setShowColorbar(obj, value)
            obj.show_colorbar_ = value;
        end
        
        function value = getShowColorbar(obj)
            value = obj.show_colorbar_;
        end
        
        function obj=setColorbarTitle(obj, value)
            obj.colorbar_title_ = value;
        end
        
        function value = getColorbarTitle(obj)
            value = obj.colorbar_title_;
        end
        
        function obj=setColorbarAxisScale(obj, value)
            obj.colorbar_axis_scale_ = value;
        end
        
        function value = getColorbarAxisScale(obj)
            value = obj.colorbar_axis_scale_;
        end
        
        function obj=setImageTitle(obj, value)
            obj.image_title_ = value;
        end
        
        function value = getImageTitle(obj)
            value = obj.image_title_;
        end
        
        function obj=setLegendForMarkers(obj, value)
            obj.legend_for_markers_ = value;
        end
        
        function value = getLegendForMarkers(obj)
            value = obj.legend_for_markers_;
        end
        
        function obj=setCrop(obj, value)
            obj.crop_ = value;
        end
        
        function value = getCrop(obj)
            value = obj.crop_;
        end
        
        function obj=setCropSize(obj, value)
            obj.crop_size_ = value;
        end
        
        function value = getCropSize(obj)
            value = obj.crop_size_;
        end
        
        function obj=setCropCenterPoint(obj, value)
            obj.crop_center_point_ = value;
        end
        
        function value = getCropCenterPoint(obj)
            value = obj.crop_center_point_;
        end
        
        function obj=setIsBackgroundPerFrame(obj, value)
            obj.is_background_per_frame_ = value;
        end
        
        function value = getIsBackgroundPerFrame(obj)
            value = obj.is_background_per_frame_;
        end

        function obj = setXYCalibration(obj, calib)
            % XYCALIBRATION Micron to pixel calibration for the xy plane of
            % the image.
            % Parameters:
            %   calib: double
            %      the scaling value to multiply the values by. That is,
            %      final_value = calib * pixel_value;
            obj.xy_calibration_ = calib;
        end

        function value = getXYCalibration(obj)
            value = obj.xy_calibration_;
        end
        
        function obj = setZCalibration(obj, calib)
            % ZCALIBRATION Micron to pixel calibration for the z axis of
            % the image stack.
            % Parameters:
            %   calib: double
            %      the scaling value to multiply the values by. That is,
            %      final_value = calib * pixel_value;
            obj.z_calibration_ = calib;
        end

        function value = getZCalibration(obj)
            value = obj.z_calibration_;
        end

        function obj = setImageSize(obj,im_size)
            obj.image_size_ = im_size;
        end

        function value = getImageSize(obj)
            value = obj.image_size_;
        end

        function builder=close(obj)
            builder=obj.image_builder_;
        end
    end
end


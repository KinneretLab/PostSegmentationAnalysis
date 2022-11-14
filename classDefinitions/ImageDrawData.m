classdef ImageDrawData < handle
    %IMAGEDRAWDATA Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (Access=private)
        overlay_ %todo: ask! see how
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
        crop_ %bool %TODO
        crop_size_ %TODO
        crop_center_point_ %TODO
    end
    
    methods
        function obj = ImageDrawData()
            obj.color_for_nan_= [0 0 0];
            obj.background_image_=[];
            obj.is_background_per_frame_=false;
            obj.show_colorbar_= true;
            obj.colorbar_axis_scale_ = [];
            obj.image_title_="";
            obj.colorbar_title_="";
            obj.legend_for_markers_=false;
        end
        
        
        function obj=setOverlay(obj, value)
            obj.overlay_ = value;
        end
        
        function value = getOverlay(obj)
            value = obj.overlay_;
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
    end
end


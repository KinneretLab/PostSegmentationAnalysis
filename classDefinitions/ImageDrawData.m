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
        image_title_
        legend_for_markers_
        crop_ %bool
        crop_size_ 
        crop_center_point_
    end
    
    methods
        function obj = ImageDrawData(image_builder)
            obj.color_for_nan_= [0 0 0];
            obj.background_image_=[];
            obj.is_background_per_frame_=false;
            obj.show_colorbar_= true;
            obj.image_title_="";
            obj.colorbar_title_="";
            obj.legend_for_markers_=false;
            obj.crop_=false;
            obj.image_builder_=image_builder;
            obj.crop_size_=64; %when crop is enabled: if center point is given will prodice an image of obj.crop_size_Xobj.crop_size_ around it, if not, wwill automatically crop around center point of image, will include all of it, and this will be length outside
            obj.crop_center_point_=[0 0];
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

        function builder=close(obj)
            builder=obj.image_builder_;
        end
    end
end


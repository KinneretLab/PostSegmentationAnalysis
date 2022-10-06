classdef ImageDrawData < handle
    %IMAGEDRAWDATA Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (Access=private)
        overlay_ %todo: ask! see how
        background_image_
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
            obj.show_colorbar_= true;
            obj.colorbar_axis_scale_ = [0 1];
            obj.image_title_="";
            obj.colorbar_title_="";
            
        end
        
        
        function setOverlay(obj, value)
            obj.overlay_ = value;
        end
        
        function value = getOverlay(obj)
            value = obj.overlay_;
        end
        
        function setBackgroundImage(obj, value)
            obj.background_image_ = value;
        end
        
        function value = getBackgroundImage(obj)
            value = obj.background_image_;
        end
        
        function setColorForNaN(obj, value)
            obj.color_for_nan_ = value;
        end
        
        function value = getColorForNaN(obj)
            value = obj.color_for_nan_;
        end
        
        function setShowColorbar(obj, value)
            obj.show_colorbar_ = value;
        end
        
        function value = getShowColorbar(obj)
            value = obj.show_colorbar_;
        end
        
        function setColorbarTitle(obj, value)
            obj.colorbar_title_ = value;
        end
        
        function value = getColorbarTitle(obj)
            value = obj.colorbar_title_;
        end
        
        function setColorbarAxisScale(obj, value)
            obj.colorbar_axis_scale_ = value;
        end
        
        function value = getColorbarAxisScale(obj)
            value = obj.colorbar_axis_scale_;
        end
        
        function setImageTitle(obj, value)
            obj.image_title_ = value;
        end
        
        function value = getImageTitle(obj)
            value = obj.image_title_;
        end
        
        function setLegendForMarkers(obj, value)
            obj.legend_for_markers_ = value;
        end
        
        function value = getLegendForMarkers(obj)
            value = obj.legend_for_markers_;
        end
        function setCrop(obj, value)
            obj.crop_ = value;
        end
        
        function value = getCrop(obj)
            value = obj.crop_;
        end
        
        function setCropSize(obj, value)
            obj.crop_size_ = value;
        end
        
        function value = getCropSize(obj)
            value = obj.crop_size_;
        end
        
        function setCropCenterPoint(obj, value)
            obj.crop_center_point_ = value;
        end
        
        function value = getCropCenterPoint(obj)
            value = obj.crop_center_point_;
        end
    end
end


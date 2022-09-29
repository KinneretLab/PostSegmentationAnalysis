classdef ImageDrawData
    %IMAGEDRAWDATA Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (Access=protected)
        overlay_ %see how
        background_image_
        color_for_nan_ %TODO: if there is a background image this setting is disregarded
        show_colorbar_ %bool
        colorbar_title_
        colorbar_axis_scale_
        image_title_
        legend_for_markers_
        crop_ %bool
        crop_size_
        crop_center_point_
    end
    
    methods
        function obj = ImageDrawData()
            obj.color_for_nan_= "black";
        end
    end
end

